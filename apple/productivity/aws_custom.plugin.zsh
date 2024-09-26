#
# AWS_CUSTOM (Custom)
#
# Lets you know if your currently configured AWS_CUSTOM credentials are valid
#
# Based on https://github.com/spaceship-prompt/spaceship-section/tree/main and
# https://spaceship-prompt.sh/api/section/
# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_AWS_CUSTOM_SHOW="${SPACESHIP_AWS_CUSTOM_SHOW=true}"
# Per guidelines, calling external commands should be async
# https://spaceship-prompt.sh/advanced/creating-section/#Section-should-be-fast
SPACESHIP_AWS_CUSTOM_ASYNC="${SPACESHIP_AWS_CUSTOM_ASYNC=true}"
# SPACESHIP_AWS_CUSTOM_PREFIX="${SPACESHIP_AWS_CUSTOM_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"}"
# SPACESHIP_AWS_CUSTOM_SUFFIX="${SPACESHIP_AWS_CUSTOM_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_AWS_CUSTOM_SYMBOL="${SPACESHIP_AWS_CUSTOM_SYMBOL="❌"}"
SPACESHIP_AWS_CUSTOM_COLOR="${SPACESHIP_AWS_CUSTOM_COLOR="red"}"

# Cache settings
AWS_CACHE_FILE="/tmp/aws_sts_cache"
AWS_CACHE_TTL=30

# Function to check if AWS STS cache is valid
check_aws_sts_cache() {
  if [[ -f "$AWS_CACHE_FILE" ]]; then
    local last_updated=$(stat -c %Y "$AWS_CACHE_FILE")
    local current_time=$(date +%s)
    if (( current_time - last_updated < AWS_CACHE_TTL )); then
      return 0 # Valid
    fi
  fi
  return 1 # Invalid
}

# Function to update the AWS STS cache
update_aws_sts_cache() {
  if aws sts get-caller-identity &> /dev/null; then
    echo "valid" > "$AWS_CACHE_FILE"
  else
    echo "invalid" > "$AWS_CACHE_FILE"
  fi
}

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show aws status
# spaceship_ prefix before section's name is required!
# Otherwise this section won't be loaded.
spaceship_aws_custom() {
  # If SPACESHIP_AWS_CUSTOM_SHOW is false, don't show aws_custom section
  [[ $SPACESHIP_AWS_CUSTOM_SHOW == false ]] && return

  ## Check if AWS_CUSTOM credentials are valid by running sts get-caller-identity
  # Check AWS STS cache
  local aws_sts_invalid=false
  if check_aws_sts_cache; then
    # Read cached status
    local cache_status=$(cat "$AWS_CACHE_FILE")
    if [[ $cache_status == "invalid" ]]; then
      aws_sts_invalid=true
    fi
  else
    # Cache is invalid, run sts check and update cache
    update_aws_sts_cache
    local cache_status=$(cat "$AWS_CACHE_FILE")
    if [[ $cache_status == "invalid" ]]; then
      aws_sts_invalid=true
    fi
  fi

  # If the AWS_CUSTOM creds are aren't an issue, don't show the section
  [[ $aws_sts_invalid == false ]] && return

  # Display the aws section using spaceship::section::v4
  spaceship::section::v4 \
    --color "$SPACESHIP_AWS_CUSTOM_COLOR" \
    --symbol "$SPACESHIP_AWS_CUSTOM_SYMBOL" \
    ""
    # --prefix="$SPACESHIP_AWS_CUSTOM_PREFIX" \
    # --suffix="$SPACESHIP_AWS_CUSTOM_SUFFIX" \
}
