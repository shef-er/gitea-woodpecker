#!/bin/env bash

bold() {
  echo "$(tput bold)${1:-}$(tput sgr0)"
}

save_env() {
  KEY="${1:-}"
  VALUE="${2:-}"

  sed -e "s#$KEY=#$KEY=$VALUE#g" < .env > .env.tmp && mv .env.tmp .env
}

read_env() {
  PROMPT="${1:-}"
  KEY="$2"

  if [ -z "$KEY" ]; then
    return 0
  fi

  read -r -p "$PROMPT" "${KEY?}"
  export "${KEY?}"

  VALUE="${!KEY}"
  save_env "$KEY" "$VALUE"
}

echo " ____  _____ _____ _   _ ____  "
echo "/ ___|| ____|_   _| | | |  _ \ "
echo "\___ \|  _|   | | | | | | |_) |"
echo " ___) | |___  | | | |_| |  __/ "
echo "|____/|_____| |_|  \___/|_|    "
echo

if [ -f .env ]; then
  read -r -p "Erase existing .env file? [Y/n]: " ERASE_ENV

  case "$ERASE_ENV" in
    "y" | "Y" | "yes" | "Yes")
      cp .env.example .env ;;
    *)
      echo "Skipping..." ;;
  esac
else
  cp .env.example .env
fi

echo
bold "SSL settings"
read_env "- Your email: " EMAIL
read_env "- Gitea instance domain: " DOMAIN_GITEA
read_env "- Woodpecker CI instance domain: " DOMAIN_WOODPECKER

echo
bold "Gitea setup"
if ! id -u git >/dev/null 2>&1; then
  echo "Setting up SSH access to Gitea instance inside Docker using:"
  echo "https://docs.gitea.io/en-us/install-with-docker/#docker-shell-with-authorized_keys"

  mkdir -p "/home/git"
  cat << "EOF" | tee "/home/git/shell"
#!/bin/sh
/usr/bin/docker exec -i -u git --env SSH_ORIGINAL_COMMAND="$SSH_ORIGINAL_COMMAND" gitea sh "$@"
EOF
  chmod +x "/home/git/shell"

  echo "Creating git user..."
  adduser --system --group --disabled-password --gecos 'Git VCS' --shell "/home/git/shell" --home "/home/git" git
  usermod -aG docker git
else
  echo "User 'git' already exists. Skipping..."
fi

save_env "GIT_USER_UID" "$(id -u git)"
save_env "GIT_USER_GID" "$(id -g git)"

echo
bold "Starting Docker containers..."
docker-compose up -d

echo
bold "Woodpecker CI setup"
echo "1. Open https://$DOMAIN_GITEA and setup your Gitea instance"
echo "2. Go to Settings -> Applications -> Manage OAuth2 Applications -> Create a new OAuth2 Application"
echo
echo "Application Name:    Woodpecker CI"
echo "Redirect URI:        https://$DOMAIN_WOODPECKER/authorize"

echo
echo "3. Enter the received secrets:"
read_env "- Client ID: " WOODPECKER_GITEA_CLIENT
read_env "- Client Secret: " WOODPECKER_GITEA_SECRET
save_env "WOODPECKER_AGENT_SECRET" "$(openssl rand -hex 32)"

echo
bold "Restarting Docker containers..."
docker-compose down
docker-compose up -d

echo
bold "All done!"
echo "- Gitea:         https://$DOMAIN_GITEA"
echo "- Woodpecker CI: https://$DOMAIN_WOODPECKER"
