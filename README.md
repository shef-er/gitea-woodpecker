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
make gen-certificates
```

### 5. Up your app

```shell
make up
```
