# Bases on # agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# Customize by JorgeAnayaDev
# * Customize user name
# * Add ramdon emoji 
# * Add time and status to commands
# * Two line prompt
# * Custom function to change persona

# # README
#
# In order for this theme to render correctly, you will need a
# Nerd Font [Nerd font](https://www.nerdfonts.com/).
#
# This customization is intened to work on normal Mac Os Terminal (Catalina)
# with Solarized-dark

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
CURRENT_FG='white'
ONE_BG='blue'
EMOJIS=(earth_globe_americas volcano rainbow cyclone full_moon_symbol unicorn_face robot_face extraterrestrial_alien)    

#case ${SOLARIZED_THEME:-dark} in
#    light) CURRENT_FG='white';;
#    *)     CURRENT_FG='black';;
#esac

# Special Powerline characters
() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  
  # GRADIENT_SEPARATOR= "\u2593\u2592\u2591"  
  END_SEPARATOR="%F{$ONE_BG}\ue0b0"
  SEGMENT_SEPARATOR="%F{black}\ue0bb"
  RSEGMENT_SEPARATOR="\ue0b2"

  BOX_DL="\u256d"
  BOX_UL="\u2570\u21e2"

  CURRENT_EMOJI=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment_color() {
  # One Color Background
  local bg fg
  [[ -n $1 ]] && bg="%K{$ONE_BG}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"

  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

prompt_segment() {
  local bg fg
  bg="%K{$ONE_BG}"
  fg="%F{$CURRENT_FG}"
  echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "    
  [[ -n $1 ]] && echo -n $1
}

# End the prompt, closing any open segments
prompt_end() {  
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$END_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi  
  echo -n "%{%f%}"
  CURRENT_BG=''  
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown
# 
# Context: user@hostname (who am I and where am I)
# Change Machine Name: %m 
#prompt_context() {  
#  # Moved to random emoji
#  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
#    prompt_segment black blue "%(!.%{%F{yellow}%}.)@%n"
#  fi  
#}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    #PL_BRANCH_CHAR=$'\ue0a0'         # 
    PL_BRANCH_CHAR=$'\ufbd9'         # 
  }
  local ref dirty mode repo_path

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    repo_path=$(git rev-parse --git-dir 2>/dev/null)
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    #if [[ -n $dirty ]]; then
    #  prompt_segment yellow yellow
    #else
    #  prompt_segment green green  # $CURRENT_FG
    #fi
    prompt_segment ""

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
  fi
}

prompt_bzr() {
    (( $+commands[bzr] )) || return
    if (bzr status >/dev/null 2>&1); then
        status_mod=`bzr status | head -n1 | grep "modified" | wc -m`
        status_all=`bzr status | head -n1 | wc -m`
        revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'`
        if [[ $status_mod -gt 0 ]] ; then
            prompt_segment "" #yellow black
            echo -n "bzr@"$revision "✚ "
        else
            if [[ $status_all -gt 0 ]] ; then
                prompt_segment "" #yellow black
                echo -n "bzr@"$revision
            else
                prompt_segment "" #green black
                echo -n "bzr@"$revision
            fi
        fi
    fi
}

prompt_hg() {
  (( $+commands[hg] )) || return
  local rev st branch
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green $CURRENT_FG
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green $CURRENT_FG
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {    
  prompt_segment '\uf07c %~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local -a symbols b f

  if [[ $RETVAL -ne 0 ]]; then
    b='red'
    f='white'
    symbols+="\uf071" 
  else 
    b='green'
    f='black'
    symbols+="\uf00c"
  fi
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && echo -n "%K{$b}%F{$f}" "$symbols %@ %K{$ONE_BG}%F{$b}\ue0b0"
}

#AWS Profile:
# - display current AWS_PROFILE name
# - displays yellow on red if profile name contains 'production' or
#   ends in '-prod'
# - displays black on green otherwise
prompt_aws() {
  [[ -z "$AWS_PROFILE" ]] && return
  case "$AWS_PROFILE" in
    *-prod|*production*) prompt_segment red yellow  "AWS: $AWS_PROFILE" ;;
    *) prompt_segment green black "AWS: $AWS_PROFILE" ;;
  esac
}

# ==============================
# >> C U S T O M I Z A T I O N
# ==============================

function persona() {
    echo -n "Cambiando de personalidad ... "             
    ONE_BG=$1
    if [[ $1 = "red" || $1 = "magenta" || $1 = "black" ]]; then
      CURRENT_FG='white'    
    else
      CURRENT_FG='black'      
    fi
    prompt_emoji $2
    END_SEPARATOR="%F{$ONE_BG}\ue0b0"
    clear
}

prompt_emoji() {  
  if [[ $UID -eq 0 ]]; then
    echo -n "\uff62%F{yellow}⚡$USER\uff63"    
  else 
    if [[ -z "$1" ]]; then
      CURRENT_EMOJI=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}
    else
      CURRENT_EMOJI=$1
      case $1 in 
        "globe") CURRENT_EMOJI='earth_globe_americas';;
        "moon") CURRENT_EMOJI='full_moon_symbol';;
        "alien") CURRENT_EMOJI='extraterrestrial_alien';;
        "robot") CURRENT_EMOJI='robot_face';;             
        "unicorn") CURRENT_EMOJI='unicorn_face';;        
        "python") CURRENT_EMOJI='snake';;             
        "docker") CURRENT_EMOJI='spouting_whale';;
        "fire") CURRENT_EMOJI='fire';;
        "star") CURRENT_EMOJI='white_medium_star';;        
      esac      
    fi    
    echo -n "\uff62$emoji[$CURRENT_EMOJI] @$USER\uff63"            
  fi  
}

prompt_randomemoji() {
  EMOJIS=(earth_globe_americas volcano rainbow cyclone full_moon_symbol unicorn_face robot_face extraterrestrial_alien)
  WHERE=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}
  if [[ $UID -eq 0 ]]; then
    echo -n "\uff62%F{yellow}⚡$USER\uff63"    
  else 
    echo -n "\uff62r$emoji[$WHERE] @$USER\uff63"
  fi       
}

prompt_os() {
  echo -n "%F{$CURRENT_FG} \ue711"
}

prompt_newline () {  
  printf "\n"  
  echo -n "$BOX_UL"  
  CURRENT_BG=''       
}

## Main prompt
build_prompt() {
  RETVAL=$?
  echo -n "$BOX_DL"
  prompt_emoji $CURRENT_EMOJI 
  prompt_status
  prompt_os
  prompt_virtualenv
  prompt_aws
  prompt_dir
  prompt_git
  prompt_bzr
  prompt_hg   
  prompt_end     
  prompt_newline  
}

PROMPT='%{%f%b%k%}$(build_prompt)'  

#prompt_agnoster_precmd() {  
#  PROMPT='%{%f%b%k%}$(build_prompt)'  
#}
#prompt_agnoster_precmd