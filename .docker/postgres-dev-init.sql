CREATE USER vscode;

ALTER USER vscode SUPERUSER;

CREATE DATABASE "go-chat_development";

GRANT ALL PRIVILEGES ON DATABASE "go-chat_development" TO vscode;
