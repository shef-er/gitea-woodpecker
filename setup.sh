#!/bin/env bash


setup_nginx() {
  echo -n "Enter EMAIL value: "; read -r EMAIL
  echo -n "Enter DOMAIN_GITEA value: "; read -r DOMAIN_GITEA
  echo -n "Enter DOMAIN_WOODPECKER value: "; read -r DOMAIN_WOODPECKER

  cat .env \
    | sed -e "s#EMAIL=#EMAIL=$EMAIL#g" \
    | sed -e "s#DOMAIN_GITEA=#DOMAIN_GITEA=$DOMAIN_GITEA#g" \
    | sed -e "s#DOMAIN_WOODPECKER=#DOMAIN_WOODPECKER=$DOMAIN_WOODPECKER#g" \
    > .env.tmp
  mv .env.tmp .env

  cp etc/nginx/templates_dist/fallback.conf.template etc/nginx/templates/

  docker-compose -f docker-compose.fallback.yml -f docker-compose.certbot.yml up --detach
  docker-compose -f docker-compose.fallback.yml -f docker-compose.certbot.yml run --rm --entrypoint "\
    certbot certonly --agree-tos \
      --webroot --webroot-path /var/www/acme-challenge \
      --rsa-key-size 4096 \
      --email $EMAIL \
      -d $DOMAIN_GITEA \
      -d $DOMAIN_WOODPECKER \
    " certbot
  docker-compose -f docker-compose.fallback.yml -f docker-compose.certbot.yml down

  openssl dhparam -out etc/nginx/dhparam.pem 2048
}


setup_git_user() {
  adduser --system \
    --shell /bin/bash \
    --gecos 'Git Version Control' \
    --group \
    --disabled-password \
    --home /home/git \
    git
  usermod -aG docker git

  # Docker shell with authorized_keys:
  # https://docs.gitea.io/en-us/install-with-docker/#docker-shell-with-authorized_keys
  cp ../dist/docker-shell /home/git/docker-shell
  chmod +x /home/git/docker-shell
  usermod -s /home/git/docker-shell git
}


setup_gitea() {
  cat .env \
    | sed -e "s#GIT_USER_UID=#GIT_USER_UID=$(id -u git)#g" \
    | sed -e "s#GIT_USER_GID=#GIT_USER_GID=$(id -g git)#g" \
    > .env.tmp
  mv .env.tmp .env

  cp etc/nginx/templates_dist/gitea.conf.template etc/nginx/templates/
  docker-compose up -d

  echo "Setup gitea admin user and get OAuth credentials for Woodpecker CI"
}


setup_woodpecker() {
  WOODPECKER_AGENT_SECRET="$(openssl rand -hex 32)"
  echo -n "Enter WOODPECKER_GITEA_CLIENT value"; read -r WOODPECKER_GITEA_CLIENT
  echo -n "Enter WOODPECKER_GITEA_SECRET value"; read -r WOODPECKER_GITEA_SECRET

  cat .env \
    | sed -e "s#WOODPECKER_AGENT_SECRET=#WOODPECKER_AGENT_SECRET=$WOODPECKER_AGENT_SECRET#g" \
    | sed -e "s#WOODPECKER_GITEA_CLIENT=#WOODPECKER_GITEA_CLIENT=$WOODPECKER_GITEA_CLIENT#g" \
    | sed -e "s#WOODPECKER_GITEA_SECRET=#WOODPECKER_GITEA_SECRET=$WOODPECKER_GITEA_SECRET#g" \
    > .env.tmp
  mv .env.tmp .env

  cp etc/nginx/templates_dist/woodpecker.conf.template etc/nginx/templates/
  docker-compose down
  docker-compose up -d
}


case ${1:-} in
  "nginx")
    setup_nginx
    ;;

  "git-user")
    setup_git_user
    ;;

  "gitea")
    setup_gitea
    ;;

  "woodpecker")
    setup_woodpecker
    ;;

  *)
    [ ! -f .env ] && cp .env.example .env
    setup_nginx
    setup_git_user
    setup_gitea
    setup_woodpecker
    echo "All done!"
    ;;
esac
