Docker image for self-hosted Github actions runner.

### Usage

#### Simplest example

```sh
docker run -d \
    -e RUNNER_CONFIG_ARGS='--url https://github.com/foo/bar --token FOOBAR' \
    01e9/github-actions-runner
```

#### Advanced `docker-compose.yaml`

```yaml
version: '3.5'

x-common:
  &common
  image: 01e9/github-actions-runner
  restart: unless-stopped

x-volumes:
  - &volume-ssh-key
    ~/.ssh/id_rsa:/home/github/.ssh/id_rsa:ro

x-docker-in-docker:
  - &volume-docker-sock
    /var/run/docker.sock:/var/run/docker.sock
  - &volume-docker-config
    ~/.docker/config.json:/root/.docker/config.json:ro

x-max-cpus: &max-cpus '3'

x-env:
  &env
  MAX_CPUS: *max-cpus

x-resource-limits:
  &resource-limits
  cpus: *max-cpus
  mem_limit: '3g'

volumes:
  project_1:
  project_2:

  mysql:

services:
  project_1:
    << : *common
    << : *resource-limits
    container_name: runner_project_1
    environment:
      << : *env
      RUNNER_CONFIG_ARGS: "--url https://github.com/example/project_1 --token FOO"
    volumes:
      - project_1:/home/github/runner
      - *volume-ssh-key
      - *volume-docker-sock
      - *volume-docker-config
  project_1:
    << : *common
    << : *resource-limits
    container_name: runner_project_2
    environment:
      << : *env
      RUNNER_CONFIG_ARGS: "--url https://github.com/example/project_2 --token BAR"
    volumes:
      - project_2:/home/github/runner
      - *volume-docker-sock
      - *volume-docker-config
  mysql: # for tests that require database
    << : *resource-limits
    container_name: runner_mysql
    image: mysql:8
    environment:
      << : *env
      MYSQL_DATABASE: test
      MYSQL_USER: test
      MYSQL_PASSWORD: test
      MYSQL_ROOT_PASSWORD: test
    volumes:
      - mysql:/var/lib/mysql
    restart: unless-stopped
```

### Environment variables

| Name | Required | Value example |
|---|---|---|
| `RUNNER_CONFIG_ARGS` | **yes** | `--url https://github.com/foo/bar --token FOOBAR` |
| `TZ` _(timezone)_ | no | `Asia/Tokyo` |
