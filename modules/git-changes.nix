{ pkgs, ... }:

let
  gitChanges = pkgs.writeShellApplication {
    name = "git-changes";

    runtimeInputs = with pkgs; [
      coreutils
      gawk
      git
    ];

    text = ''
      set -euo pipefail

      MODE=summary
      DATA_FILE=""
      declare -A TRACKED_STATUS=()

      usage_line() {
        printf '%s\n' 'Usage: git changes [--files|-f] [--help|-h]'
      }

      usage() {
        cat <<'EOF'
Usage:
  git changes              Show total uncommitted changes
  git changes -f           Show total + per-file changes
  git changes --files      Same as -f
  git changes -h           Show help
  git changes --help       Show help

Includes:
  - staged tracked changes
  - unstaged tracked changes
  - untracked files, including their contents as additions
  - files not ignored by Git; .gitignore and standard excludes are respected

Detailed output:
  CHG is additions + deletions. Files are sorted by CHG, largest first.
  ST statuses are M modified, A added/tracked new file, D deleted,
  T type changed, and U untracked. Other single-letter Git statuses may
  be shown if Git reports them. Rename detection is kept off so each
  line-count record stays aligned with its path; a rename is therefore
  normally shown as a D row and an A row.
  Binary files count as changed files, but Git does not provide line
  counts for them, so their CHG, +, and - columns display "bin".
EOF
      }

      die() {
        printf 'git changes: %s\n' "$*" >&2
        exit 1
      }

      fail_usage() {
        printf 'git changes: %s\n' "$*" >&2
        usage_line >&2
        exit 2
      }

      cleanup() {
        if [[ -n "''${DATA_FILE:-}" && -e "$DATA_FILE" ]]; then
          rm -f -- "$DATA_FILE"
        fi
      }

      parse_args() {
        if (( $# == 0 )); then
          return
        fi

        if (( $# != 1 )); then
          fail_usage "expected zero or one argument"
        fi

        case "$1" in
          -f|--files)
            MODE=files
            ;;

          -h|--help)
            usage
            exit 0
            ;;

          *)
            fail_usage "unknown argument: $1"
            ;;
        esac
      }

      ensure_git_repo() {
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
          die "not inside a Git repository"
      }

      create_data_file() {
        DATA_FILE="$(mktemp "''${TMPDIR:-/tmp}/git-changes.XXXXXX")"
        trap cleanup EXIT
      }

      append_record() {
        # Records are NUL-delimited so paths containing newlines do not split
        # the data stream. The tab-separated fields keep the renderers simple.
        printf '%s\t%s\t%s\t%s\0' "$1" "$2" "$3" "$4" >> "$DATA_FILE"
      }

      collect_tracked_statuses() {
        local raw_status path status

        while IFS= read -r -d "" raw_status &&
              IFS= read -r -d "" path; do
          [[ -n "$path" ]] || continue

          status="''${raw_status:0:1}"
          case "$status" in
            M|A|D|T|U|R|C)
              ;;
            *)
              status=M
              ;;
          esac

          TRACKED_STATUS["$path"]="$status"
        done < <(
          git diff HEAD --name-status --no-renames -z --
        )
      }

      collect_head_changes() {
        local added deleted path status

        collect_tracked_statuses

        while IFS=$'\t' read -r -d "" added deleted path; do
          [[ -n "$path" ]] || continue

          status="''${TRACKED_STATUS["$path"]:-M}"
          append_record "$added" "$deleted" "$status" "$path"
        done < <(
          git diff HEAD --numstat --no-renames -z --
        )
      }

      append_no_index_record() {
        local status="$1"
        local path="$2"
        local stats added deleted

        stats="$(
          git diff --no-index --numstat -- /dev/null "$path" 2>/dev/null || true
        )"

        if [[ -n "$stats" ]]; then
          IFS=$'\t' read -r added deleted _ <<< "$stats"
        else
          added=0
          deleted=0
        fi

        append_record "$added" "$deleted" "$status" "$path"
      }

      append_index_record() {
        local path="$1"
        local stats added deleted

        stats="$(
          git diff --cached --numstat --no-renames -- "$path" 2>/dev/null || true
        )"

        if [[ -n "$stats" ]]; then
          IFS=$'\t' read -r added deleted _ <<< "$stats"
        else
          added=0
          deleted=0
        fi

        append_record "$added" "$deleted" A "$path"
      }

      collect_unborn_changes() {
        local path

        # With no HEAD, the final worktree contents are the useful baseline.
        # Indexed paths are treated as tracked additions; untracked paths are
        # still separate so their U status remains visible.
        while IFS= read -r -d "" path; do
          [[ -n "$path" ]] || continue

          if [[ -e "$path" || -L "$path" ]]; then
            append_no_index_record A "$path"
          else
            append_index_record "$path"
          fi
        done < <(
          git ls-files --cached -z | LC_ALL=C sort -z -u
        )

        while IFS= read -r -d "" path; do
          [[ -n "$path" ]] || continue
          append_no_index_record U "$path"
        done < <(
          git ls-files --others --exclude-standard -z | LC_ALL=C sort -z -u
        )
      }

      collect_untracked_changes() {
        local path

        while IFS= read -r -d "" path; do
          [[ -n "$path" ]] || continue
          append_no_index_record U "$path"
        done < <(
          git ls-files --others --exclude-standard -z | LC_ALL=C sort -z -u
        )
      }

      print_summary() {
        gawk -v RS='\0' -F '\t' '
          NF >= 4 {
            files++

            if ($1 ~ /^[0-9]+$/) {
              additions += $1
            }

            if ($2 ~ /^[0-9]+$/) {
              deletions += $2
            }
          }

          END {
            printf "%d files changed, +%d -%d\n",
              files,
              additions,
              deletions
          }
        ' "$DATA_FILE"
      }

      print_files() {
        printf '\n'
        printf '%8s %8s %8s  %-2s %s\n' \
          "CHG" \
          "+" \
          "-" \
          "ST" \
          "FILE"

        # Add a sortable churn field, sort NUL-delimited records, then render
        # the columns. Reconstructing the final field preserves tabs in paths
        # as well as the normal spaces handled by the CLI contract.
        gawk -v RS='\0' -F '\t' '
          NF >= 4 {
            added = $1
            deleted = $2

            if (added ~ /^[0-9]+$/ && deleted ~ /^[0-9]+$/) {
              churn = added + deleted
            } else {
              churn = -1
            }

            path = $4
            for (i = 5; i <= NF; i++) {
              path = path FS $i
            }

            printf "%d\t%s\t%s\t%s\t%s%c",
              churn,
              added,
              deleted,
              $3,
              path,
              0
          }
        ' "$DATA_FILE" |
          LC_ALL=C sort -z -t $'\t' -k1,1nr -k5,5 |
          gawk -v RS='\0' -F '\t' '
            NF >= 5 {
              churn = $1
              added = $2
              deleted = $3
              status = $4

              path = $5
              for (i = 6; i <= NF; i++) {
                path = path FS $i
              }

              if (churn >= 0) {
                churn_display = churn
              } else {
                churn_display = "bin"
              }

              if (added ~ /^[0-9]+$/) {
                added_display = "+" added
              } else {
                added_display = "bin"
              }

              if (deleted ~ /^[0-9]+$/) {
                deleted_display = "-" deleted
              } else {
                deleted_display = "bin"
              }

              printf "%8s %8s %8s  %-2s %s\n",
                churn_display,
                added_display,
                deleted_display,
                status,
                path
            }
          '
      }

      main() {
        parse_args "$@"
        ensure_git_repo
        create_data_file

        if git rev-parse --verify HEAD >/dev/null 2>&1; then
          collect_head_changes
          collect_untracked_changes
        else
          collect_unborn_changes
        fi

        print_summary

        if [[ "$MODE" == files ]]; then
          print_files
        fi
      }

      main "$@"
    '';
  };

  gitChangesMan = pkgs.writeTextFile {
    name = "git-changes-manual";
    destination = "/share/man/man1/git-changes.1";
    text = ''
      .TH GIT-CHANGES 1
      .SH NAME
      git-changes \- summarize the current Git working-tree changes
      .SH SYNOPSIS
      .B git changes
      .br
      .B git changes \-f
      .br
      .B git changes \-\-files
      .br
      .B git changes \-h
      .br
      .B git changes \-\-help
      .SH DESCRIPTION
      Counts the complete current change set: staged tracked changes, unstaged
      tracked changes, and untracked files. Untracked file contents are counted
      as additions. Git's standard excludes and .gitignore are respected.
      .SH DETAILED OUTPUT
      With \fB\-f\fR or \fB\-\-files\fR, the summary is followed by one row per
      changed file, sorted by descending \fBCHG\fR. CHG means additions plus
      deletions.
      .PP
      The status column uses M for modified, A for added or tracked new files,
      D for deleted, T for type changed, and U for untracked files. Rename
      detection is disabled so line-count records remain aligned with paths;
      a rename is normally shown as separate D and A rows.
      .SH BINARY FILES
      Binary files count as changed files. Git does not expose line counts for
      them, so their CHG, additions, and deletions columns are shown as \fBbin\fR
      instead of invented numbers.
      .SH EXIT STATUS
      Returns zero on success. Invalid arguments return a non-zero status.
    '';
  };

  gitChangesPackage = pkgs.symlinkJoin {
    name = "git-changes";
    paths = [
      gitChanges
      gitChangesMan
    ];
  };

in
{
  environment.systemPackages = [
    gitChangesPackage
  ];
}
