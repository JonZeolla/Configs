#
# Zenable
#
# Zenable is a notification tool for displaying alerts in your prompt
# when any environment variables starting with ZENABLE_ are set
#
# Based on https://github.com/spaceship-prompt/spaceship-section/tree/main and
# https://spaceship-prompt.sh/api/section/
# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_ZENABLE_SHOW="${SPACESHIP_ZENABLE_SHOW=true}"
# Per guidelines, env var based logic should be sync
# https://spaceship-prompt.sh/advanced/creating-section/#Section-should-be-fast
SPACESHIP_ZENABLE_ASYNC="${SPACESHIP_ZENABLE_ASYNC=false}"
# SPACESHIP_ZENABLE_PREFIX="${SPACESHIP_ZENABLE_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"}"
# SPACESHIP_ZENABLE_SUFFIX="${SPACESHIP_ZENABLE_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_ZENABLE_SYMBOL="${SPACESHIP_ZENABLE_SYMBOL="⚠️ "}"
SPACESHIP_ZENABLE_COLOR="${SPACESHIP_ZENABLE_COLOR="red"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

# Show Zenable status
# spaceship_ prefix before section's name is required!
# Otherwise this section won't be loaded.
spaceship_zenable() {
  # If SPACESHIP_ZENABLE_SHOW is false, don't show zenable section
  [[ $SPACESHIP_ZENABLE_SHOW == false ]] && return

  # Check if any environment variable starts with ZENABLE_
  local zenable_var_found=false
  for var in ${(k)parameters}; do
    if [[ $var == ZENABLE_* ]]; then
      zenable_var_found=true
      break
    fi
  done

  # If no ZENABLE_ variable is found, don't show the section
  [[ $zenable_var_found == false ]] && return

  # Display the zenable section using spaceship::section::v4
  spaceship::section::v4 \
    --color="$SPACESHIP_ZENABLE_COLOR" \
    --symbol="$SPACESHIP_ZENABLE_SYMBOL" \
    ""
    # --prefix="$SPACESHIP_ZENABLE_PREFIX" \
    # --suffix="$SPACESHIP_ZENABLE_SUFFIX" \
}
