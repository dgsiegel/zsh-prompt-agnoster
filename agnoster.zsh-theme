# vim:ft=zsh ts=2 sw=2 sts=2
#
# based on agnoster's theme - https://gist.github.com/3712874

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
SSH_BG=green
PRIMARY_FG=black

# Characters
SEGMENT_SEPARATOR="\ue0b0"  # 
PLUSMINUS="\u00b1"          # ±
BRANCH="\ue0a0"             # 
DETACHED="\u27a6"           # ➦
#CROSS="\u2718"              # ✘
CROSS="\u274C"              # ❌
LIGHTNING="\u26a1"          # ⚡
GEAR="\u2699"               # ⚙
ARROW="\u2197"              # ↗
STAR="\u2217"               # ∗

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment $SSH_BG $PRIMARY_FG "%(!.%{%F{yellow}%}.)$user@%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref dirty
  if $(git rev-parse --is-inside-work-tree 2> /dev/null); then
    if [[ -n $(git status -s --ignore-submodules=dirty 2> /dev/null) ]]; then
      color=yellow
    else
      color=green
    fi

    git diff --no-ext-diff --ignore-submodules --quiet --exit-code || dirty="$STAR"

    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="$DETACHED $(git show-ref --head -s --abbrev | head -n1 2> /dev/null)"

    if git rev-parse --quiet --verify HEAD >/dev/null; then
      git diff-index --cached --quiet --ignore-submodules HEAD -- || index="$PLUSMINUS"
    else
      index="#"
    fi

    if $(git status -b --porcelain | grep '\[ahead' &> /dev/null); then
      push="$ARROW"
    fi

    prompt_segment $color $PRIMARY_FG
    echo -n "${ref/refs\/heads\//}${dirty}${index}${push}"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $PRIMARY_FG '%~'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment $PRIMARY_FG default "$symbols"
}

prompt_vi_mode() {
  [[ "$KEYMAP" == "vicmd" ]] && prompt_segment cyan $PRIMARY_FG "$CROSS"
}

prompt_agnoster_setup () {
  build_prompt() {
    prompt_vi_mode
    prompt_status
    prompt_context
    prompt_dir
    prompt_git
    prompt_end
  }

  function zle-keymap-select zle-line-init zle-line-finish {
    zle reset-prompt
    zle -R
  }

  zle -N zle-line-init
  zle -N zle-line-finish
  zle -N zle-keymap-select

  PROMPT='%{%f%b%k%}$(build_prompt) '
}

prompt_agnoster_setup "$@"
