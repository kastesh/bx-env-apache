FROM nginx

RUN apt-get update
RUN apt-get install -y vim procps net-tools iproute2

ADD etc/ /etc/nginx/

VOLUME /usr/share/nginx/html
VOLUME /var/log/nginx

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh


EXPOSE 80

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["nginx"]
