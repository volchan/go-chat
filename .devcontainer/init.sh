#!/usr/bin/env bash

# Setup SSH key
if [[ ! -f .ssh-key-name ]]; then
  read -p "Enter your GitHub ssh key name (default: id_rsa): " ssh_key_name
  ssh_key_name=${ssh_key_name:-id_rsa}
  echo $ssh_key_name >.ssh-key-name
fi

ssh-add $HOME/.ssh/$(cat .ssh-key-name)

# JQ is required for parsing JSON in the terminal
if ! command -v jq &>/dev/null; then
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install jq
  else
    sudo apt-get update
    sudo apt-get install -y jq
  fi
fi

# Setup personal VSCode extensions
if [[ ! -f .personal-extensions.json ]]; then
  initial_array=$(jq -n '[]')

  default="y"
  read -e -p "Would you like to add personal extensions? (Y/n): " add
  add=${add:-$default}

  if [[ $add =~ ^[Yy]$ ]]; then
    json_content=$(cat ~/.vscode/extensions/extensions.json)

    echo "Choose the extensions you would like to add to the .personal-extensions.json file:"
    echo "y - yes"
    echo "n - no"
    echo "c - custom (add with specific version)"

    extensions=$(echo "$json_content" | jq -c '.[]')
    IFS=$'\n' read -rd '' -a extensions_array <<<"$extensions"

    for obj in "${extensions_array[@]}"; do
      name=$(echo "$obj" | jq -r '.identifier.id')
      version=$(echo "$obj" | jq -r '.version')

      default="y"
      read -e -p "Would you like to add $name? (Y/n/c): " reply
      reply=${reply:-$default}
      case $reply in
      [Yy]*)
        new_obj=$(jq -n --arg name "$name" '{name: $name}')
        ;;
      [Nn]*)
        echo "Skipping $name."
        continue
        ;;
      [Cc]*)
        default_version=$version
        read -e -p "Enter the version you would like to add (default: $version): " version_reply
        version=${version_reply:-$default_version}

        new_obj=$(jq -n --arg name "$name" --arg version "$version" '{name: $name, version: $version}')
        ;;
      *)
        echo "Invalid option. Skipping $name."
        continue
        ;;
      esac

      initial_array=$(echo "$initial_array" | jq --argjson new_obj "$new_obj" '. + [$new_obj]')
      echo "Added $name."
      echo "$initial_array" >.personal-extensions.json
      echo ".personal-extensions.json file generated."
    done
  else
    printf "No personal extensions will be added."
  fi
else
  echo ".personal-extensions.json file already exists."
  echo "To regenerate the file, delete it and rebuild the devcontainer."
fi
