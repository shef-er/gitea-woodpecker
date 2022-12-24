# Gitea: Git with a cup of tea

## Installation

### 1. Create host machine git user to use ssh connections

```shell
adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git git
usermod -aG docker git
```

### 2. Docker ssh shell setup

Link to gitea docs: [Docker shell with authorized_keys](https://docs.gitea.io/en-us/install-with-docker/#docker-shell-with-authorized_keys)

```shell
cp scripts/docker-shell /home/git/docker-shell
chmod +x /home/git/docker-shell
usermod -s /home/git/docker-shell git
```

### 3. Copy `.env` file from `.env.example` provided in repo

```shell
cp .env.example .env
```

And fill required parameters:
- `USER_UID`
- `USER_GID`
- `DOMAIN`
- `EMAIL`

### 4.Generate ssl certificates for your domain

```shell
make cert
```

### 5. Up your app

```shell
make up
```


# Steps overview

1. Setup host git user
    1. Create host machine git user to use ssh connections
    2. Docker ssh shell setup

2. Setup nginx with SSL  
    1. `cp .env.example .env`
    2. Add your git user uid and gid, email and domain names to .env
    3. `cp /etc/nginx/templates_dist/fallback.conf.template /etc/nginx/templates/`
    4. Set up `docker-compose.fallback.yml` and `docker-compose.certbot.yml`  
    5. Generate certs with certbot  
    6. Bring down all containers  

3. Set up Gitea
    1. `cp /etc/nginx/templates_dist/gitea.conf.template /etc/nginx/templates/`
    2. Run `docker-compose.yml`  
    3. Setup gitea admin user and get OAuth credentials for Woodpecker

4. Set up Woodpecker
    1. Add Gitea credentials to Woodpecker env vars and get AGENT_SECRET from `openssl rand -hex 32`
    2. `cp /etc/nginx/templates_dist/woodpecker.conf.template /etc/nginx/templates/`
    3. Restart `docker-compose.yml`
