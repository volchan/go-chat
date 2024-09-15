#!/usr/bin/env bash

# Setup Air, GO hot reload
go install github.com/air-verse/air@latest

# Setup SSH config
echo "Setting up SSH config..."
default_ssh_config_filename=".devcontainer/ssh-config"
rsa_key_name=$(cat .ssh-key-name)
ssh_config_filename=$HOME/.ssh/config
cat $default_ssh_config_filename >$ssh_config_filename
sed -i.bak "s|IdentityFile ~/.ssh/rsa-key-name|IdentityFile ~/.ssh/$rsa_key_name|" "$HOME/.ssh/config"

# Check permissions of ~/.ssh/config
if [[ $(stat -c %a ~/.ssh/config) != "600" ]]; then
  chmod 600 ~/.ssh/config
fi

# Setup Github CLI
default="y"
read -e -p "Do you want to setup Github CLI? [Y/n] " setup_gh
setup_gh=${setup_gh:-$default}
if [[ $setup_gh =~ ^[Yy]$ ]]; then
  gh auth login
fi

# Install personal aliases
if [[ ! -f .personal-aliases ]]; then
  touch .personal-aliases
  echo "Add your personal aliases to the .personal-aliases file or leave it empty to ignore this."
  read -p "Press [Enter] key to continue..."
fi

echo "source $PWD/.personal-aliases" >>$HOME/.zshrc

# Setup ZSH plugins
echo "Setting up ZSH plugins..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
sed -i 's/plugins=(git)/plugins=(git gitfast common-aliases zsh-syntax-highlighting zsh-history-substring-search)/' "$HOME/.zshrc"

# Setup ZSH prefill
echo "Setting up ZSH prefill for dev terminal..."
echo "if [[ -n \$DEV_TERMINAL ]]; then print -z task dev; fi" >>$HOME/.zshrc

# Install personal extensions
if [[ -f .personal-extensions.json ]]; then
  # workaround because the code command is not available in the PATH https://github.com/microsoft/vscode-remote-release/issues/8535
  export code="$(ls ~/.vscode-server*/bin/*/bin/code-server* | head -n 1)"

  echo "Installing personal extensions..."
  json_content=$(cat .personal-extensions.json)

  # Iterate over each object in the JSON array
  echo "$json_content" | jq -c '.[]' | while read -r obj; do
    name=$(echo "$obj" | jq -r '.name')
    version=$(echo "$obj" | jq -r '.version // empty')

    if [[ -n "$version" ]]; then
      $code --install-extension $name@$version
    else
      $code --install-extension $name
    fi
  done

  unset json_content
  unset code
else
  echo "No .personal-extensions.json file found."
  exit 0
fi
