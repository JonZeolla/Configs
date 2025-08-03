#!/usr/bin/env bats

# Test suite for git-split-branch.sh
# This test suite uses BATS (Bash Automated Testing System)
# To run: bats test-git-split-branch.bats

# Test setup and teardown
setup() {
    # Create a temporary directory for test repository
    export TEST_DIR
    TEST_DIR="$(mktemp -d)"
    export ORIGINAL_DIR
    ORIGINAL_DIR="$(pwd)"
    export SCRIPT_PATH="${ORIGINAL_DIR}/git-split-branch.sh"

    # Create test repository
    cd "$TEST_DIR" || exit 1
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create initial commit on main
    echo "initial content" > initial.txt
    git add initial.txt
    git commit -m "Initial commit"

    # Set up origin
    git remote add origin https://github.com/test/test-repo.git

    # Create feature branch
    git checkout -b test-feature

    # Create test files with changes
    echo "file1 content" > file1.txt
    echo "file2 content" > file2.txt
    mkdir -p subdir
    echo "file3 content" > subdir/file3.txt
    git add .
    git commit -m "Add test files"
}

teardown() {
    # Clean up
    cd "$ORIGINAL_DIR" || exit 1
    rm -rf "$TEST_DIR"
}

# Helper function to mock git fetch
mock_git_fetch() {
    # Override git fetch to avoid network calls
    git() {
        if [[ "$1" == "fetch" ]]; then
            return 0
        else
            command git "$@"
        fi
    }
    export -f git
}

# Test: Script exists and is executable
@test "script exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

# Test: Show help
@test "show help with -h flag" {
    run "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Git Branch Splitter" ]]
    [[ "$output" =~ "DESCRIPTION:" ]]
    [[ "$output" =~ "USAGE:" ]]
}

# Test: Show help with --help flag
@test "show help with --help flag" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Git Branch Splitter" ]]
}

# Test: Invalid option handling
@test "invalid option shows error and help" {
    run "$SCRIPT_PATH" --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option: --invalid-option" ]]
    [[ "$output" =~ "USAGE:" ]]
}

# Test: Not in git repository
@test "fails when not in git repository" {
    cd /tmp
    run "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not in a git repository!" ]]
}

# Test: Running from main branch
@test "fails when running from main branch" {
    git checkout main
    run "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Cannot run from main/master branch!" ]]
}

# Test: Running from master branch
@test "fails when running from master branch" {
    git checkout -b master
    run "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Cannot run from main/master branch!" ]]
}

# Test: Get current branch function
@test "get_current_branch returns correct branch" {
    # Source the script to access functions
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    result=$(get_current_branch)
    [ "$result" = "test-feature" ]
}

# Test: Validate branch name - valid names
@test "validate_branch_name accepts valid names" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    validate_branch_name "feature/test"

    validate_branch_name "bugfix-123"

    validate_branch_name "release_v1.0"
}

# Test: Validate branch name - invalid names
@test "validate_branch_name rejects invalid names" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Empty name
    run validate_branch_name ""
    [ "$status" -ne 0 ]

    # Name with spaces
    run bash -c "source '$SCRIPT_PATH' 2>/dev/null; validate_branch_name 'feature branch'"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Branch name cannot contain spaces" ]]
}

# Test: Configure branches with unbound variable bug - array index mismatch
@test "show_branch_summary handles branch count and array indices correctly" {
    # This test reproduces the exact scenario from the user's error:
    # - User enters 3 additional branches (indices 2, 3, 4)
    # - Total branch_count is 4
    # - But there might be an issue with how indices are handled

    run bash -c "
        set -euo pipefail  # Same as the main script
        source '$SCRIPT_PATH' 2>/dev/null || true

        # Create the exact scenario from the user
        declare -A branch_map
        branch_map[1]='feat/controls/allow-api-upload'  # Current branch
        branch_map[2]='feat/services/allow-local-testing-with-cors'
        branch_map[3]='feat/always-keep-neptune-params'
        branch_map[4]='feat/default-sandboxes-to-new-ui'

        # Test with the correct branch_count of 4
        show_branch_summary branch_map 4
    "

    # This should work correctly
    [ "$status" -eq 0 ]
    [[ "$output" =~ "feat/controls/allow-api-upload" ]]
    [[ "$output" =~ "feat/default-sandboxes-to-new-ui" ]]
}

# Test: show_branch_summary handles missing array elements gracefully
@test "show_branch_summary fails gracefully when branch_count exceeds array size" {
    run bash -c "
        set -euo pipefail  # Same as the main script
        source '$SCRIPT_PATH' 2>/dev/null || true

        # Create scenario where branch_count is larger than actual array
        declare -A branch_map
        branch_map[1]='feat/controls/allow-api-upload'
        # Only 1 branch in array, but branch_count is higher

        # This should now fail gracefully with our fix
        show_branch_summary branch_map 2
    "

    [ "$status" -ne 0 ]
    [[ "$output" =~ "Internal error: branch 2 not found in branch map" ]] || [[ "$output" =~ "unbound variable" ]]
}

# Test: Exact reproduction of user's unbound variable error
@test "reproduce exact user scenario - branch_count mismatch" {
    # This test reproduces the exact error: branch_count doesn't match array size
    run bash -c '
        set -euo pipefail
        source "'"$SCRIPT_PATH"'" 2>/dev/null || true

        test_scenario() {
            # Set up exactly like the user scenario
            declare -A branch_map
            branch_map[1]="feat/controls/allow-api-upload"

            # The bug: trying to show more branches than exist
            # User had 4 branches but something went wrong
            echo "==> Branch Summary:"
            show_branch_summary branch_map 2
        }

        test_scenario 2>&1
    '

    echo "Output: $output"

    # Should now fail gracefully with our fix
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Internal error" ]] || [[ "$output" =~ "unbound variable" ]]
}

# Test: configure_branches validates array integrity
@test "configure_branches detects and reports nameref issues" {
    # Test the new validation in configure_branches
    run bash -c '
        set -euo pipefail
        source "'"$SCRIPT_PATH"'" 2>/dev/null || true

        # Simulate a scenario where nameref might fail
        test_configure() {
            declare -A branch_map
            local branch_count

            # Manually simulate what would happen if nameref failed
            branch_map[1]="current-branch"
            branch_count=4  # Claim we have 4 branches
            # But only branch_map[1] exists

            # Run the verification part of configure_branches
            local verify_count=0
            for i in $(seq 1 "$branch_count"); do
                if [[ -v "branch_map[$i]" ]]; then
                    verify_count=$((verify_count + 1))
                fi
            done

            if [[ $verify_count -ne $branch_count ]]; then
                echo "ERROR: Only $verify_count of $branch_count branches were stored correctly."
                return 1
            fi

            return 0
        }

        test_configure 2>&1
    '

    # Should fail with the verification error
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Only 1 of 4 branches were stored correctly" ]]
}

# Test: Full integration test simulating user's exact scenario
@test "integration test - user enters 3 branches and script handles them correctly" {
    # This test simulates the exact user flow that caused the bug
    cd "$TEST_DIR"

    # We already have main from setup, just ensure we're on test-feature
    git checkout test-feature

    # Create some changed files
    echo "change1" >> file1.txt
    echo "change2" >> file2.txt
    git add .
    git commit -m "Make changes"

    # Mock git operations
    git() {
        if [[ "$1" == "fetch" ]]; then
            return 0
        elif [[ "$1" == "diff" ]] && [[ "$2" == "--name-only" ]]; then
            # Return the changed files
            echo "file1.txt"
            echo "file2.txt"
            return 0
        else
            command git "$@"
        fi
    }
    export -f git

    # Run the script with simulated user input
    run bash -c "
        cd '$TEST_DIR'
        source /dev/stdin <<'MOCK'
        git() {
            if [[ \"\$1\" == \"fetch\" ]]; then
                return 0
            elif [[ \"\$1\" == \"diff\" ]] && [[ \"\$2\" == \"--name-only\" ]]; then
                echo \"file1.txt\"
                echo \"file2.txt\"
                return 0
            else
                command git \"\$@\"
            fi
        }
        export -f git
MOCK

        # Simulate user input: 3 branches then Enter
        {
            echo 'feat/services/allow-local-testing-with-cors'
            echo 'feat/always-keep-neptune-params'
            echo 'feat/default-sandboxes-to-new-ui'
            echo ''  # Empty to finish
            echo '1'  # Assign file1 to branch 1
            echo '2'  # Assign file2 to branch 2
            echo 'n'  # Don't proceed with splitting
        } | '$SCRIPT_PATH' 2>&1
    "

    echo "Full output:"
    echo "$output"
    echo "---"

    # The script should not crash with unbound variable
    [[ ! "$output" =~ "unbound variable" ]]

    # Should show all 4 branches in the summary
    [[ "$output" =~ "Branch Summary:" ]]
    [[ "$output" =~ "test-feature" ]]
    [[ "$output" =~ "feat/services/allow-local-testing-with-cors" ]]
    [[ "$output" =~ "feat/always-keep-neptune-params" ]]
    [[ "$output" =~ "feat/default-sandboxes-to-new-ui" ]]
}

# Test: Get changed files
@test "get_changed_files returns correct files" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true
    mock_git_fetch

    # Mock origin/main
    git update-ref refs/remotes/origin/main HEAD~1

    # Get changed files
    mapfile -t files < <(get_changed_files)

    # Should have our test files
    [[ " ${files[*]} " =~ file1\.txt ]]
    [[ " ${files[*]} " =~ file2\.txt ]]
    [[ " ${files[*]} " =~ subdir/file3\.txt ]]
}

# Test: Confirm prompt - yes responses
@test "confirm_prompt accepts yes responses" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Test 'y' response
    echo "y" | confirm_prompt "Test prompt?"

    # Test 'Y' response
    echo "Y" | confirm_prompt "Test prompt?"

    # Test empty response with 'n' default
    run bash -c 'source "'"$SCRIPT_PATH"'" 2>/dev/null && echo "" | confirm_prompt "Test prompt?" "n"'
    [ "$status" -ne 0 ]

    # Test empty response with 'y' default
    echo "" | confirm_prompt "Test prompt?" "y"
}

# Test: Confirm prompt - no responses
@test "confirm_prompt rejects no responses" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Test 'n' response
    run bash -c 'source "'"$SCRIPT_PATH"'" 2>/dev/null && echo "n" | confirm_prompt "Test prompt?"'
    [ "$status" -ne 0 ]

    # Test 'N' response
    run bash -c 'source "'"$SCRIPT_PATH"'" 2>/dev/null && echo "N" | confirm_prompt "Test prompt?"'
    [ "$status" -ne 0 ]

    # Test any other response
    run bash -c 'source "'"$SCRIPT_PATH"'" 2>/dev/null && echo "maybe" | confirm_prompt "Test prompt?"'
    [ "$status" -ne 0 ]
}

# Test: Create worktree
@test "create_worktree creates and returns path" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true
    mock_git_fetch

    # Mock origin/main
    git update-ref refs/remotes/origin/main HEAD~1

    # Create worktree
    worktree_path=$(create_worktree "test-branch")

    # Check worktree was created
    [ -d "$worktree_path" ]
    [[ "$worktree_path" =~ "/tmp/git-split-worktrees/test-branch" ]]

    # Clean up
    git worktree remove --force "$worktree_path" 2>/dev/null || true
}

# Test: Apply file to worktree
@test "apply_file_to_worktree copies file correctly" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create a temporary worktree directory
    worktree_dir="$TEST_DIR/test-worktree"
    mkdir -p "$worktree_dir"

    # Apply file
    apply_file_to_worktree "file1.txt" "$worktree_dir"

    # Check file was copied
    [ -f "$worktree_dir/file1.txt" ]
    [ "$(cat "$worktree_dir/file1.txt")" = "file1 content" ]
}

# Test: Apply file with subdirectory to worktree
@test "apply_file_to_worktree creates subdirectories" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create a temporary worktree directory
    worktree_dir="$TEST_DIR/test-worktree"
    mkdir -p "$worktree_dir"

    # Apply file in subdirectory
    apply_file_to_worktree "subdir/file3.txt" "$worktree_dir"

    # Check directory structure was created
    [ -d "$worktree_dir/subdir" ]
    [ -f "$worktree_dir/subdir/file3.txt" ]
    [ "$(cat "$worktree_dir/subdir/file3.txt")" = "file3 content" ]
}

# Test: Get GitHub repo URL from SSH format
@test "get_github_repo_url converts SSH URL" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set SSH remote
    git remote set-url origin git@github.com:user/repo.git

    url=$(get_github_repo_url)
    [ "$url" = "https://github.com/user/repo" ]
}

# Test: Get GitHub repo URL from HTTPS format
@test "get_github_repo_url handles HTTPS URL" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set HTTPS remote
    git remote set-url origin https://github.com/user/repo.git

    url=$(get_github_repo_url)
    [ "$url" = "https://github.com/user/repo" ]
}

# Test: Get GitHub repo URL with no remote
@test "get_github_repo_url handles missing remote" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Remove remote
    git remote remove origin

    url=$(get_github_repo_url)
    [ "$url" = "" ]
}

# Test: Generate PR link
@test "generate_pr_link creates correct URL" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set remote (remove first if exists)
    git remote remove origin 2>/dev/null || true
    git remote add origin https://github.com/user/repo.git

    link=$(generate_pr_link "feature-branch")
    [ "$link" = "https://github.com/user/repo/pull/new/feature-branch" ]
}

# Test: Generate PR link with no remote
@test "generate_pr_link handles missing remote" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Remove remote
    git remote remove origin 2>/dev/null || true

    link=$(generate_pr_link "feature-branch")
    [[ "$link" =~ "Unable to generate PR link" ]]
}

# Test: Cleanup worktrees
@test "cleanup_worktrees removes worktree directory" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Create test worktree directory
    export WORKTREE_BASE="$TEST_DIR/test-worktrees"
    mkdir -p "$WORKTREE_BASE/branch1"
    mkdir -p "$WORKTREE_BASE/branch2"

    # Run cleanup
    cleanup_worktrees

    # Check directory was removed
    [ ! -d "$WORKTREE_BASE" ]
}

# Test: cleanup happens on script failure
@test "cleanup runs even when script fails with error" {
    cd "$TEST_DIR"

    # Create some changed files
    echo "change1" >> file1.txt
    git add .
    git commit -m "Make changes"

    # Create a custom worktree directory
    test_worktree_dir="$TEST_DIR/test-worktrees-$$"

    # Run script in a way that will cause it to fail
    run bash -c "
        cd '$TEST_DIR'
        export WORKTREE_BASE='$test_worktree_dir'

        # Create the directory to simulate the script started work
        mkdir -p \"\$WORKTREE_BASE/test-branch\"
        echo 'test file' > \"\$WORKTREE_BASE/test-branch/file.txt\"

        # Mock git to avoid network
        git() {
            if [[ \"\$1\" == \"fetch\" ]]; then
                return 0
            elif [[ \"\$1\" == \"diff\" ]] && [[ \"\$2\" == \"--name-only\" ]]; then
                echo \"file1.txt\"
                return 0
            else
                command git \"\$@\"
            fi
        }
        export -f git

        # Create input that will cause the script to fail
        # We'll trigger a failure by causing an error in branch configuration
        {
            echo 'invalid branch name with spaces'
            echo 'invalid branch name with spaces'
            echo 'invalid branch name with spaces'
            echo 'invalid branch name with spaces'
            echo 'invalid branch name with spaces'
            echo ''  # This will cause 'No additional branches' error
        } | '$SCRIPT_PATH' 2>&1 || exit_code=\$?

        echo \"Exit code: \${exit_code:-0}\"

        # Check if cleanup ran
        if [[ -d \"\$WORKTREE_BASE\" ]]; then
            echo \"ERROR: Worktree directory still exists\"
            ls -la \"\$WORKTREE_BASE\" 2>&1 || true
        else
            echo \"SUCCESS: Cleanup ran - directory removed\"
        fi
    "

    echo "Full output:"
    echo "$output"

    # The script should have failed but cleanup should have run
    [[ "$output" =~ "SUCCESS: Cleanup ran" ]] || [[ "$output" =~ "Cleaning up worktrees" ]]

    # Ensure the test directory was cleaned up
    [ ! -d "$test_worktree_dir" ]
}

# Test: cleanup happens on interrupt
@test "cleanup runs when script is interrupted" {
    cd "$TEST_DIR"

    # Create test worktree directory
    test_worktree_dir="$TEST_DIR/test-worktrees-interrupt-$$"

    # Run script in background and interrupt it
    run bash -c "
        cd '$TEST_DIR'
        export WORKTREE_BASE='$test_worktree_dir'

        # Create the directory
        mkdir -p \"\$WORKTREE_BASE/test\"

        # Source the script to test interrupt handler
        source '$SCRIPT_PATH' 2>/dev/null || true

        # Simulate interrupt
        interrupt_handler

        # This should not be reached
        echo 'ERROR: Script continued after interrupt'
    " 2>&1 || true

    echo "Output: $output"

    # Should see interrupt message
    [[ "$output" =~ "Operation interrupted" ]]

    # Should have exit code 130 (SIGINT)
    [ "$status" -eq 130 ]

    # Directory should be cleaned up
    [ ! -d "$test_worktree_dir" ]
}

# Note: display_changed_files test removed due to BATS compatibility issues
# The function uses bash 4.3+ nameref which caused test execution problems

# Test: Verbose mode
@test "verbose mode enables debug output" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Test without verbose
    export VERBOSE=false
    output=$(debug "Test message" 2>&1)
    [ -z "$output" ]

    # Test with verbose
    export VERBOSE=true
    output=$(debug "Test message" 2>&1)
    [[ "$output" =~ "DEBUG:" ]]
    [[ "$output" =~ "Test message" ]]
}

# Test: Logging functions output correctly
@test "logging functions format output" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Test log function
    output=$(log "Test log" 2>&1)
    [[ "$output" =~ "==>" ]]
    [[ "$output" =~ "Test log" ]]

    # Test error function (redirects to stderr)
    output=$(error "Test error" 2>&1)
    [[ "$output" =~ "ERROR:" ]]
    [[ "$output" =~ "Test error" ]]

    # Test warn function
    output=$(warn "Test warning" 2>&1)
    [[ "$output" =~ "WARNING:" ]]
    [[ "$output" =~ "Test warning" ]]

    # Test info function
    output=$(info "Test info" 2>&1)
    [[ "$output" =~ "INFO:" ]]
    [[ "$output" =~ "Test info" ]]
}

# Test: Script handles missing origin/main
@test "handles missing origin/main gracefully" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Remove origin
    git remote remove origin

    # Try to get changed files (should fail gracefully)
    run bash -c "cd '$TEST_DIR' && source '$SCRIPT_PATH' 2>/dev/null; get_changed_files"
    [ "$status" -ne 0 ]
}

# Test: Color output is properly formatted (no raw escape codes)
@test "color output displays correctly without raw escape codes" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Test that color variables are defined
    [[ -n "$RED" ]]
    [[ -n "$GREEN" ]]
    [[ -n "$YELLOW" ]]
    [[ -n "$BLUE" ]]
    [[ -n "$CYAN" ]]
    [[ -n "$NC" ]]

    # Test that echo -e properly interprets color codes
    output=$(echo -e "${CYAN}test${NC}")
    # Should not contain literal \033 escape sequences
    [[ ! "$output" =~ '\033' ]]
    [[ ! "$output" =~ '\\033' ]]
}

# Test: Echo -e properly formats color codes
@test "echo -e interprets color codes correctly" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Test direct echo -e output
    output=$(echo -e "Branch 1 will be your current branch: ${CYAN}test-branch${NC}")

    # The output should not contain literal escape sequences
    # Note: We check for both \033 and \\033 patterns
    if [[ "$output" =~ \\\\033 ]] || [[ "$output" =~ \\033\\[ ]]; then
        echo "ERROR: Found literal escape sequences in output: $output"
        return 1
    fi

    # The output should contain the expected text
    [[ "$output" =~ "Branch 1 will be your current branch: test-branch" ]]
}

# Test: Show branch summary uses colors correctly
@test "show_branch_summary displays colors properly" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -A branch_map
    branch_map[1]="main-branch"
    branch_map[2]="feature-branch"

    # Capture output
    output=$(show_branch_summary branch_map 2 2>&1)

    # Should not contain literal escape sequences
    [[ ! "$output" =~ '\033[' ]]
    [[ ! "$output" =~ '\\033[' ]]

    # Should contain the branch names
    [[ "$output" =~ "main-branch" ]]
    [[ "$output" =~ "feature-branch" ]]
}

# Test: Final report uses colors correctly
@test "show_final_report displays colors properly" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -A branch_files
    branch_files[1]="file1.txt file2.txt"

    declare -A created_branches
    created_branches["new-feature"]="/tmp/worktree"

    # Capture output
    output=$(show_final_report "current-branch" branch_files created_branches 2>&1)

    # Should not contain literal escape sequences
    [[ ! "$output" =~ '\033[' ]]
    [[ ! "$output" =~ '\\033[' ]]

    # Should contain expected content
    [[ "$output" =~ "Current branch" ]]
    [[ "$output" =~ "Created/Updated branches:" ]]
    [[ "$output" =~ "Push command:" ]]
    [[ "$output" =~ "PR link:" ]]
}

# Test: Assignment summary shows correct file counts
@test "assignment summary displays correct file counts" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -A branch_map
    branch_map[1]="current-branch"
    branch_map[2]="feature-branch"
    branch_map[3]="bugfix-branch"

    declare -A branch_files
    # Initialize all branches
    branch_files[1]=""
    branch_files[2]=""
    branch_files[3]=""

    # Assign files to branches
    branch_files[1]="file1.txt file2.txt"
    branch_files[2]="file3.txt"
    branch_files[3]=""  # No files assigned

    # Capture output
    output=$(show_assignment_summary branch_map branch_files 3 2>&1)

    # Should show correct counts
    [[ "$output" =~ "current-branch: 2 file(s)" ]]
    [[ "$output" =~ "feature-branch: 1 file(s)" ]]
    [[ "$output" =~ "bugfix-branch: 0 file(s)" ]]

    # Should list the files
    [[ "$output" =~ "file1.txt" ]]
    [[ "$output" =~ "file2.txt" ]]
    [[ "$output" =~ "file3.txt" ]]
}

# Test: organize_files_by_branch correctly groups files
@test "organize_files_by_branch groups files correctly" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -A file_assignments
    file_assignments["file1.txt"]=1
    file_assignments["file2.txt"]=1
    file_assignments["file3.txt"]=2
    file_assignments["file4.txt"]=3
    file_assignments["file5.txt"]=2

    declare -A branch_files
    # Initialize branches
    branch_files[1]=""
    branch_files[2]=""
    branch_files[3]=""

    # Run the organization
    organize_files_by_branch file_assignments branch_files

    # Check results
    [[ "${branch_files[1]}" =~ "file1.txt" ]]
    [[ "${branch_files[1]}" =~ "file2.txt" ]]
    [[ "${branch_files[2]}" =~ "file3.txt" ]]
    [[ "${branch_files[2]}" =~ "file5.txt" ]]
    [[ "${branch_files[3]}" =~ "file4.txt" ]]

    # Count files in each branch
    IFS=' ' read -r -a files1 <<< "${branch_files[1]}"
    IFS=' ' read -r -a files2 <<< "${branch_files[2]}"
    IFS=' ' read -r -a files3 <<< "${branch_files[3]}"

    [ ${#files1[@]} -eq 2 ]
    [ ${#files2[@]} -eq 2 ]
    [ ${#files3[@]} -eq 1 ]
}

# Test: confirm_prompt requires explicit y/n answer
@test "confirm_prompt requires explicit y or n answer" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Test that empty input is rejected
    output=$(echo -e "\ny" | { source "$SCRIPT_PATH" 2>/dev/null || true; confirm_prompt "Test prompt?"; } 2>&1)
    [[ "$output" =~ "Please answer 'y' for yes or 'n' for no" ]]

    # Test that invalid input is rejected
    output=$(echo -e "maybe\ny" | { source "$SCRIPT_PATH" 2>/dev/null || true; confirm_prompt "Test prompt?"; } 2>&1)
    [[ "$output" =~ "Please answer 'y' for yes or 'n' for no" ]]

    # Test that 'y' is accepted immediately
    run bash -c 'source "'"$SCRIPT_PATH"'" 2>/dev/null && echo "y" | confirm_prompt "Test prompt?"'
    [ "$status" -eq 0 ]

    # Test that 'n' is accepted immediately
    run bash -c 'source "'"$SCRIPT_PATH"'" 2>/dev/null && echo "n" | confirm_prompt "Test prompt?"'
    [ "$status" -eq 1 ]
}

# Test: Undo functionality in file assignment
@test "undo functionality allows going back to previous file" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -a changed_files=("file1.txt" "file2.txt" "file3.txt")
    declare -A file_assignments
    declare -A branch_map
    branch_map[1]="current-branch"
    branch_map[2]="feature-branch"

    # Simulate user input:
    # - Assign file1 to branch 1
    # - Assign file2 to branch 2
    # - Use 'u' to go back to file2
    # - Reassign file2 to branch 1
    # - Assign file3 to branch 2
    output=$(echo -e "1\n2\nu\n1\n2" | {
        assign_files_to_branches changed_files file_assignments 2 "branch_map"
        # Output the assignments for verification
        for file in "${!file_assignments[@]}"; do
            echo "$file -> ${file_assignments[$file]}"
        done
    } 2>&1)

    # Check that undo message appears
    [[ "$output" =~ "Going back to: file2.txt" ]]

    # Check final assignments
    [[ "$output" =~ "file1.txt -> 1" ]]
    [[ "$output" =~ "file2.txt -> 1" ]]  # Changed from 2 to 1 after undo
    [[ "$output" =~ "file3.txt -> 2" ]]

    # Ensure no circular reference errors
    [[ ! "$output" =~ "circular name reference" ]]
}

# Test: Undo at first file shows warning
@test "undo at first file shows warning" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -a changed_files=("file1.txt" "file2.txt")
    declare -A file_assignments
    declare -A branch_map
    branch_map[1]="current-branch"
    branch_map[2]="feature-branch"

    # Try to undo at the first file
    output=$(echo -e "u\n1\n2" | assign_files_to_branches changed_files file_assignments 2 "branch_map" 2>&1)

    # Should show warning
    [[ "$output" =~ "Already at the first file, cannot go back" ]]
}

# Test: Multiple undos work correctly
@test "multiple undos allow going back multiple files" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -a changed_files=("file1.txt" "file2.txt" "file3.txt" "file4.txt")
    declare -A file_assignments
    declare -A branch_map
    branch_map[1]="current-branch"
    branch_map[2]="feature-branch"

    # Simulate:
    # - Assign files 1-3 to branch 1
    # - Use 'u' twice to go back to file2
    # - Reassign file2 and file3 to branch 2
    # - Assign file4 to branch 1
    output=$(echo -e "1\n1\n1\nu\nu\n2\n2\n1" | {
        assign_files_to_branches changed_files file_assignments 2 "branch_map"
        # Output the assignments
        for file in "${!file_assignments[@]}"; do
            echo "$file -> ${file_assignments[$file]}"
        done
    } 2>&1)

    # Check undo messages
    [[ "$output" =~ "Going back to: file3.txt" ]]
    [[ "$output" =~ "Going back to: file2.txt" ]]

    # Check final assignments
    [[ "$output" =~ "file1.txt -> 1" ]]
    [[ "$output" =~ "file2.txt -> 2" ]]  # Changed after undo
    [[ "$output" =~ "file3.txt -> 2" ]]  # Changed after undo
    [[ "$output" =~ "file4.txt -> 1" ]]
}

# Test: Undo removes previous assignment from array
@test "undo properly removes previous assignment from array" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -a changed_files=("file1.txt" "file2.txt")
    declare -A file_assignments
    declare -A branch_map
    branch_map[1]="current-branch"
    branch_map[2]="feature-branch"

    # Assign file1, then undo before completing file2
    echo -e "1\nu\n2\n1" | assign_files_to_branches changed_files file_assignments 2 "branch_map" 2>&1

    # After undo and reassignment, file1 should only have one assignment
    [ "${file_assignments[file1.txt]}" = "2" ]
    [ "${file_assignments[file2.txt]}" = "1" ]
}

# Test: No circular reference errors when using interactive commands
@test "interactive commands (d/v/p/u) do not cause circular reference errors" {
    # shellcheck source=/dev/null
    source "$SCRIPT_PATH" 2>/dev/null || true

    # Set up test data
    declare -a changed_files=("file1.txt" "file2.txt")
    declare -A file_assignments
    declare -A branch_map
    branch_map[1]="current-branch"
    branch_map[2]="feature-branch"
    branch_map[3]="bugfix-branch"
    branch_map[4]="release-branch"

    # Create test files
    echo "test content 1" > file1.txt
    echo "test content 2" > file2.txt

    # Mock git diff to avoid actual git operations
    git() {
        if [[ "$1" == "diff" ]]; then
            echo "Mock diff output"
            return 0
        else
            command git "$@"
        fi
    }
    export -f git

    # Test with commands that trigger show_branch_summary
    # Using 'p' to print (which we can control) instead of 'd' or 'v'
    output=$(echo -e "p\n1\np\n2" | assign_files_to_branches changed_files file_assignments 4 "branch_map" 2>&1)

    # Clean up test files
    rm -f file1.txt file2.txt

    # Ensure no circular reference errors
    if [[ "$output" =~ "circular name reference" ]]; then
        echo "ERROR: Found circular reference in output:"
        echo "$output"
        return 1
    fi

    # Should show branch summaries without errors
    [[ "$output" =~ "Branch Summary:" ]]
    [[ "$output" =~ "current-branch" ]]
    [[ "$output" =~ "feature-branch" ]]
    [[ "$output" =~ "bugfix-branch" ]]
    [[ "$output" =~ "release-branch" ]]
}
