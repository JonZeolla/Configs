#!/usr/bin/env bash

# Shellcheck false positive suppressions:
# SC2178: This warning incorrectly flags nameref variables (declare -n) when they're
#         used as arrays. This is a known shellcheck limitation with bash 4.3+ namerefs.
#         Our usage is correct - we're passing arrays by reference using namerefs.
# SC2034: Variables appear unused because they're passed to functions as nameref
#         arguments. Shellcheck doesn't track this usage pattern correctly.
# shellcheck disable=SC2178,SC2034

set -euo pipefail

# Script configuration - define early for cleanup
# Allow overriding from environment for testing
WORKTREE_BASE="${WORKTREE_BASE:-/tmp/git-split-worktrees}"

# Clean up worktrees function - define early for trap
cleanup_worktrees() {
    if [[ -d "$WORKTREE_BASE" ]]; then
        # Use debug if available, otherwise use printf
        if declare -f debug >/dev/null 2>&1; then
            debug "Cleaning up worktrees..."
        else
            printf "Cleaning up worktrees...\n" >&2
        fi
        git worktree prune 2>/dev/null || true
        rm -rf "$WORKTREE_BASE" 2>/dev/null || true
    fi
}

# Handle interruption gracefully - define early for trap
interrupt_handler() {
    echo
    # Use error if available, otherwise echo to stderr
    if declare -f error >/dev/null 2>&1; then
        error "Operation interrupted by user"
    else
        echo "Error: Operation interrupted by user" >&2
    fi
    cleanup_worktrees
    exit 130  # Standard exit code for SIGINT
}

# Set up cleanup trap immediately
trap interrupt_handler INT TERM

# Check bash version (we need 4.3+ for nameref support)
if [[ ${BASH_VERSION%%.*} -lt 4 ]] || { [[ ${BASH_VERSION%%.*} -eq 4 ]] && [[ ${BASH_VERSION#*.} -lt 3 ]]; }; then
    echo "Error: This script requires bash 4.3 or later for nameref support."
    echo "Your bash version: $BASH_VERSION"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_NAME="$(basename "$0")"
# WORKTREE_BASE already defined earlier for cleanup trap
MAIN_BRANCH="main"

# Help function
show_help() {
    cat << EOF
${GREEN}Git Branch Splitter${NC}

${CYAN}DESCRIPTION:${NC}
    An interactive tool to split changes from your current branch across multiple branches.

    This script helps you reorganize your uncommitted and committed changes by:
    - Identifying all files changed compared to origin/main
    - Allowing you to assign each file to either the current branch or new branches
    - Creating new branches with the assigned files
    - Reverting moved files from the original branch with clean revert commits

${CYAN}USAGE:${NC}
    $SCRIPT_NAME [options]

${CYAN}OPTIONS:${NC}
    -h, --help     Show this help message
    -v, --verbose  Enable verbose output

${CYAN}REQUIREMENTS:${NC}
    - Must be run from within a git repository
    - Cannot be run from the main branch
    - Requires git worktree support
    - Requires an internet connection to fetch from origin

${CYAN}WORKFLOW:${NC}
    1. Script validates you're in a git repo and not on main
    2. Fetches latest from origin/main
    3. Shows all changed files compared to origin/main
    4. Prompts you to define branch names for splitting
    5. For each file, you assign it to a branch (or keep on current)
       During assignment, you can use:
       - d: Show git diff for the file
       - v: Open the file in vi
       - p: Print/cat the file contents
       - u: Undo last assignment and go back
    6. Creates new branches and migrates files
    7. Creates revert commits on original branch for moved files
    8. Shows final report with GitHub PR links

${CYAN}NOTES:${NC}
    - Each file is handled independently
    - Only entire file changes are moved (not partial changes)
    - New branches are created from origin/main using git worktrees
    - Original commit history is not preserved in new branches
    - Revert commits maintain history on the original branch

${CYAN}EXAMPLE:${NC}
    $ $SCRIPT_NAME

    # The script will interactively guide you through:
    # 1. Viewing changed files
    # 2. Creating branch mappings
    # 3. Assigning files to branches
    # 4. Committing changes
    # 5. Generating PR links

EOF
}

# Parse command line arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Logging functions
log() {
    echo -e "${GREEN}==>${NC} $1"
}

error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

info() {
    echo -e "${CYAN}INFO:${NC} $1"
}

debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}DEBUG:${NC} $1"
    fi
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository!"
        echo "Please run this script from within a git repository."
        exit 1
    fi
}

# Get current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Check if we're on main branch
check_not_on_main() {
    local current_branch
    current_branch=$(get_current_branch)
    if [[ "$current_branch" == "$MAIN_BRANCH" ]] || [[ "$current_branch" == "master" ]]; then
        error "Cannot run from main/master branch!"
        echo "Please checkout a feature branch first."
        show_help
        exit 1
    fi
}

# Fetch latest from origin
fetch_origin() {
    log "Fetching latest from origin..."
    if ! git fetch origin "$MAIN_BRANCH" 2>/dev/null; then
        error "Failed to fetch from origin. Is your internet connection working?"
        exit 1
    fi
}

# Get list of changed files compared to origin/main
get_changed_files() {
    # Get files that have changes (both staged and unstaged)
    git diff --name-only "origin/$MAIN_BRANCH"...HEAD | sort -u
}

# Get the diff for a specific file
get_file_diff() {
    local file="$1"
    git diff "origin/$MAIN_BRANCH"...HEAD -- "$file"
}

# Create a worktree for a branch
create_worktree() {
    local branch_name="$1"
    local worktree_path="$WORKTREE_BASE/$branch_name"

    # Remove worktree if it already exists
    if [[ -d "$worktree_path" ]]; then
        git worktree remove --force "$worktree_path" 2>/dev/null || true
    fi

    # Create new worktree from origin/main
    debug "Creating worktree for branch '$branch_name' at $worktree_path"
    git worktree add -b "$branch_name" "$worktree_path" "origin/$MAIN_BRANCH" >/dev/null 2>&1
    echo "$worktree_path"
}



# Apply file changes to a worktree
apply_file_to_worktree() {
    local file="$1"
    local worktree_path="$2"
    # local original_branch="$3"  # Currently unused, kept for potential future use

    debug "Applying changes for $file to worktree"

    # Create directory structure if needed
    local file_dir
    file_dir=$(dirname "$file")
    if [[ "$file_dir" != "." ]]; then
        mkdir -p "$worktree_path/$file_dir"
    fi

    # Get the file content from the original branch
    if git show "HEAD:$file" >/dev/null 2>&1; then
        git show "HEAD:$file" > "$worktree_path/$file"
        
        # Preserve file permissions from git
        local file_mode
        file_mode=$(git ls-tree HEAD "$file" | awk '{print $1}')
        if [[ "$file_mode" == "100755" ]]; then
            chmod +x "$worktree_path/$file"
            debug "Set executable permission for $file"
        fi
    else
        # File might be new (untracked), copy it
        if [[ -f "$file" ]]; then
            cp -p "$file" "$worktree_path/$file"  # -p preserves permissions
        fi
    fi
}

# Commit changes in a worktree
commit_in_worktree() {
    local worktree_path="$1"
    local branch_name="$2"
    local -n files_ref=$3

    cd "$worktree_path"

    # Add all files
    for file in "${files_ref[@]}"; do
        if [[ -f "$file" ]]; then
            git add "$file"
        fi
    done

    # Check if there are changes to commit
    if ! git diff --cached --quiet; then
        echo
        log "Committing changes to branch '$branch_name'"
        echo "Files to be committed:"
        for file in "${files_ref[@]}"; do
            echo "  - $file"
        done
        echo
        read -r -p "Enter commit message for branch '$branch_name': " commit_msg

        git commit -m "$commit_msg"
        info "Changes committed to branch '$branch_name'"
    else
        warn "No changes to commit on branch '$branch_name'"
    fi

    cd - >/dev/null
}

# Create revert commit for moved files
create_revert_commit() {
    local -n files_ref=$1
    local target_branch="$2"

    if [[ ${#files_ref[@]} -eq 0 ]]; then
        return
    fi

    log "Creating revert commit for files moved to '$target_branch'"

    # Create a temporary patch file
    local patch_file="/tmp/git-split-revert-$$.patch"

    # Generate reverse patch for the files
    for file in "${files_ref[@]}"; do
        # Get the reverse diff (what would undo the changes)
        git diff "origin/$MAIN_BRANCH" HEAD -- "$file" | sed 's/^+/-temp-/; s/^-/+/; s/^-temp-/-/' >> "$patch_file"
    done

    # Apply the reverse patch
    if [[ -s "$patch_file" ]]; then
        git apply "$patch_file" 2>/dev/null || {
            # If simple apply fails, try to manually revert files
            for file in "${files_ref[@]}"; do
                if git show "origin/$MAIN_BRANCH:$file" >/dev/null 2>&1; then
                    git show "origin/$MAIN_BRANCH:$file" > "$file"
                else
                    # File was new, remove it
                    rm -f "$file"
                fi
            done
        }

        # Stage the reverted files
        for file in "${files_ref[@]}"; do
            if [[ -f "$file" ]]; then
                git add "$file"
            else
                git rm --cached "$file" 2>/dev/null || true
            fi
        done

        # Commit the revert
        local file_list
        file_list=$(printf '%s, ' "${files_ref[@]}")
        file_list=${file_list%, }
        git commit -m "Revert: Move files to branch '$target_branch'

Moved files: $file_list"

        info "Created revert commit for ${#files_ref[@]} file(s)"
    fi

    rm -f "$patch_file"
}

# Get GitHub repository URL
get_github_repo_url() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    # Convert SSH URL to HTTPS URL
    if [[ "$remote_url" =~ ^git@github.com:(.+)\.git$ ]]; then
        echo "https://github.com/${BASH_REMATCH[1]}"
    elif [[ "$remote_url" =~ ^https://github.com/(.+)\.git$ ]]; then
        echo "https://github.com/${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Generate PR link
generate_pr_link() {
    local branch_name="$1"
    local repo_url
    repo_url=$(get_github_repo_url)

    if [[ -n "$repo_url" ]]; then
        echo "${repo_url}/pull/new/${branch_name}"
    else
        echo "(Unable to generate PR link - repository URL not found)"
    fi
}

# Validate branch name
validate_branch_name() {
    local branch_name="$1"

    if [[ -z "$branch_name" ]]; then
        return 1
    fi

    if [[ "$branch_name" =~ [[:space:]] ]]; then
        error "Branch name cannot contain spaces"
        return 1
    fi

    return 0
}

# Prompt for yes/no confirmation
confirm_prompt() {
    local prompt="$1"
    local response

    while true; do
        read -r -p "$prompt (y/n): " response
        case "$response" in
            [Yy])
                return 0
                ;;
            [Nn])
                return 1
                ;;
            *)
                error "Please answer 'y' for yes or 'n' for no"
                ;;
        esac
    done
}

# Display changed files
display_changed_files() {
    local -n files_ref=$1

    log "Found ${#files_ref[@]} changed file(s):"
    for i in "${!files_ref[@]}"; do
        printf "  ${CYAN}%2d)${NC} %s\n" $((i + 1)) "${files_ref[$i]}"
    done
}

# Configure branches for splitting
configure_branches() {
    local current_branch="$1"
    local -n branch_map_ref=$2
    local -n branch_count_ref=$3

    log "Branch Configuration"
    echo "Let's define the branches you want to split changes across."
    echo -e "Branch 1 will be your current branch: ${CYAN}$current_branch${NC}"
    echo

    branch_map_ref[1]="$current_branch"
    branch_count_ref=1

    while true; do
        read -r -p "Enter name for branch $((branch_count_ref + 1)) (or press Enter to finish): " branch_name
        if [[ -z "$branch_name" ]]; then
            break
        fi

        if ! validate_branch_name "$branch_name"; then
            continue
        fi

        # Check if branch already exists
        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            warn "Branch '$branch_name' already exists locally"
            if ! confirm_prompt "Do you want to use it anyway?"; then
                continue
            fi
        fi

        branch_count_ref=$((branch_count_ref + 1))
        branch_map_ref["$branch_count_ref"]="$branch_name"
        info "Added branch $branch_count_ref: ${CYAN}$branch_name${NC}"
    done

    if [[ $branch_count_ref -eq 1 ]]; then
        error "No additional branches specified. Need at least one target branch."
        return 1
    fi

    # Verify that all branches were stored correctly (workaround for bash nameref issues)
    local verify_count=0
    for i in $(seq 1 "$branch_count_ref"); do
        if [[ -v "branch_map_ref[$i]" ]]; then
            verify_count=$((verify_count + 1))
        else
            debug "Warning: branch_map[$i] is not set after configuration"
        fi
    done

    if [[ $verify_count -ne $branch_count_ref ]]; then
        error "Internal error: Only $verify_count of $branch_count_ref branches were stored correctly."
        error "This might be due to a bash version incompatibility."
        error "Please ensure you're using bash 4.3 or later."
        return 1
    fi

    return 0
}

# Show branch summary
show_branch_summary() {
    local -n branch_map_ref=$1
    local branch_count=$2

    log "Branch Summary:"
    for i in $(seq 1 "$branch_count"); do
        # Check if the array element exists before accessing it
        if [[ -v "branch_map_ref[$i]" ]]; then
            echo -e "  ${CYAN}$i)${NC} ${branch_map_ref[$i]}"
        else
            error "Internal error: branch $i not found in branch map"
            error "This might be due to a bash version incompatibility with associative array namerefs"
            exit 1
        fi
    done
}

# Assign files to branches
assign_files_to_branches() {
    local -n changed_files_ref=$1
    local -n file_assignments_ref=$2
    local branch_count=$3
    local branch_map_name=$4  # Changed from nameref to just the name
    local file_index=0
    local total_files=${#changed_files_ref[@]}

    log "File Assignment"
    echo "For each file, enter the branch number (1-$branch_count) or press Enter for default (1):"
    echo "Additional options: d=diff, v=vi, p=print, u=undo"
    echo

    # Use index-based loop to allow going backwards
    while (( file_index < total_files )); do
        local file="${changed_files_ref[$file_index]}"

        # Re-show branch summary every 5 files
        if (( file_index > 0 && file_index % 5 == 0 )); then
            echo
            show_branch_summary "$branch_map_name" "$branch_count"
            echo
        fi

        while true; do
            read -r -p "  $file -> Branch [1]: " choice

            # Handle special commands
            case "$choice" in
                d|D)
                    # Show git diff for this file
                    echo
                    echo -e "${CYAN}Diff for $file:${NC}"
                    git diff "origin/$MAIN_BRANCH"...HEAD -- "$file" | less -R
                    echo
                    # Re-show branch summary after diff
                    show_branch_summary "$branch_map_name" "$branch_count"
                    echo
                    continue
                    ;;
                v|V)
                    # Open file in vi
                    vi "$file"
                    echo
                    # Re-show branch summary after vi
                    show_branch_summary "$branch_map_name" "$branch_count"
                    echo
                    continue
                    ;;
                p|P)
                    # Print/cat the file
                    echo
                    echo -e "${CYAN}Contents of $file:${NC}"
                    if [[ -f "$file" ]]; then
                        cat -n "$file" | less
                    else
                        warn "File not found in working directory"
                    fi
                    echo
                    # Re-show branch summary after print
                    show_branch_summary "$branch_map_name" "$branch_count"
                    echo
                    continue
                    ;;
                u|U)
                    # Undo - go back to previous file
                    if (( file_index > 0 )); then
                        file_index=$((file_index - 1))
                        local prev_file="${changed_files_ref[$file_index]}"
                        # Remove the previous assignment
                        unset "file_assignments_ref[$prev_file]"
                        info "Going back to: $prev_file"
                        echo
                        break  # Break inner loop to re-process previous file
                    else
                        warn "Already at the first file, cannot go back"
                        continue
                    fi
                    ;;
            esac

            # Default to 1 if empty
            if [[ -z "$choice" ]]; then
                choice=1
            fi

            # Validate choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= branch_count )); then
                file_assignments_ref["$file"]=$choice
                file_index=$((file_index + 1))
                break
            else
                error "Invalid choice. Please enter a number between 1 and $branch_count, or d/v/p/u for commands"
            fi
        done
    done
}

# Organize files by branch
organize_files_by_branch() {
    local -n file_assignments_ref=$1
    local -n branch_files_ref=$2

    for file in "${!file_assignments_ref[@]}"; do
        local branch_num=${file_assignments_ref[$file]}
        # Check if the key exists, if not initialize it
        if [[ ! -v "branch_files_ref[$branch_num]" ]]; then
            branch_files_ref[$branch_num]=""
        fi

        if [[ -z "${branch_files_ref[$branch_num]}" ]]; then
            branch_files_ref[$branch_num]="$file"
        else
            branch_files_ref[$branch_num]+=" $file"
        fi
    done
}

# Show assignment summary
show_assignment_summary() {
    local -n branch_map_ref=$1
    local -n branch_files_ref=$2
    local branch_count=$3

    log "Assignment Summary:"
    for i in $(seq 1 "$branch_count"); do
        local branch="${branch_map_ref[$i]}"
        # Check if branch_files_ref[$i] exists before accessing it
        if [[ -v "branch_files_ref[$i]" ]]; then
            IFS=' ' read -r -a files <<< "${branch_files_ref[$i]}"
            echo -e "  ${CYAN}$branch${NC}: ${#files[@]} file(s)"
            if [[ ${#files[@]} -gt 0 ]]; then
                for file in "${files[@]}"; do
                    echo "    - $file"
                done
            fi
        else
            # No files assigned to this branch
            echo -e "  ${CYAN}$branch${NC}: 0 file(s)"
        fi
    done
}

# Process branches and create worktrees
process_branches() {
    local current_branch="$1"
    local -n branch_map_ref=$2
    local -n branch_files_ref=$3
    local -n created_branches_ref=$4
    local branch_count=$5

    for i in $(seq 2 "$branch_count"); do
        local branch="${branch_map_ref[$i]}"
        # Default to empty string if branch_files_ref[$i] doesn't exist
        IFS=' ' read -r -a files <<< "${branch_files_ref[$i]:-}"

        if [[ ${#files[@]} -eq 0 ]]; then
            debug "No files assigned to branch '$branch', skipping"
            continue
        fi

        log "Processing branch: ${CYAN}$branch${NC}"

        # Create worktree
        local worktree_path
        worktree_path=$(create_worktree "$branch")
        created_branches_ref["$branch"]="$worktree_path"

        # Apply files to worktree
        for file in "${files[@]}"; do
            apply_file_to_worktree "$file" "$worktree_path" "$current_branch"
        done

        # Commit changes in worktree
        commit_in_worktree "$worktree_path" "$branch" files
    done
}

# Create revert commits for moved files
create_revert_commits() {
    local -n branch_map_ref=$1
    local -n branch_files_ref=$2
    local branch_count=$3

    log "Creating revert commits on current branch..."
    for i in $(seq 2 "$branch_count"); do
        local branch="${branch_map_ref[$i]}"
        # Default to empty string if branch_files_ref[$i] doesn't exist
        IFS=' ' read -r -a files <<< "${branch_files_ref[$i]:-}"

        if [[ ${#files[@]} -gt 0 ]]; then
            create_revert_commit files "$branch"
        fi
    done
}

# Show final report
show_final_report() {
    local current_branch="$1"
    local -n branch_files_ref=$2
    local -n created_branches_ref=$3
    local -n worktrees_pruned_ref=$4

    echo
    echo "======================================"
    log "Final Report"
    echo "======================================"
    echo

    # Show current branch status
    echo -e "${CYAN}Current branch ($current_branch):${NC}"
    IFS=' ' read -r -a remaining_files <<< "${branch_files_ref[1]}"
    echo "  Files remaining: ${#remaining_files[@]}"
    if git diff --name-only --cached | grep -q .; then
        echo -e "  ${YELLOW}Note: You have staged changes${NC}"
    fi
    echo -e "  Push command: ${BLUE}git push -u origin $current_branch${NC}"
    echo -e "  PR link: ${BLUE}$(generate_pr_link "$current_branch")${NC}"
    echo

    # Show created branches
    echo -e "${CYAN}Created/Updated branches:${NC}"
    for branch in "${!created_branches_ref[@]}"; do
        echo -e "  ${GREEN}✓${NC} $branch"
        echo -e "    Push command: ${BLUE}git push -u origin $branch${NC}"
        echo -e "    PR link: ${BLUE}$(generate_pr_link "$branch")${NC}"
        echo
    done

    # Prompt to push branches
    if [[ ${#created_branches_ref[@]} -gt 0 ]]; then
        echo
        if confirm_prompt "Would you like to push all branches to origin?"; then
            log "Pushing branches to origin..."

            # Push current branch first
            echo -e "  Pushing ${CYAN}$current_branch${NC} (current branch with revert commits)..."
            if git push -u origin "$current_branch" 2>&1; then
                echo -e "  ${GREEN}✓${NC} Successfully pushed $current_branch"
            else
                error "Failed to push $current_branch"
            fi

            # Push created branches
            for branch in "${!created_branches_ref[@]}"; do
                echo -e "  Pushing ${CYAN}$branch${NC}..."
                if git push -u origin "$branch" 2>&1; then
                    echo -e "  ${GREEN}✓${NC} Successfully pushed $branch"
                else
                    error "Failed to push $branch"
                fi
            done
            echo

            # Clean up worktrees after successful push
            log "Cleaning up worktrees..."
            git worktree prune
            cleanup_worktrees
            info "Worktrees cleaned up successfully"
            worktrees_pruned_ref=true
        fi
    fi

    log "Branch splitting complete!"
    echo
    echo "Next steps:"
    echo "1. Review the changes on each branch"
    echo "2. Create pull requests using the generated links above"
}

# Main script logic
main() {
    # Initial checks
    check_git_repo
    check_not_on_main

    local current_branch
    current_branch=$(get_current_branch)
    log "Current branch: ${CYAN}$current_branch${NC}"

    # Fetch latest
    fetch_origin

    # Get changed files
    log "Analyzing changed files compared to origin/$MAIN_BRANCH..."
    mapfile -t changed_files < <(get_changed_files)

    if [[ ${#changed_files[@]} -eq 0 ]]; then
        info "No changed files found compared to origin/$MAIN_BRANCH"
        exit 0
    fi

    echo
    display_changed_files changed_files

    # Set up branch configuration
    echo
    declare -A branch_map
    local branch_count
    if ! configure_branches "$current_branch" branch_map branch_count; then
        exit 1
    fi

    # Show branch summary
    echo
    show_branch_summary branch_map "$branch_count"

    # File assignment phase
    echo
    declare -A file_assignments
    assign_files_to_branches changed_files file_assignments "$branch_count" "branch_map"

    # Organize files by branch
    declare -A branch_files
    # Initialize branch_files with numeric keys
    for i in $(seq 1 "$branch_count"); do
        branch_files[$i]=""
    done
    organize_files_by_branch file_assignments branch_files

    # Show assignment summary
    echo
    show_assignment_summary branch_map branch_files "$branch_count"

    # Confirmation
    echo
    if ! confirm_prompt "Proceed with branch splitting?"; then
        info "Operation cancelled"
        exit 0
    fi

    # Create worktrees directory
    mkdir -p "$WORKTREE_BASE"

    # Process each branch (except current)
    declare -A created_branches
    process_branches "$current_branch" branch_map branch_files created_branches "$branch_count"

    # Create revert commits on current branch for moved files
    create_revert_commits branch_map branch_files "$branch_count"

    # Final report (this will handle pushing and may prune worktrees)
    local worktrees_pruned=false
    show_final_report "$current_branch" branch_files created_branches worktrees_pruned

    # Ask user if they want to clean up (only if not already pruned)
    if [[ "$worktrees_pruned" != "true" ]]; then
        echo
        if confirm_prompt "Would you like to clean up the temporary worktrees?"; then
            cleanup_worktrees
        else
            info "Worktrees preserved at: $WORKTREE_BASE"
            info "You can manually clean them up later with: rm -rf $WORKTREE_BASE"
        fi
    fi
}


# Run main function only if script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
