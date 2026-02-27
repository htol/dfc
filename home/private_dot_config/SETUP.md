# TODO:
Move all this staff to bootstrap  

# Hello
Short notes for enviroment setup.

some X related staff
```
sudo apt-get -y install rofi nitrogen flameshot kbdd
# TODO: manual build for
# polybar picom alacritty ghostty
```

# For nvim lsp (optional, depricated)
Ussualy lsp servers will be installed via Masson
All supported lsps
```
go install golang.org/x/tools/gopls@latest  # also for  gopls update
npm install -g pyright yaml-language-server vscode-langservers-extracted
npm install -g @vue/language-server typescript typescript-language-server
```

# golang
```
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt install golang-1.19
```

# rust
```
curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path
```

# java. jdtls
```
mkdir -p ~/.local/jdt-ls
cd ~/.local/jdt-ls
curl -LO https://download.eclipse.org/jdtls/milestones/1.9.0/jdt-language-server-1.9.0-202203031534.tar.gz
```

# sdkman && gradle
```
sudo apt-install -y zip
curl -s "https://get.sdkman.io" | bash
sdk install gradle
```

# Next packages are required to build python from source on Ubuntu (optional)
```
sudo apt update && sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
```

# ansible
```
git clone https://github.com/ansible/ansible.git ~/.local/ansible
pip install -r ~/.local/ansible/requirements.txt
```

# macosx soft
```
brew install fish nushell fzf rg fd ghostty visual-studio-code iterm2 vlc sublime-text nvim emacs \
colima docker golang p7zip htop btop jq bat rectangle netcat tmux nushell scroll-reverser
```

# macosx system settings
Check bootstrap! There is already a banch of setting to configure macosx. Here is only often used.

Don't create "DS_Store" on remote shares:
```
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
defaults read com.apple.desktopservices # check current policy
```
