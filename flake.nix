{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nixpkgs-ruby,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfree = true;
          overlays = [ nixpkgs-ruby.overlays.default ];
        };

        rubyVersion = builtins.head (builtins.split "\n" (builtins.readFile ./.ruby-version));
        ruby = pkgs."ruby-${rubyVersion}";

        lint = pkgs.writeShellScriptBin "lint" ''
          changed_files=$(git diff --name-only --diff-filter=ACM --merge-base main)

          bundle exec rubocop --autocorrect-all --force-exclusion $changed_files Gemfile
        '';

        postgresql = pkgs.postgresql_18;
        psychBuildFlags = with pkgs; [
          "--with-libyaml-include=${libyaml.dev}/include"
          "--with-libyaml-lib=${libyaml.out}/lib"
        ];
        postgresqlBuildFlags = with pkgs; [
          "--with-pg-config=${lib.getDev postgresql.pg_config}/bin/pg_config"
        ];

        # Worktree detection hook (per-flake, reusable pattern)
        worktree = rec {
          isWorktree = ''
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
              if [ "$(git rev-parse --git-dir 2>/dev/null)" != "$(git rev-parse --git-common-dir 2>/dev/null)" ]; then
                echo "true"
              else
                echo "false"
              fi
            else
              echo "false"
            fi
          '';

          id = ''
            if [ "$(${isWorktree})" = "true" ]; then
              git rev-parse --show-toplevel | md5sum | cut -c1-8
            else
              echo "main"
            fi
          '';
        };

        pg-environment-variables = ''
          if [ "$(${worktree.isWorktree})" = "true" ]; then
            WT_ID=$(${worktree.id})
            export PGHOST="/tmp/pg-$WT_ID"
            export PGDATA="$HOME/.local/share/postgres/worktrees/$WT_ID"
            mkdir -p "$PGHOST" "$PGDATA"
          else
            export PGDATA=$PWD/.nix/postgres/data
            export PGHOST=$PWD/.nix/postgres
          fi
          export DB_USER=""
        '';
        postgresql-start = pkgs.writeShellScriptBin "pg-start" ''
          ${pg-environment-variables}

          if [ ! -d $PGDATA ]; then
            mkdir -p $PGDATA

            ${postgresql}/bin/initdb $PGDATA --auth=trust
          fi

          ${postgresql}/bin/postgres -k $PGHOST -c listen_addresses=''' -c unix_socket_directories=$PGHOST
        '';
        init = pkgs.writeShellScriptBin "init" ''cd terraform && terraform init -backend=false'';
        update-providers = pkgs.writeShellScriptBin "update-providers" ''cd terraform && terraform init -backend=false -reconfigure -upgrade'';

        worktree-info = pkgs.writeShellScriptBin "worktree-info" ''
          if [ "$(${worktree.isWorktree})" = "true" ]; then
            WT_ID=$(${worktree.id})
            echo "Worktree mode enabled"
            echo "  ID:          $WT_ID"
            echo "  PGHOST:      /tmp/pg-$WT_ID"
            echo "  PGDATA:      $HOME/.local/share/postgres/worktrees/$WT_ID"
          else
            echo "Normal checkout (not a worktree)"
          fi
        '';

        worktree-clean = pkgs.writeShellScriptBin "worktree-clean" ''
          set -euo pipefail
          if [ "$(${worktree.isWorktree})" != "true" ]; then
            echo "Not inside a worktree. Nothing to clean."
            exit 0
          fi

          WT_ID=$(${worktree.id})
          echo "Cleaning worktree $WT_ID..."

          # Drop dev-hub specific databases (isolation comes from PGHOST)
          if command -v dropdb >/dev/null 2>&1; then
            dropdb --if-exists "tariff_dev_hub_development" || true
            dropdb --if-exists "tariff_dev_hub_test" || true
          fi

          # Remove short socket dir and per-worktree Postgres data
          rm -rf "/tmp/pg-$WT_ID"
          rm -rf "$HOME/.local/share/postgres/worktrees/$WT_ID"

          # Remove per-worktree Bundler state
          rm -rf ".bundle"
          rm -rf "$HOME/.local/share/gem/worktrees/$WT_ID" 2>/dev/null || true
          rm -rf "$HOME/.cache/bundle/worktrees/$WT_ID" 2>/dev/null || true

          # Remove marker
          rm -f "$HOME/.local/share/postgres/worktrees/$WT_ID/.worktree-initialized" 2>/dev/null || true

          echo "Worktree $WT_ID cleaned (Postgres + bundle)."
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            # Worktree-aware Bundler/Ruby isolation
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              WT_ID=$(${worktree.id})
              export GEM_HOME="$HOME/.local/share/gem/worktrees/$WT_ID"
              export BUNDLE_PATH=".bundle"
              export BUNDLE_APP_CONFIG=".bundle"
              export BUNDLE_IGNORE_CONFIG=1
              mkdir -p "$GEM_HOME" ".bundle"
              echo "Worktree Bundler isolation enabled (ID: $WT_ID)"
            else
              export GEM_HOME=$PWD/.nix/ruby/$(${ruby}/bin/ruby -e "puts RUBY_VERSION")
              mkdir -p $GEM_HOME
            fi

            export BUNDLE_BUILD__PG="${builtins.concatStringsSep " " postgresqlBuildFlags}"
            export BUNDLE_BUILD__PSYCH="${builtins.concatStringsSep " " psychBuildFlags}"

            export GEM_PATH=$GEM_HOME
            export PATH=$GEM_HOME/bin:$PATH

            ${pg-environment-variables}

            ${worktree-info}/bin/worktree-info

            # Ensure pre-commit hooks are installed (so they actually run on commit)
            if command -v pre-commit >/dev/null 2>&1; then
              pre-commit install --install-hooks 2>/dev/null || true
            fi

            # === Automatic per-worktree database initialization ===
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              WT_ID=$(${worktree.id})
              MARKER="$PGDATA/.worktree-initialized"

              if [ ! -f "$MARKER" ]; then
                echo ""
                echo "==> First time in this worktree (ID: $WT_ID)"
                echo "    Installing gems + initializing databases..."
                echo ""

                rm -rf .bundle
                bundle install 2>&1 | tail -5 || true
                bundle exec rails db:create 2>&1 | tail -3 || true
                bundle exec rails db:structure:load 2>&1 | tail -5 || true

                echo ""
                echo "    Preparing test database..."
                RAILS_ENV=test bundle exec rails db:test:prepare 2>&1 | tail -5 || true

                touch "$MARKER"
                echo ""
                echo "==> Worktree databases ready."
                echo ""
              fi
            fi
          '';

          buildInputs = [
            init
            lint
            pkgs.pre-commit
            postgresql
            postgresql-start
            ruby
            update-providers
            worktree-info
            worktree-clean
          ];
        };
      }
    );
}
