#
# Working directory
#
# Custom working directory management in the prompt
#
# This is a fork of https://github.com/spaceship-prompt/spaceship-prompt/blob/7c1667f00309426d32f0463deffe10de6bd59313/sections/dir.zsh

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_DIR_SHOW="${SPACESHIP_DIR_SHOW=true}"
SPACESHIP_DIR_PREFIX="${SPACESHIP_DIR_PREFIX="in "}"
SPACESHIP_DIR_SUFFIX="${SPACESHIP_DIR_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
SPACESHIP_DIR_TRUNC="${SPACESHIP_DIR_TRUNC=3}"
SPACESHIP_DIR_TRUNC_PREFIX="${SPACESHIP_DIR_TRUNC_PREFIX=}"
SPACESHIP_DIR_TRUNC_REPO="${SPACESHIP_DIR_TRUNC_REPO=true}"
SPACESHIP_DIR_COLOR="${SPACESHIP_DIR_COLOR="cyan"}"
SPACESHIP_DIR_LOCK_SYMBOL="${SPACESHIP_DIR_LOCK_SYMBOL=" "}"
SPACESHIP_DIR_LOCK_COLOR="${SPACESHIP_DIR_LOCK_COLOR="red"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

spaceship_dir_custom() {
  [[ $SPACESHIP_DIR_SHOW == false ]] && return

  local dir trunc_prefix

  # Treat repo root as a top-level directory or not
  if [[ $SPACESHIP_DIR_TRUNC_REPO == true ]] && spaceship::is_git; then
    local git_root=$(git rev-parse --show-toplevel)
    local repo_name=$(basename "$git_root")

    if (cygpath --version) >/dev/null 2>/dev/null; then
      git_root=$(cygpath -u $git_root)
    fi

    # Check if the parent of the $git_root is "/"
    if [[ $git_root:h == / ]]; then
      trunc_prefix=/
    else
      trunc_prefix=$SPACESHIP_DIR_TRUNC_PREFIX
    fi

    # Custom logic only for zenable repos
    if [[ $git_root == */zenable/* ]]; then
      local current_dir=$(pwd)
      local relative_path=${current_dir#$git_root/}

      if [[ $relative_path == services/* ]]; then
        local service_name=${relative_path#services/}
        dir="$trunc_prefix svc/$service_name"
      elif [[ $relative_path == infrastructure/accounts/* ]]; then
        local account_name=${relative_path#infrastructure/accounts/}
        dir="$trunc_prefix acct/$account_name"
      elif [[ $relative_path == infrastructure/modules/* ]]; then
        local module_name=${relative_path#infrastructure/modules/}
        dir="$trunc_prefix mod/$module_name"
      elif [[ $relative_path == packages/* ]]; then
        # For packages, keep the entire path starting from `packages/`
        local package_path=${relative_path#packages/}
        dir="$trunc_prefix pkg/$package_path"
      elif [[ $relative_path == scripts/* ]]; then
        dir="$trunc_prefix scripts/"
      else
        # Default behavior; see below for details on how this works
        dir="$trunc_prefix $git_root:t${${PWD:A}#$~~git_root}"
      fi
    else
      # `${NAME#PATTERN}` removes a leading prefix PATTERN from NAME.
      # `$~~` avoids `GLOB_SUBST` so that `$git_root` won't actually be
      # considered a pattern and matched literally, even if someone turns that on.
      # `$git_root` has symlinks resolved, so we use `${PWD:A}` which resolves
      # symlinks in the working directory.
      # See "Parameter Expansion" under the Zsh manual.
      dir="$trunc_prefix $git_root:t${${PWD:A}#$~~git_root}"
    fi
  else
    if [[ SPACESHIP_DIR_TRUNC -gt 0 ]]; then
      # `%(N~|TRUE-TEXT|FALSE-TEXT)` replaces `TRUE-TEXT` if the current path,
      # with prefix replacement, has at least N elements relative to the root
      # directory else `FALSE-TEXT`.
      # See "Prompt Expansion" under the Zsh manual.
      trunc_prefix="%($((SPACESHIP_DIR_TRUNC + 1))~|$SPACESHIP_DIR_TRUNC_PREFIX|)"
    fi

    dir="$trunc_prefix%${SPACESHIP_DIR_TRUNC}~"
  fi

  local suffix="$SPACESHIP_DIR_SUFFIX"

  if [[ ! -w . ]]; then
    suffix="%F{$SPACESHIP_DIR_LOCK_COLOR}${SPACESHIP_DIR_LOCK_SYMBOL}%f${SPACESHIP_DIR_SUFFIX}"
  fi

  spaceship::section \
    --color "$SPACESHIP_DIR_COLOR" \
    --prefix "$SPACESHIP_DIR_PREFIX" \
    --suffix "$suffix" \
    "$dir"
}
