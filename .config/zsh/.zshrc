# Load command completion plugin
autoload -Uz compinit
zmodload zsh/complist
compinit
_comp_options+=(globdots) # Process hidden files as well

# Load colors names for a more readable PROMPT variable
autoload -U colors && colors

# VCS plugin that enables branch name extracting from git repositories
autoload -Uz vcs_info

# History plugin that sets the cursor to the end of the command when navigating
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

# ZSH history settings
HISTFILE=~/.cache/zsh_history
HISTSIZE=10000000
SAVEHIST=10000000

# Share history between sessions
setopt inc_append_history

# Autotab complete configuration
zstyle ':completion:*' menu select

# Group completions by type (files, builtins, commands, etc.)
zstyle ':completion:*' group-name ''

# Sort files completion entries by last modified
zstyle ':completion:*' file-sort modification

# Case insensitive path completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Default completion colors uses ls ones
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"

# General purpose completion colors
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}# %d%f'
zstyle ':completion:*:parameters' list-colors '=*=32'
zstyle ':completion:*:options' list-colors '=^(-- *)=32'

# Kill completion
zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'

# Man completion
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# Custom vcs_info formatting (branch name only)
zstyle ':vcs_info:git:*' formats " %{[33m%}[%b]%{[0m%}"

# Function that runs before each command
precmd() {
    local max_path_entries
    vcs_info

    # If we're in a git repository, we shorten the path
    if [[ -n ${vcs_info_msg_0_} ]]; then
        max_path_entries=3
    fi

    PROMPT="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%${max_path_entries}~%{$fg[red]%}]%b${vcs_info_msg_0_} $ "
}

# Function that wraps the git command in order to use nvim when possible
git() {
    if [[ "$1" = "show" ]] || [[ "$1" = "log" ]] || [[ "$1" = "diff" ]]
    then
        if command git "$@" > /tmp/git.$$
        then
            nvim /tmp/git.$$
        fi

        rm /tmp/git.$$
    else
        command git "$@"
    fi
}

rootme() {
    if [ "$#" -eq 2 ]
    then
        sshpass -p"$(echo "$2" | cut -d@ -f1)" ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p "$1" "$2"
    elif [ "$#" -eq 3 ]
    then
        sshpass -p"$(echo "$2" | cut -d@ -f1)" scp -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -P "$1" "$2":"$3" .
    else
        echo "Usage: rootme [PORT] [USER@HOST] (FILE)"
    fi

}

# Tell the line editor to turn on "application" mode when it starts and turn it off when it stops.
# This should make the use of khome, kend, kcuu1 and kcud1 portable across terminal emulators.
# See https://zsh.sourceforge.io/FAQ/zshfaq03.html#l26
if [[ -v terminfo[smkx] ]]
then
    function zle-line-init () { echoti smkx }
    function zle-line-finish () { echoti rmkx }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

# Key bindings (man terminfo)
bindkey "${terminfo[kdch1]}" delete-char
bindkey "${terminfo[khome]}" beginning-of-line
bindkey "${terminfo[kend]}"  end-of-line
bindkey "${terminfo[kcuu1]}" history-beginning-search-backward-end
bindkey "${terminfo[kcud1]}" history-beginning-search-forward-end
bindkey "^[[1;5D"            backward-word
bindkey "^[[1;5C"            forward-word
bindkey "^[[D"               backward-word
bindkey "^[[C"               forward-word

# Key bindings (tab completion)
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Key bindings (external tools)
bindkey -s '^f' 'cd "$(dirname "$(fzf)")"\n'

# Aliases
alias sudo='sudo ' # so that other aliases expand when using sudo
alias proxify='proxify ' # so that other aliases expand when using proxify
alias cp="cp -i"
alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias ll='ls -l'
alias l='ls -lA'
alias ipa='ip -c -br a'
alias vim='nvim'
alias gs='git status'
alias xo='xdg-open'
alias pandoc='sudo docker run --rm -v "$(pwd):/data" -u $(id -u):$(id -g) pandoc/latex'
alias python3='ipython3'
alias python='ipython'
alias su='su --pty' # https://www.errno.fr/TTYPushback.html
alias cat='bat --style=plain --paging=never'

# Shell specific environment variables (global ones should be in ~/.profile)
export GPG_TTY="$(tty)"

# Checking requirements to make sure this zshrc is usable
requirements=(nvim fzf most docker)

for requirement in "${requirements[@]}"
do
    if ! loc="$(type -p "$requirement")" || [[ -z "$loc" ]]
    then
        echo "You must install '$requirement' for this .zshrc to work properly !"
    fi
done

# Clean temp variables
unset requirements
unset requirement
unset loc
