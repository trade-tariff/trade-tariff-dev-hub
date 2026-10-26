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
      self,
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

        reviewEnvironment = ''
          if [ "''${REVIEW_SANDBOX:-}" != 1 ] || [ "$PWD" != /workspace ]; then exit 64; fi
          export TMPDIR=/workspace/.review/tmp PRE_COMMIT_HOME=/workspace/.review/pre-commit
          export GEM_HOME=/workspace/.review/gems
          export GEM_PATH="$GEM_HOME''${REVIEW_GEM_CACHE:+:$REVIEW_GEM_CACHE}"
          export PATH="$GEM_HOME/bin:$PATH" BUNDLE_BIN="$GEM_HOME/bin"
          export BUNDLE_IGNORE_CONFIG=1 BUNDLE_PATH__SYSTEM=true BUNDLE_FROZEN=true
          export RAILS_ENV=test ENVIRONMENT=test CI=true DISABLE_BOOTSNAP_COMPILE_CACHE=1
          export PGDATA=/workspace/.review/postgres PGHOST=/workspace/.review/pg PGUSER=postgres DB_USER=postgres PGPORT=5432
          LD_LIBRARY_PATH="$(${pgConfig}/bin/pg_config --libdir):${pkgs.libyaml.out}/lib:${pkgs.openssl.out}/lib"
          export LD_LIBRARY_PATH
          export TF_CLI_CONFIG_FILE=/workspace/.review/terraform.rc TF_IN_AUTOMATION=1 TF_INPUT=0 CHECKPOINT_DISABLE=1 AWS_EC2_METADATA_DISABLED=true
          unset BUNDLE_PATH BUNDLE_APP_CONFIG BUNDLE_WITHOUT TF_PLUGIN_CACHE_DIR DATABASE_URL
          mkdir -p "$TMPDIR" "$GEM_HOME" "$PGHOST"
        '';
        reviewTools =
          import
            (builtins.fetchTree {
              type = "github";
              owner = "NixOS";
              repo = "nixpkgs";
              rev = "4a29d733e8a7d5b824c3d8c958a946a9867b3eb2";
              narHash = "sha256-f+JACbTqzZ+G92DSnXOUGRhGANb8Blh7CoeYOeBF8/U=";
            })
            {
              inherit system;
              config.allowUnfree = true;
            };
        reviewLatestTools = import (builtins.fetchTree {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "55bfb4d7437bd4e09ab7cba58a43bd68eb310044";
          narHash = "sha256-jBYGPi4udQ9uo4KQp9m2J0546nJVQitG15gvZSaVVAs=";
        }) { inherit system; };
        reviewTerraformHooks = builtins.fetchTree {
          type = "github";
          owner = "antonbabenko";
          repo = "pre-commit-terraform";
          rev = "d61ded22bf9aa0f757303ebcbb0d6d71c4b54015";
          narHash = "sha256-IPONqvEUoGrsnQkD0RTLW28QKoKqv8wf/ooExmSTJmE=";
        };
        reviewRubyHooks = builtins.fetchTree {
          type = "github";
          owner = "mattlqx";
          repo = "pre-commit-ruby";
          rev = "1f893f2c0db4068fafa19b8ea7d7db1253ea0cc1";
          narHash = "sha256-7S84RvncmcXVIjgNhzFyN4HnKJk+tKxHYvfOLcuiw8c=";
        };
        reviewTrufflehogScan = pkgs.writeShellScript "trufflehog-pre-commit" ''
          set -euo pipefail
          exclude_file="$(mktemp)"
          trap 'rm -f "$exclude_file"' EXIT
          printf '%s\n' '(^|/)\.git(/|$)' '(^|/)\.terraform(/|$)' '(^|/)\.terragrunt-cache(/|$)' > "$exclude_file"
          while IFS= read -r ignored; do
            [ -n "$ignored" ] || continue
            escaped="$(printf '%s' "''${ignored%/}" | sed 's/[][(){}.^$*+?|\\]/\\&/g')"
            case "$ignored" in
              */) printf '(^|/)%s(/|$)\n' "$escaped" >> "$exclude_file" ;;
              *) printf '(^|/)%s$\n' "$escaped" >> "$exclude_file" ;;
            esac
          done < <(git ls-files --others --ignored --exclude-standard --directory)
          exec ${reviewLatestTools.trufflehog}/bin/trufflehog filesystem "$(pwd -P)" --exclude-paths="$exclude_file" --results=verified,unknown --fail
        '';
        reviewHook =
          id: entry: attrs:
          {
            inherit id entry;
            name = id;
            language = "system";
          }
          // attrs;
        reviewPreCommitConfig = pkgs.writeText "review-pre-commit.json" (
          builtins.toJSON {
            default_install_hook_types = [
              "pre-commit"
              "pre-push"
            ];
            default_stages = [ "pre-commit" ];
            repos = [
              {
                repo = "local";
                hooks = [
                  (reviewHook "terraform_fmt" "${reviewTerraformHooks}/hooks/terraform_fmt.sh" {
                    files = "\\.(tf|tofu|tfvars|(tftest|tofutest|tfmock|tfquery)\\.hcl)$";
                    exclude = "\\.terraform/.*$";
                  })
                  (reviewHook "terraform_validate" "${reviewTerraformHooks}/hooks/terraform_validate.sh" {
                    files = "\\.(tf|tofu|tfvars|terraform\\.lock\\.hcl)$";
                    exclude = "\\.terraform/.*$";
                    require_serial = true;
                  })
                  (reviewHook "terraform_tflint" "${reviewTerraformHooks}/hooks/terraform_tflint.sh" {
                    files = "\\.(tf|tofu|tfvars)$";
                    exclude = "\\.terraform/.*$";
                    require_serial = true;
                  })
                  (reviewHook "terraform_docs" "${reviewTerraformHooks}/hooks/terraform_docs.sh" {
                    files = "\\.(tf|tofu|terraform\\.lock\\.hcl)$";
                    exclude = "\\.terraform/.*$";
                    require_serial = true;
                    args = [
                      "--hook-config=--add-to-existing-file=true"
                      "--hook-config=--path-to-file=README.md"
                      "--hook-config=--create-file-if-not-exist=true"
                    ];
                  })
                  (reviewHook "trailing-whitespace"
                    "${reviewTools.python3Packages.pre-commit-hooks}/bin/trailing-whitespace-fixer"
                    {
                      types = [ "text" ];
                      stages = [
                        "pre-commit"
                        "pre-push"
                        "manual"
                      ];
                    }
                  )
                  (reviewHook "end-of-file-fixer"
                    "${reviewTools.python3Packages.pre-commit-hooks}/bin/end-of-file-fixer"
                    {
                      types = [ "text" ];
                      stages = [
                        "pre-commit"
                        "pre-push"
                        "manual"
                      ];
                      exclude = "^vendor/javascript/";
                    }
                  )
                  (reviewHook "check-yaml" "${reviewTools.python3Packages.pre-commit-hooks}/bin/check-yaml" {
                    types = [ "yaml" ];
                  })
                  (reviewHook "file-contents-sorter"
                    "${reviewTools.python3Packages.pre-commit-hooks}/bin/file-contents-sorter"
                    { files = ".env.development|.env.test"; }
                  )
                  (reviewHook "markdownlint-fix" "${reviewTools.markdownlint-cli}/bin/markdownlint --fix" {
                    types = [ "markdown" ];
                    args = [
                      "--disable"
                      "MD013"
                      "--ignore"
                      "terraform"
                    ];
                  })
                  (reviewHook "rubocop" "${reviewRubyHooks}/bin/rubocop-wrapper.sh" {
                    types = [ "ruby" ];
                    args = [ "--autocorrect" ];
                    pass_filenames = true;
                  })
                  (reviewHook "actionlint-docker" "${reviewTools.actionlint}/bin/actionlint" {
                    types = [ "yaml" ];
                    files = "^\\.github/workflows/";
                  })
                  (reviewHook "trufflehog" "${reviewTrufflehogScan}" {
                    stages = [
                      "pre-commit"
                      "pre-push"
                    ];
                  })
                ];
              }
            ];
          }
        );

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
              excludes = [ "^vendor/javascript/" ];
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
              settings.ignore = [ "{.direnv,.nix,.worktrees}/**" ];
              stages = [ "pre-commit" ];
            };
            terraform-format = {
              enable = true;
              package = pkgs.terraform;
              stages = [ "pre-commit" ];
            };
            terraform-validate = {
              enable = true;
              package = pkgs.terraform;
              entry = ''
                bash -c '
                  set -uo pipefail
                  status=0

                  while read -r dir; do
                    lockfile="$dir/.terraform.lock.hcl"
                    backup=$(mktemp)
                    had_lockfile=false

                    if [ -f "$lockfile" ]; then
                      cp "$lockfile" "$backup"
                      had_lockfile=true
                    fi

                    ${pkgs.terraform}/bin/terraform -chdir="$dir" init -backend=false
                    init_status=$?

                    if [ "$init_status" -eq 0 ]; then
                      ${pkgs.terraform}/bin/terraform -chdir="$dir" validate
                      validate_status=$?
                    else
                      validate_status=$init_status
                    fi

                    if [ "$had_lockfile" = true ]; then
                      cp "$backup" "$lockfile"
                    else
                      rm -f "$lockfile"
                    fi
                    rm -f "$backup"

                    if [ "$validate_status" -ne 0 ]; then
                      status=$validate_status
                    fi
                  done < <(for arg in "$@"; do dirname "$arg"; done | sort | uniq)

                  exit "$status"
                ' --
              '';
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
              description = "Run RuboCop through Bundler on changed Ruby files";
              entry = ''
                bash -c '
                  changed_files=$(git diff --name-only --diff-filter=ACM --merge-base main | grep -E "\\.(rb|rake)$|^(Gemfile|Rakefile|config\\.ru)$" || true)

                  if [ -n "$changed_files" ]; then
                    bundle exec rubocop --autocorrect --force-exclusion $changed_files
                  fi
                '
              '';
              files = "\\.(rb|rake)$|^(Gemfile|Rakefile|config\\.ru)$";
              pass_filenames = false;
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
        devShells.review = self.devShells.${system}.default.overrideAttrs (old: {
          shellHook = "";
          PRE_COMMIT_NO_CONCURRENCY = "1";
          GOMAXPROCS = "2";
          nativeBuildInputs = [
            pkgs.gitMinimal
            pkgs.pre-commit
            pkgs.curl
            pkgs.jq
            pkgs.util-linux
            reviewTools.terraform
            reviewTools.tflint
            reviewTools.terraform-docs
            (pkgs.writeShellApplication {
              name = "review-bootstrap";
              text = reviewEnvironment + ''
                for archive in /deps/gem-archives/*.gem; do
                  [ -f "$archive" ] || continue
                  gem install --local --no-document --ignore-dependencies "$archive"
                done
                bundle check || bundle install --local
                bundle binstubs --all
                initdb -D "$PGDATA" -U postgres --auth=trust --encoding=UTF8 --no-locale
                pg_ctl -D "$PGDATA" -l "$TMPDIR/postgres.log" -o "-k $PGHOST -c listen_addresses=" -w start
                pg_isready -h "$PGHOST" -U postgres
                bundle exec rails db:create db:schema:load
                printf 'disable_checkpoint = true\nprovider_installation {\n filesystem_mirror {\n path = "/deps/terraform-inputs/providers"\n include = ["registry.terraform.io/*/*"]\n }\n}\n' > "$TF_CLI_CONFIG_FILE"
                files="$(git ls-files '*.tf')"
                test -n "$files"
                mapfile -t roots < <(printf '%s\n' "$files" | while IFS= read -r file; do dirname "$file"; done | sort -u)
                for root in "''${roots[@]}"; do
                  mkdir -p "$root/.terraform/modules"
                  if [ -f "/deps/terraform-inputs/roots/$root/modules.json" ]; then cp "/deps/terraform-inputs/roots/$root/modules.json" "$root/.terraform/modules/modules.json"; fi
                  if [ ! -f "$root/.terraform.lock.hcl" ]; then cp "/deps/terraform-inputs/roots/$root/lock.hcl" "$root/.terraform.lock.hcl"; fi
                  terraform -chdir="$root" init -backend=false -input=false -lockfile=readonly -no-color
                  mkdir -p "/workspace/.review/terraform-locks/$root"
                  cp "$root/.terraform.lock.hcl" "/workspace/.review/terraform-locks/$root/.terraform.lock.hcl"
                  # Init verifies the ZIP against the committed hashes. Validate also needs
                  # the Linux content hash, which providers lock records from that mirror.
                  terraform -chdir="$root" providers lock -fs-mirror=/deps/terraform-inputs/providers -platform=linux_amd64
                done
              '';
            })
            (pkgs.writeShellApplication {
              name = "review-check";
              text = reviewEnvironment + ''
                restore_review_locks() {
                  while IFS= read -r -d "" lockfile; do
                    cp "$lockfile" "''${lockfile#/workspace/.review/terraform-locks/}"
                  done < <(find /workspace/.review/terraform-locks -type f -name .terraform.lock.hcl -print0)
                }
                trap restore_review_locks EXIT
                status=0
                pre-commit run --all-files --config ${reviewPreCommitConfig} || status=$?
                pre-commit run --all-files --hook-stage pre-push --config ${reviewPreCommitConfig} || status=$?
                bundle exec brakeman || status=$?
                bundle exec rspec --format progress --format json --out "$TMPDIR/unit.json" || status=$?
                ruby -rjson -e 's = JSON.parse(File.read(ARGV[0])).fetch("summary"); abort "Unit tests failed or skipped" unless s.fetch("example_count").positive? && s.fetch("failure_count").zero? && s.fetch("pending_count").zero?' "$TMPDIR/unit.json" || status=$?
                restore_review_locks
                trap - EXIT
                exit "$status"
              '';
            })
          ]
          ++ (old.nativeBuildInputs or [ ]);
          BUNDLE_BUILD__PG = builtins.concatStringsSep " " postgresqlBuildFlags;
          BUNDLE_BUILD__PSYCH = builtins.concatStringsSep " " psychBuildFlags;
          TZDIR = "${pkgs.tzdata.outPath}/share/zoneinfo";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        });

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
