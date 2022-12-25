# Gitea: Git with a cup of tea

## Installation

### Set up nginx with ssl

Run `cp .env.example .env` and fill `EMAIL`, `DOMAIN_GITEA`, `DOMAIN_WOODPECKER` vars in `.env`

```shell
cp ./etc/nginx/templates_dist/fallback.conf.template ./etc/nginx/templates/

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

openssl dhparam -out ./etc/nginx/dhparam.pem 2048
```

### Set up git user

Create host machine git user to use ssh connections

```shell
adduser --system \
  --shell /bin/bash \
  --gecos 'Git Version Control' \
  --group \
  --disabled-password \
  --home /home/git \
  git
usermod -aG docker git
```

Set up docker proxy ssh shell

```shell
cp ../dist/docker-shell /home/git/docker-shell
chmod +x /home/git/docker-shell
usermod -s /home/git/docker-shell git
```

More at Gitea docs: [Docker shell with authorized_keys](https://docs.gitea.io/en-us/install-with-docker/#docker-shell-with-authorized_keys)

### Set up Gitea

 1. Fill `GIT_USER_UID`, `GIT_USER_GID` vars in .env
 2. `cp ./etc/nginx/templates_dist/gitea.conf.template ./etc/nginx/templates/`
 3. `make up` / `docker-compose up -d`  
 4. Setup gitea admin user and get OAuth credentials for Woodpecker

### Set up Woodpecker

 1. Fill `WOODPECKER_AGENT_SECRET` in .env with output from `openssl rand -hex 32`
 2. Fill `WOODPECKER_GITEA_CLIENT`, `WOODPECKER_GITEA_SECRET` vars in .env
 3. `cp ./etc/nginx/templates_dist/woodpecker.conf.template ./etc/nginx/templates/`
 4. `make restart` / `docker-compose restart`
