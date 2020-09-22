FROM debian:bullseye-slim
MAINTAINER IP2Location <support@ip2location.com>

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -qy install mariadb-server wget unzip

# Add MySQL configuration
ADD custom.cnf /etc/mysql/mariadb.conf.d/999-custom.cnf

# Add scripts
ADD run.sh /run.sh
ADD update.sh /update.sh
RUN chmod 755 /*.sh

# Exposed ENV
ENV TOKEN FALSE
ENV CODE FALSE
ENV MYSQL_PASSWORD FALSE

# Add VOLUMEs
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

EXPOSE 3306 33060
CMD ["/run.sh"]