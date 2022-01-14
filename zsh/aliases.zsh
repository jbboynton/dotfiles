alias aliases="vim ~/.zsh/aliases.zsh"
alias app="open -a"
alias bbu="brew bundle"
alias be="bundle exec"
alias bi="bundle install"
alias bin="vim ~/.bin"
alias brewfile="vim ~/Brewfile"
alias c="composer"
alias cat="bat"
alias ci="composer install"
alias co="composer outdated"
alias code="cd ~/Code"
alias deps="git log --oneline --remotes | grep Bump | less"
alias dotfiles="cd ~/.dotfiles"
alias gitconfig="vim ~/.gitconfig"
alias hide_files="defaults write com.apple.finder AppleShowAllFiles NO && killall Finder"
alias hrc="heroku run rails console"
alias hrl="heroku logs --num 99999999 | less"
alias htop="sudo htop"
alias http="http --pretty=all --verbose"
alias install_tools="xcode-select --install"
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias less="bat"
alias ll="exa -abghlm --sort name --group-directories-first --git"
alias llt="exa --long -L 2 -T"
alias mailconfig="vim ~/Library/Application\\ Support/MailMate/Resources/KeyBindings/Custom.plist"
alias notes="cd ~/Notes"
alias pgstart="pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start"
alias pgstop="pg_ctl -D /usr/local/var/postgres stop -s -m fast"
alias plint="find . -iname \"*.php\" -exec php -l '{}' \; | grep -v 'Syntax OK'"
alias rc="bundle exec rubocop --color --config .rubocop.yml --extra-details --force-exclusion --format simple"
alias rcs="bundle exec rubocop --color --config .rubocop.yml --extra-details --force-exclusion --format simple && bundle exec rspec"
alias remigrate="bin/rails db:drop && bin/rails db:create && bin/rails db:migrate && bin/rails db:seed"
alias rmcache="rm -fr .cache-loader && yarn rmdist && rm -fr resources/views/cache/* && yarn build"
alias rmds="fd --hidden --no-ignore '^\.DS_Store$' --type f --exec-batch rm"
alias rmswp="fd --hidden --no-ignore --full-path '/var/tmp/.*\.sw.*' --type f --exec-batch rm"
alias rs="bundle exec rspec"
alias rsf="bundle exec rspec --only-failures"
alias rtm="bin/rails db:migrate RAILS_ENV=test"
alias scratch="vim /var/tmp/scratch.md"
alias sd="shutdown now"
alias show_files="defaults write com.apple.finder AppleShowAllFiles YES && killall Finder"
alias sourcez="source ~/.zshrc"
alias sshconfig="vim ~/.ssh/config"
alias tmuxconfig="vim ~/.tmux.conf"
alias tree="tree -aC"
alias vgs="vagrant global-status --prune"
alias vht="vsshc make https_log"
alias vimconfig="vim ~/.vimrc"
alias vimprojects="vim ~/.vim/rcfiles/projects"
alias vup="vagrant up --provision"
alias wget="wget --no-hsts"
alias wip="git add -A && git commit -m \"WIP\" -m \"[skip ci]\""
alias zshconfig="vim ~/.zshrc"
alias zshhist="vim ~/.zsh_history"
