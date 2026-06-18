{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
      nixpkgs-ruby,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ nixpkgs-ruby.overlays.default ];
        };

        rubyVersion = builtins.head (builtins.split "\n" (builtins.readFile ./.ruby-version));
        ruby = pkgs."ruby-${rubyVersion}";

        lint = pkgs.writeShellScriptBin "lint" ''
          mapfile -t changed_files < <(git diff --name-only --diff-filter=ACM --merge-base main)

          if [ ''${#changed_files[@]} -eq 0 ]; then
            echo "No changed files to lint."
            exit 0
          fi

          pre-commit run --files "''${changed_files[@]}"
        '';

        postgresql = pkgs.postgresql_18;
        pgConfig = postgresql.pg_config;
        psychBuildFlags = with pkgs; [
          "--with-libyaml-include=${libyaml.dev}/include"
          "--with-libyaml-lib=${libyaml.out}/lib"
        ];
        postgresqlBuildFlags = [
          "--with-pg-config=${pgConfig}/bin/pg_config"
        ];

        # Worktree detection hook (per-flake, reusable pattern)
        # Disable Git fsmonitor for hook-local probes. If these git commands start
        # fsmonitor--daemon inside direnv's shellHook, the daemon can inherit a
        # nix-direnv pipe and keep the first `direnv exec ...` blocked after setup.
        worktree = rec {
          isWorktree = ''
            if git -c core.fsmonitor=false rev-parse --is-inside-work-tree >/dev/null 2>&1; then
              if [ "$(git -c core.fsmonitor=false rev-parse --git-dir 2>/dev/null)" != "$(git -c core.fsmonitor=false rev-parse --git-common-dir 2>/dev/null)" ]; then
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
              git -c core.fsmonitor=false rev-parse --show-toplevel | md5sum | cut -c1-8
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

          if [ ! -f "$PGDATA/PG_VERSION" ]; then
            mkdir -p "$PGDATA"
            ${postgresql}/bin/initdb "$PGDATA" --auth=trust
          fi

          ${postgresql}/bin/postgres -k "$PGHOST" -c listen_addresses=''' -c unix_socket_directories="$PGHOST"
        '';
        init = pkgs.writeShellScriptBin "init" "cd terraform && terraform init -backend=false";
        update-providers = pkgs.writeShellScriptBin "update-providers" "cd terraform && terraform init -backend=false -reconfigure -upgrade";

        preCommitCheck = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          configPath = ".pre-commit-config-nix.yaml";
          default_stages = [ "pre-commit" ];
          hooks = {
            actionlint = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            check-added-large-files = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            check-case-conflicts = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            check-merge-conflicts = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            check-yaml = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            deadnix = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            detect-private-keys = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            end-of-file-fixer = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            markdownlint = {
              enable = true;
              excludes = [ "^terraform/" ];
              settings.configuration.MD013 = false;
              stages = [ "pre-commit" ];
            };
            nixfmt-rfc-style = {
              package = pre-commit-hooks.inputs.nixpkgs.legacyPackages.${system}.nixfmt;
              enable = true;
              stages = [ "pre-commit" ];
            };
            sort-file-contents = {
              enable = true;
              files = "^\\.env\\.(development|test)$";
              stages = [ "pre-commit" ];
            };
            statix = {
              enable = true;
              settings.ignore = [ ".worktrees" ];
              stages = [ "pre-commit" ];
            };
            terraform-format = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            terraform-validate = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            tflint = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            trim-trailing-whitespace = {
              enable = true;
              stages = [ "pre-commit" ];
            };
            trufflehog = {
              enable = true;
              stages = [ "pre-commit" ];
            };

            rubocop = {
              enable = true;
              name = "rubocop";
              description = "Run RuboCop through Bundler";
              entry = "bundle exec rubocop --autocorrect";
              files = "\\.(rb|rake)$|^(Gemfile|Rakefile|config\\.ru)$";
              stages = [ "pre-commit" ];
            };
          };
        };

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

          PGDATA="$HOME/.local/share/postgres/worktrees/$WT_ID"
          PGHOST="/tmp/pg-$WT_ID"
          PIDFILE="/tmp/pg-$WT_ID.pid"

          # Stop the daemonised Postgres for this worktree before removing its data.
          if [ -f "$PGDATA/postmaster.pid" ] || [ -f "$PIDFILE" ]; then
            echo "    Stopping Postgres..."
            ${postgresql}/bin/pg_ctl stop -D "$PGDATA" -s -m fast || true
          fi

          rm -f "$PIDFILE"

          # Remove short socket dir and per-worktree Postgres data
          rm -rf "$PGHOST"
          rm -rf "$PGDATA"

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
              WT_ROOT=$(git -c core.fsmonitor=false rev-parse --show-toplevel)
              WT_BUNDLE_PATH="$WT_ROOT/.bundle"
              export GEM_HOME="$HOME/.local/share/gem/worktrees/$WT_ID"
              export BUNDLE_PATH="$WT_BUNDLE_PATH"
              export BUNDLE_APP_CONFIG="$WT_BUNDLE_PATH"
              export BUNDLE_IGNORE_CONFIG=1
              mkdir -p "$GEM_HOME" "$WT_BUNDLE_PATH"
              echo "Worktree Bundler isolation enabled (ID: $WT_ID)"
            else
              export GEM_HOME=$PWD/.nix/ruby/$(${ruby}/bin/ruby -e "puts RUBY_VERSION")
              mkdir -p $GEM_HOME
            fi

            export BUNDLE_BUILD__PG="${builtins.concatStringsSep " " postgresqlBuildFlags}"
            export BUNDLE_BUILD__PSYCH="${builtins.concatStringsSep " " psychBuildFlags}"

            export GEM_PATH=$GEM_HOME
            export PATH=${ruby}/bin:$GEM_HOME/bin:$PATH

            ${pg-environment-variables}

            ${worktree-info}/bin/worktree-info

            # === Automatic per-worktree database initialization ===
            if [ "$(${worktree.isWorktree})" = "true" ]; then
              WT_ID=$(${worktree.id})
              MARKER="$PGDATA/.worktree-initialized"
              PIDFILE="/tmp/pg-$WT_ID.pid"

              if [ ! -f "$MARKER" ]; then
                echo ""
                echo "==> First time in this worktree ($WT_ID) - running full setup..."
                echo ""

                fail_worktree_setup() {
                  echo ""
                  echo "==> Worktree setup failed. Fix the error above, then re-enter the shell."
                  if [ -f "$PGDATA/postmaster.pid" ]; then
                    ${postgresql}/bin/pg_ctl stop -D "$PGDATA" -s -m fast || true
                  fi
                  exit 1
                }

                run_setup_step() {
                  label="$1"
                  shift
                  log_file="/tmp/worktree-$WT_ID-$(echo "$label" | tr '[:upper:] /:' '[:lower:]---').log"

                  echo "    $label..."
                  # Setup commands may spawn daemon helpers, such as git fsmonitor. Close
                  # inherited nix-direnv pipe fds so those helpers cannot block `direnv exec`.
                  if "$@" >"$log_file" 2>&1 \
                    3>&- 4>&- 5>&- \
                    6>&- 7>&- 8>&- 9>&-; then
                    echo "      ok (log: $log_file)"
                  else
                    status=$?
                    echo "      failed with exit $status (log: $log_file)"
                    echo "      last 80 log lines:"
                    tail -80 "$log_file" | sed 's/^/        /'
                    return "$status"
                  fi
                }

                # Start Postgres as a proper daemon on the short socket if not already running
                if ! ${postgresql}/bin/pg_isready -h "$PGHOST" -p "''${PGPORT:-5432}" >/dev/null 2>&1; then
                  echo "    Starting Postgres as daemon on short socket..."
                  if [ ! -f "$PGDATA/PG_VERSION" ]; then
                    mkdir -p "$PGDATA"
                    run_setup_step "Initialising Postgres data directory" ${postgresql}/bin/initdb "$PGDATA" --auth=trust || fail_worktree_setup
                  fi
                  rm -f "$PIDFILE"
                  # pg_ctl daemonises Postgres from inside direnv's shellHook. File descriptors
                  # 3+ are extra handles opened by the parent process; `>&-` closes them for this
                  # command. Without this, Postgres inherits a nix-direnv pipe and the first
                  # `direnv exec ...` stays blocked after setup instead of running its command.
                  if ! ${postgresql}/bin/pg_ctl start \
                    -D "$PGDATA" \
                    -l "/tmp/pg-$WT_ID.log" \
                    -o "-k $PGHOST -c listen_addresses= -c external_pid_file=$PIDFILE" \
                    -w \
                    -t 60 \
                    3>&- 4>&- 5>&- \
                    6>&- 7>&- 8>&- 9>&-; then
                    echo "      failed to start Postgres (log: /tmp/pg-$WT_ID.log)"
                    echo "      last 80 log lines:"
                    tail -80 "/tmp/pg-$WT_ID.log" | sed 's/^/        /' || true
                    fail_worktree_setup
                  fi
                  for i in {1..60}; do
                    if ${postgresql}/bin/pg_isready -h "$PGHOST" -p "''${PGPORT:-5432}" >/dev/null 2>&1; then
                      break
                    fi
                    sleep 1
                  done
                  if ! ${postgresql}/bin/pg_isready -h "$PGHOST" -p "''${PGPORT:-5432}" >/tmp/pg-$WT_ID-ready.log 2>&1; then
                    echo "      Postgres did not become ready on $PGHOST"
                    cat /tmp/pg-$WT_ID-ready.log | sed 's/^/        /' || true
                    fail_worktree_setup
                  fi
                fi

                rm -rf "$BUNDLE_PATH"
                mkdir -p "$BUNDLE_PATH"
                export BUNDLE_IGNORE_CONFIG=1
                run_setup_step "Installing gems" bundle install --jobs=4 --retry=3 || fail_worktree_setup
                run_setup_step "Preparing development database" bundle exec rails db:prepare || fail_worktree_setup
                run_setup_step "Preparing test database" env RAILS_ENV=test bundle exec rails db:prepare || fail_worktree_setup

                touch "$MARKER"
                echo ""
                echo "==> Worktree first-time setup complete."
                echo ""
              else
                export BUNDLE_IGNORE_CONFIG=1
              fi
            fi

            ${preCommitCheck.shellHook}
            export PATH=${pkgs.writeShellScriptBin "pre-commit" ''
              set -euo pipefail

              has_config=false
              for arg in "$@"; do
                case "$arg" in
                  -c|--config|--config=*)
                    has_config=true
                    ;;
                esac
              done

              if [ "$has_config" = true ]; then
                exec ${preCommitCheck.config.package}/bin/pre-commit "$@"
              fi

              if [ "''${1:-}" = "run" ]; then
                shift
                exec ${preCommitCheck.config.package}/bin/pre-commit run --config .pre-commit-config-nix.yaml "$@"
              fi

              exec ${preCommitCheck.config.package}/bin/pre-commit "$@"
            ''}/bin:$PATH
          '';

          buildInputs = preCommitCheck.enabledPackages ++ [
            init
            lint
            postgresql
            pgConfig
            postgresql-start
            pkgs.terraform-docs
            ruby
            update-providers
            worktree-info
            worktree-clean
          ];
        };
      }
    );
}
