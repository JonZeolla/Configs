#
# Zenable
#
# Zenable is a notification tool for displaying alerts in your prompt
# when certain environment variables starting with ZENABLE_ are set
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
SPACESHIP_PYTHON_SYMBOL="${SPACESHIP_PYTHON_SYMBOL="🐍"}"

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
  # Check for specific env vars
  local zenable_account=""
  local zenable_environment=""
  local pythonpath_var_found=false

  for var in ${(k)parameters}; do
    # Skip alerting on loglevel; should be obvious and is regularly set
    if [[ $var == ZENABLE_* ]] && [[ $var != "ZENABLE_LOGLEVEL" ]]; then
      zenable_var_found=true
      if [[ $var == "ZENABLE_ACCOUNT" ]]; then
        zenable_account="${(P)var}"
      elif [[ $var == "ZENABLE_ENVIRONMENT" ]]; then
        zenable_environment="${(P)var}"
      # Selectively don't alert or track certain variables
      elif [[ $var != "ZENABLE_GITHUB_APP_INSTALLATION_ID" && $var != "ZENABLE_SUBDOMAIN" && $var != "ZENABLE_API_KEY" ]]; then
        # Otherwise, flag another ZENABLE_ env var as found for alerting
        other_zenable_var_found=true
      fi
    fi

    if [[ $var == *PYTHONPATH* ]] && [[ -n "${(P)var}" ]]; then
      pythonpath_var_found=true
    fi
  done

  local zenable_info=""
  # Create the prompt content for account and environment
  if [[ -n $zenable_account ]]; then
    zenable_info+="[Account: $zenable_account] "
  fi
  if [[ -n $zenable_environment ]]; then
    zenable_info+="[Environment: $zenable_environment] "
  fi

  # Add Python-related symbol if PYTHONPATH-related variables are found
  if [[ $pythonpath_var_found == true ]]; then
    zenable_info+="$SPACESHIP_PYTHON_SYMBOL "
  fi

  # Display the zenable section using spaceship::section::v4
  # Only display a symbol if a ZENABLE_ env var was found which _wasn't_ ACCOUNT or ENVIRONMENT
  spaceship::section::v4 \
    --color "$SPACESHIP_ZENABLE_COLOR" \
    ${other_zenable_var_found:+--symbol "$SPACESHIP_ZENABLE_SYMBOL"} \
    "${zenable_info}"
}
