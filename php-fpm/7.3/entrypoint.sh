#!/usr/bin/env sh

# Recupération de l'utilisateur et groupe courant
uid=$(stat -c %u /srv)
gid=$(stat -c %g /srv)
user='foo'

# fonction pour charger les variables d'environnement du fichier .env
function dotenv ()
{
  set -a
  [ -f .env ] && ./.env
  set +a
}

# Ajout d'une fonction a executer au démarrage de la VM, qui peut mettre à jour la BDD
# et les assets si spécifié dans la variable d'environnement.
function beforeStart ()
{
    if [ "enabled" == "$APP_AUTO_UPDATE" -a -d vendor  ]; then
        echo "beforeStart actions"
    fi
}

function fixDirectoryPermissions()
{
    chown $user -R /srv
    for DIRECTORY in '/srv/app/cache' '/srv/app/logs' '/srv/web/uploads'
    do
            if [ -d  "$DIRECTORY"  ]
            then
                chmod -R 777 "$DIRECTORY"
            fi
    done
}

function update_elastic_agent_config_file() {
  if [ -e /usr/local/etc/php/conf.d/99-elastic-apm-custom.ini ]; then
    sed -i "/;$1.*/c $1 = $2" /usr/local/etc/php/conf.d/99-elastic-apm-custom.ini
  fi
}

function config_apm_elastic (){
  if [ "true" == "$ELASTIC_APM_ENABLED" ]; then
      echo "ELK APM is enabled"
      ELK_APM_ENV=${APP_MODE}
      if [ ! -z "$ELASTIC_APM_ENVIRONMENT" ]; then
        ELK_APM_ENV=${ELASTIC_APM_ENVIRONMENT}

      fi
      update_elastic_agent_config_file "elastic_apm.environnement" "${ELK_APM_ENV}"
      echo "ELK APM ENV is setting to ${ELK_APM_ENV}"
      update_elastic_agent_config_file "elastic_apm.server_url" "${ELASTIC_APM_SERVER_URL}"
      echo "ELK APM URL is setting to ${ELASTIC_APM_SERVER_URL}"
      update_elastic_agent_config_file "elastic_apm.secret_token" "${ELASTIC_APM_SECRET_TOKEN}"
      echo "ELK APM SERVICE NAME is setting to ${ELASTIC_APM_SERVICE_NAME}"
      update_elastic_agent_config_file "elastic_apm.service_name" "${ELASTIC_APM_SERVICE_NAME}"

      LOG_LEVEL="INFO"
      if [ "prod" == $ELK_APM_ENV ]; then
        LOG_LEVEL= "ERROR"
      fi
      if [ ! -z "$ELASTIC_APM_LOG_LEVEL" ]; then
          LOG_LEVEL=${ELASTIC_APM_LOG_LEVEL}
          update_elastic_agent_config_file "elastic_apm.log_level" "${ELASTIC_APM_LOG_LEVEL}"
      fi
      update_elastic_agent_config_file "elastic_apm.log_level" ${LOG_LEVEL}
      echo "ELK APM LOG_LEVEL is setting to ${ELASTIC_APM_SERVICE_NAME}"
  else
      update_elastic_agent_config_file "elastic_apm.enabled" "false"
      echo "ELK APM is disabled"
  fi
}

dotenv
config_apm_elastic

# Si on a activé 'utilisation de XDEBUG on le configure pour PHP
if [ "enabled" == "$APP_XDEBUG" ]; then
    # Enable xdebug
    echo 'Xdebug  is enabled'
else
    # Disable xdebug
    if [ -e /usr/local/etc/php/conf.d/xdebug.ini ]; then
        rm -f /usr/local/etc/php/conf.d/xdebug.ini
    fi
    echo 'Xdebug  is disabled'
fi

if [ $uid == 0 ] && [ $gid == 0 ]; then
    if [ $# -eq 0 ]; then
        beforeStart
    	  fixDirectoryPermissions
        php-fpm --allow-to-run-as-root
    else
        echo "$@"
        exec "$@"
    fi
fi

echo 'Environnement is :'$APP_MODE
# don't use \d with sed, it is not digits but the special char like \r\n :) or use perl but perl is not present everywhere.
sed -i -r "s/$user:x:[[:digit:]]+:[[:digit:]]+:/$user:x:$uid:$gid:/g" /etc/passwd
sed -i -r "s/bar:x:[[:digit:]]+:/bar:x:$gid:/g" /etc/group

sed -i "s/user = www-data/user = $user/g" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/group = www-data/group = bar/g" /usr/local/etc/php-fpm.d/www.conf

if [ $# -eq 0 ]; then
	beforeStart
	fixDirectoryPermissions
  php-fpm
else
    echo gosu $user "$@"
    exec gosu $user "$@"
fi
