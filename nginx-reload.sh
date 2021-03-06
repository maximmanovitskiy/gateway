#!/bin/bash


log() {
  date_time="$(date +%Y-%m-%d\ %H:%M:%S)"
  if [ -z $2 ]; then
    echo "${date_time} nginx: $1"
  else
    (>&2 echo "${date_time} nginx: ERROR: $1")
  fi
}


{
  log "starting"
  nginx -g 'daemon off;' "$@" && exit 1
} &

nginx_pid=$!

watches=${NGINX_WATCH_PATHS:-"/etc/nginx/conf.d/server.conf"}
config_file=${NGINX_CONFIG_FILE:-"/etc/nginx/nginx.conf"}

log "setting up watches for ${watches[@]}"

while true
do
        inotifywait -e create,modify,delete ${watches[@]}
        nginx -t -c $config_file
        if [ $? -eq 0 ]
        then
                log 'new configuration file is valid, reloading nginx'
                nginx -s reload
	else
		log 'new configuration is invalid!'
        fi
done

wait $nginx_pid || exit 1
