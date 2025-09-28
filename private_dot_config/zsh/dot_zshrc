# Path to your oh-my-zsh installation.
#export ZSH="$HOME/.local/oh-my-zsh"

#ZSH_THEME="gentoo"

#plugins=(
#  git colorize pip python tmux python
#)
#
#source $ZSH/oh-my-zsh.sh

ZSH_COLORIZE_STYLE="colorful"


autoload colors
colors

setopt prompt_subst

###
# zsh gentoo theme
#
function prompt_char {
	if [ $UID -eq 0 ]; then echo "#"; else echo $; fi
}

PROMPT='%(!.%{$fg_bold[red]%}.%{$fg_bold[green]%}%n@)%m %{$fg_bold[blue]%}%(!.%1~.%~) $(prompt_char)%{$reset_color%} '


export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

HISTFILE=~/.config/zsh/history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt appendhistory

load-ansible(){
	# TODO: ansible path as env variable?
	if [ -f ${HOME}/.local/ansible/hacking/env-setup ]; then
		source ~/.local/ansible/hacking/env-setup
		echo "Ansible environment loaded"
	fi
}

[ -s "$FNM_DIR/fnm" ] && eval "$(fnm env --shell=zsh)"

if [ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]; then
     export PATH=$PATH:"/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

cd

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.local/sdkman"
[[ -s "$HOME/.local/sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.local/sdkman/bin/sdkman-init.sh"
