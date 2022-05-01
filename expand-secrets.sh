#!/bin/sh
# Taken from https://github.com/DevilaN/docker-entrypoint-example/blob/main/docker/entrypoint/docker-entrypoint.d/.env-from-docker-secrets

# EXPANDING VARIABLES FROM DOCKER SECRETS
: ${ENV_SECRETS_DIR:=/run/secrets}

# usage: env_secret_expand VAR
#    ie: env_secret_expand 'XYZ_DB_PASSWORD'
# (will check for "$XYZ_DB_PASSWORD" variable value for a placeholder that defines the
#  name of the docker secret to use instead of the original value. For example:
# XYZ_DB_PASSWORD="docker-secret:my-db_secret"
env_secret_expand() {
    var="$1"
    eval val=\$"$var"
    if secret_name=$(expr match "$val" "docker-secret:\([^}]\+\)$"); then
        secret="${ENV_SECRETS_DIR}/${secret_name}"
        if [ -f "$secret" ]; then
            val=$(cat "${secret}")
            export "$var"="$val"
        fi
    fi
}

env_secrets_expand() {
    for env_var in $(printenv | cut -f1 -d"=")
    do
      # script fails if env variable has name that contains '(', skip it here
      case "$env_var" in
        *\(*) ;;
        *) env_secret_expand "$env_var" ;;
      esac
    done
}

env_secrets_expand
