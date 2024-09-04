FROM mcr.microsoft.com/devcontainers/base:latest

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.zsh_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.zsh_history \
  && chown -R vscode /commandhistory \
  && echo "$SNIPPET" >> "/home/vscode/.zshrc"
