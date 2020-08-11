FROM centos:7

RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 && \
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm --import https://rpms.remirepo.net/RPM-GPG-KEY-remi && \
    rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

RUN yum update -y && \
    yum install -y vim iproute2 procps-ng

RUN sed -i -e '/\[remi-php73\]/,/^\[/s/enabled=0/enabled=1/' /etc/yum.repos.d/remi-php73.repo

RUN yum install -y \
    httpd httpd-tools curl openssl \
    php php-cli php-common \
    php-gd php-imap php-json php-ldap \
    php-mbstring php-mysqlnd php-opcache \
    php-pdo php-pear php-pear-DB \
    php-pecl-apcu php-pecl-apcu-bc php-pecl-geoip \
    php-pecl-mcrypt php-pecl-memcache php-pecl-rrd \
    php-pecl-ssh2 php-pecl-xdebug php-pecl-zip \
    php-process php-pspell php-xml php-zipstream

RUN echo -n > /etc/httpd/conf.modules.d/01-cgi.conf && \
    echo -n > /etc/httpd/conf.modules.d/00-proxy.conf && \
    echo -n > /etc/httpd/conf.modules.d/00-lua.conf && \
    echo -n > /etc/httpd/conf.modules.d/00-dav.conf && \
    echo -n > /etc/httpd/conf.d/autoindex.conf && \
    echo -n > /etc/httpd/conf.d/userdir.conf && \
    echo -n > /etc/httpd/conf.d/welcome.conf

COPY etc/httpd.conf /etc/httpd/conf/httpd.conf
COPY etc/default.conf /etc/httpd/conf.d/default.conf
COPY etc/bitrixenv.ini /etc/php.d/bitrixenv.ini
COPY etc/opcache.ini   /etc/php.d/opcache.ini.docker
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh
ADD .install /tmp/.install

RUN yum clean all

VOLUME /var/www/html
VOLUME /var/log/httpd
VOLUME /var/log/php


EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
