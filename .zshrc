autoload -U compinit && compinit
autoload -U colors && colors

git_user() {
  echo "$(git -C "$1" config user.name)"
}

git_root() {
  local folder='.'
  for i in $(seq 0 $(pwd|tr -cd '/'|wc -c)); do
    [ -d "$folder/.git" ] && echo "$folder" && return
    folder="../$folder"
  done
}

git_branch() {
  local git_root="$1"
  local line="$2"
  local branch="???"
  local ahead=''
  local behind=''

  case "$line" in
    \#\#\ HEAD*)
      branch="$(git -C "$git_root" tag --points-at HEAD)"
      [ -z "$branch" ] && branch="$(git -C "$git_root" rev-parse --short HEAD)"
      branch="%F{yellow}$branch%F{reset}"
      ;;
    *)
      branch="${line#\#\# }"
      branch="%F{green}${branch%%...*}%F{reset}"
      ahead="$(echo $line | sed -En -e 's|^.*(\[ahead ([[:digit:]]+)).*\]$|\2|p')"
      behind="$(echo $line | sed -En -e 's|^.*(\[.*behind ([[:digit:]]+)).*\]$|\2|p')"
      [ -n "$ahead" ] && ahead="%F{white}↑%F{reset}$ahead"
      [ -n "$behind" ] && behind="%F{white}↓%F{reset}$behind"
      ;;
  esac

  print "${branch}${ahead}${behind}"
}

git_status() {
  local untracked=0
  local modified=0
  # local deleted=0
  local staged=0
  local branch=''
  local output=''

  for line in "${(@f)$(git status --porcelain -b 2>/dev/null)}";
  do
    case $line in
      \#\#*) branch="$(git_branch "$1" "$line")" ;;
      \?\?*) ((untracked++)) ;;
      U?*|?U*|DD*|AA*|\ M*|\ D*) ((modified++)) ;;
      ?M*|?D*) ((modified++)) ;; ((staged++)) ;;
      ??*) ((staged++)) ;;
    esac
  done
  output="$branch"

  [ $staged -gt 0 ] && output+=" %F{green}S$staged%F{reset}"
  [ $modified -gt 0 ] && output+=" %F{red}M$modified%F{reset}"
  # [ $deleted -gt 0 ] && output+=" %F{red}D$deleted%F{reset}"
  [ $untracked -gt 0 ] && output+=" %F{yellow}?$untracked%F{reset}"

  echo $output
}

git_prompt_info() {
  local GIT_ROOT="$(git_root)"
  [ -z "$GIT_ROOT" ] && return

  print " $(git_user "$GIT_ROOT")%F{240}@%F{reset}$(git_status "$GIT_ROOT") "
}

PROMPT=''
PROMPT+='%F{green}%n@%m:%F{cyan}%~%F{reset}'
PROMPT+='%F{green}$(git_prompt_info)%F{reset}'
PROMPT+="λ "

HISTFILE=~/.zsh_history
HISTSIZE=200
SAVEHIST=200
setopt appendhistory
setopt histignorealldups
setopt prompt_subst

source ./.common-aliases
source ./.git-aliases
source ./.docker-aliases
