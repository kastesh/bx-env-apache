#!/bin/bash

[[ $DEBUG == true ]] && set -x

INSTALL_DIR=/tmp/.install
WORK_DIR=/var/www/html/default

# command to run
RUN="${1}"
# arguments
EXTRA_ARGS="${@:2}"

# which archive is deployed in the project directory
# if this variable is empty - nothing to do
ARCH="${BX_ARCHIVE}"

SETTINGS_TMPL=.settings.php.template
DBCONN_TMPL=dbconn.php.template

PHP_CONF_DIR=/etc/php.d
PHP_MODULES_DISABLE="xdebug xhprof mssql
    phar xmlwriter xmlreader
    sqlite3 pdo pdo_dblib pdo_mysql
    pdo_sqlite imap xsl soap
    curl gmp posix sybase_ct sysvmsg
    sysvsem sysvshm wddx xsl ftp"

bx_init(){
    # test if there is project files installed
    if [[ -f $WORK_DIR/bitrix/.settings.php || \
        -f $WORK_DIR/bitrix/php_interface/dbconn.php ]]; then
        return 0
    fi

    pushd ${WORK_DIR} >/dev/null 2>&1

    # if no archive than no unpack things
    if [[ -n "${ARCH}" ]]; then
        echo "Copy project file: ${ARCH}"
        #tar xzvf ${ARCH}
        LOCAL_ARCH=$(echo "${ARCH}" | awk -F'/' '{print $NF}')
        curl ${ARCH} --output $LOCAL_ARCH
        if [[ $(echo "$LOCAL_ARCH" |  grep -c '\.\(tar\.gz\|tgz\)$') -gt 0 ]]; then
            tar xzvvf $LOCAL_ARCH
            rm -f $LOCAL_ARCH
        else
            echo "This type of archive is not supported. File $LOCAL_ARCH"
        fi
    fi

    echo "Update installation directory"
    cat ${INSTALL_DIR}/$SETTINGS_TMPL | \
        sed -e "\
            s/__SERVER__/${MYSQL_SERVER}/;\
            s/__LOGIN__/${MYSQL_USER}/;\
            s/__PASSWORD__/${MYSQL_PASSWORD}/;\
            s/__SECURITY_KEY__/${PUSH_SERVER_KEY}/;\
        " > $WORK_DIR/bitrix/.settings.php
    cat ${INSTALL_DIR}/$DBCONN_TMPL | \
        sed -e "\
            s/__SERVER__/${MYSQL_SERVER}/;\
            s/__LOGIN__/${MYSQL_USER}/;\
            s/__PASSWORD__/${MYSQL_PASSWORD}/;\
        " > $WORK_DIR/bitrix/php_interface/dbconn.php

    popd 

    echo "Change access rights"
    chown -R apache:apache $WORK_DIR 
}
disable_modules(){
    for mod in $PHP_MODULES_DISABLE; do
        # It may be a variant with multiple files
        mod_files=$(find $PHP_CONF_DIR/ -name "*${mod}.ini" -type f)

        # already disabled
        [[ -z $mod_files ]] && continue

        for f in $mod_files; do
            # empty file; next
            [[ ! -s ${f} ]] && continue

            # file with disabled prefix; next
            [[ -f ${f}.disabled ]] && continue

            mv -fv ${f} ${f}.disabled
            touch ${f}
        done
    done
}

update_opcache(){
    opcache_file=$(find $PHP_CONF_DIR/ -name "*opcache.ini" -type f)

    [[ -z $opcache_file ]] && return 0

    mv -fv ${PHP_CONF_DIR}/opcache.ini.docker ${opcache_file}
}

php_init(){
    disable_modules

    update_opcache
}

# initial setup
bx_init

# php settings
php_init

# update access rights
chown -R apache:apache /var/log/php
chown -R apache:apache /var/www/html/.bx_temp

# run httpd
if [[ -z ${RUN} || ${RUN} == "httpd" || ${RUN} == $(which httpd) ]]; then
    echo "Starting apache..."
    exec $(which httpd) -DFOREGROUND $EXTRA_ARGS
else
    exec "${RUN} ${$EXTRA_ARGS}"
fi
