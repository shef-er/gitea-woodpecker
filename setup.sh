#!/bin/env bash

print_header() {
  echo
  echo " ${1:-}"
}

print_text_n() {
  echo -n "   ${1:-}"
}

print_text() {
  print_text_n "${1:-}"
  echo
}

[ ! -f .env ] && cp .env.example .env

print_header "SSL certs settings"
print_text_n "Your email: "; read -r EMAIL
print_text_n "Forgejo instance domain name: "; read -r DOMAIN_FORGEJO
print_text_n "Woodpecker CI instance domain name: "; read -r DOMAIN_WOODPECKER

cat .env \
  | sed -e "s#EMAIL=#EMAIL=$EMAIL#g" \
  | sed -e "s#DOMAIN_FORGEJO=#DOMAIN_FORGEJO=$DOMAIN_FORGEJO#g" \
  | sed -e "s#DOMAIN_WOODPECKER=#DOMAIN_WOODPECKER=$DOMAIN_WOODPECKER#g" \
  > .env.tmp
mv .env.tmp .env

print_header "Git user setup"
if ! id -u "git" >/dev/null 2>&1; then
  print_text "Creating 'git' user"
  adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git
  usermod -aG docker git

  print_text "Setting up SSH access to Forgejo instance inside Docker using:"
  print_text "https://docs.gitea.io/en-us/install-with-docker/#docker-shell-with-authorized_keys"
  cp ../dist/docker-shell /home/git/docker-shell
  chmod +x /home/git/docker-shell
  usermod -s /home/git/docker-shell git
else
  print_text "User 'git' already exist. Skipping..."
fi

cat .env \
  | sed -e "s#GIT_USER_UID=#GIT_USER_UID=$(id -u git)#g" \
  | sed -e "s#GIT_USER_GID=#GIT_USER_GID=$(id -g git)#g" \
  > .env.tmp
mv .env.tmp .env


print_header "Starting Docker containers"
docker-compose up -d

print_header "Woodpecker CI setup"
print_text "1. Open https://$DOMAIN_FORGEJO and setup your Forgejo instance"
print_text "2. Go to Settings -> Applications -> Manage OAuth2 Applications -> Create a new OAuth2 Application"
print_text
print_text "Application Name:    Woodpecker CI"
print_text "Redirect URI:        https://$DOMAIN_WOODPECKER/authorize"
print_text
print_text "3. Enter the received secrets:"
print_text_n "Client ID: "; read -r WOODPECKER_GITEA_CLIENT
print_text_n "Client Secret: "; read -r WOODPECKER_GITEA_SECRET

cat .env \
  | sed -e "s#WOODPECKER_AGENT_SECRET=#WOODPECKER_AGENT_SECRET=$(openssl rand -hex 32)#g" \
  | sed -e "s#WOODPECKER_GITEA_CLIENT=#WOODPECKER_GITEA_CLIENT=$WOODPECKER_GITEA_CLIENT#g" \
  | sed -e "s#WOODPECKER_GITEA_SECRET=#WOODPECKER_GITEA_SECRET=$WOODPECKER_GITEA_SECRET#g" \
  > .env.tmp
mv .env.tmp .env

print_header "Restarting Docker containers"
docker-compose up -d

print_header "All done!"
print_text "Forgejo: https://$DOMAIN_FORGEJO"
print_text "Woodpecker CI: https://$DOMAIN_WOODPECKER"
