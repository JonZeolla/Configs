#\!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="/Users/jonzeolla/src/jonzeolla/configs/apple/productivity/bin/git-split-branch.sh"
}

@test "display_changed_files shows numbered list" {
    source "$SCRIPT_PATH" 2>/dev/null || true
    
    local test_files=("file1.txt" "file2.txt" "subdir/file3.txt")
    output=$(display_changed_files test_files 2>&1)
    
    [[ "$output" =~ Found\ 3\ changed\ file\(s\): ]]
    [[ "$output" =~ 1\)\ file1\.txt ]]
    [[ "$output" =~ 2\)\ file2\.txt ]]
    [[ "$output" =~ 3\)\ subdir/file3\.txt ]]
}
