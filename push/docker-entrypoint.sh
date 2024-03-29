#!/bin/bash

WORKDIR=/opt/push-server

SERVICE_CONFIG=push-server-multi

PUB_TMPL=push-server-pub-__PORT__.json
SUB_TMPL=push-server-sub-__PORT__.json
CONFIG_DIR=/etc/push-server
LOG_DIR=/var/log/push-server


SECURITY_KEY="${PUSH_SERVER_KEY}"

pushd $WORKDIR || exit 1

# config file
[[ ! -f /etc/default/$SERVICE_CONFIG ]] && \
    cp -fv etc/sysconfig/${SERVICE_CONFIG} /etc/default/${SERVICE_CONFIG}

# security key must be used in portal settings
[[ $(grep -v "^$\|^#" /etc/default/${SERVICE_CONFIG} | \
    grep -c "SECURITY_KEY") -eq 0 ]] && \
    echo "SECURITY_KEY=${SECURITY_KEY}" >> /etc/default/${SERVICE_CONFIG}

# run directory; there is pid-files
[[ $(grep -v "^$\|^#" /etc/default/${SERVICE_CONFIG} | \
    grep -c "RUN_DIR") -eq 0 ]] && \
    echo "RUN_DIR=/tmp/push-server" >> /etc/default/${SERVICE_CONFIG}

# tmp dir
[[ ! -d /tmp/push-server ]] && mkdir /tmp/push-server

# change bitrix user to root
sed -i "s/USER=bitrix/USER=root/" /etc/default/${SERVICE_CONFIG}

# debian vs redhat; compatibility
[[ ! -d /etc/sysconfig ]] && mkdir /etc/sysconfig
ln -sf /etc/default/${SERVICE_CONFIG} /etc/sysconfig

# templates for pub and sub services
[[ ! -d /etc/push-server ]] && mkdir /etc/push-server
cp -fv etc/push-server/$PUB_TMPL /etc/push-server/
cp -fv etc/push-server/$SUB_TMPL /etc/push-server/

# service start script
cp -fv etc/init.d/push-server-multi /usr/local/bin
chmod 755 /usr/local/bin/push-server-multi

# generate configs
if [[ ! -f /etc/push-server/push-server-sub-8012.json ]]; then
    /usr/local/bin/push-server-multi configs
fi


# start all services; withous changing user
/usr/local/bin/push-server-multi systemd_start

while sleep 120; do
    for port in 9010 9011; do
        pidf=/tmp/push-server/pub-${port}.pid
        pidn=$(cat $pidf)
        ps ax -o pid |  grep "^\s*${pidn}$" >/dev/null 2>&1
        if [[ $? -gt 0 ]]; then
            echo "One of the processes [pub-${port}] has already exited."
            echo "Pid File: $pidf $(cat $pidf)"
            exit 1
        fi
    done
    for port in 8010 8011 8012 8013 8014 8015; do
        pidf=/tmp/push-server/sub-${port}.pid
        pidn=$(cat $pidf)
        ps ax -o pid |  grep "^\s*${pidn}$" >/dev/null 2>&1
        if [[ $? -gt 0 ]]; then
            echo "One of the processes [sub-${port}] has already exited."
            echo "Pid file: $pidf $(cat $pidf)"
            exit 1
        fi
    done
done

popd >/dev/null 2>&1
