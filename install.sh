sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
apt-get install -y vim
cp .zshrc ~/.zshrc
cat > ~/.bash_profile <<'EOF'
[ -f ~/.profile ] && . ~/.profile
# Interactive sessions only, so scripts that run `bash -lc ...` are unaffected
if [[ $- == *i* ]] && [ -z "$ZSH_VERSION" ] && command -v zsh >/dev/null; then
  exec zsh -l
fi
EOF
