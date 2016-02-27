FROM debian:latest
MAINTAINER Dmitrii Zolotov <dzolotov@herzen.spb.ru>

# Install packages

ENV DEBIAN_FRONTEND noninteractive

ADD sources.list /etc/apt/
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y nginx php5-fpm php5-gd php5-pgsql git python-setuptools zendframework sudo postgresql-client mc libwrap0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir /usr/share/webacula && cd /usr/share/webacula && git clone https://github.com/tim4dev/webacula . && \
    rm /usr/share/webacula/install/PostgreSql/* && rm /usr/share/webacula/application/config.ini && rm /usr/share/webacula/install/db.conf && \
    chown www-data:www-data -R /usr/share/webacula && chmod 777 -R /usr/share/webacula/data && useradd postgres && \
    rm -rf /etc/nginx/sites-available/* && rm -rf /etc/nginx/sites-enabled/*

ADD 10_make_tables.sh /usr/share/webacula/install/PostgreSql/
ADD 20_acl_make_tables.sh /usr/share/webacula/install/PostgreSql/
ADD config.ini /usr/share/webacula/application/
ADD db.conf /usr/share/webacula/install/
ADD webacula.conf /etc/nginx/sites-enabled
ADD bconsole /opt/bacula/bin/
ADD bconsole.conf /opt/bacula/etc/
ADD run.sh /
ADD startFPMWithDockerEnvs.sh /etc/php5/
ADD lib.tar.gz /opt/bacula/lib

ENV PG_DB bacula
ENV PG_USER bacula
ENV PG_PWD bacula
ENV PG_HOST 127.0.0.1
ENV ROOT_PWD root
ENV DIR_HOST 127.0.0.1
ENV DIR_NAME director
ENV DIR_PWD director
ENV DOMAIN example.com

# Supervisor Config
RUN mkdir /var/log/supervisor/
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD supervisord.conf /etc/supervisord.conf

RUN echo "Europe/Moscow" > /etc/timezone && dpkg-reconfigure tzdata

EXPOSE 80

CMD ["supervisord","-n","-c","/etc/supervisord.conf"]
