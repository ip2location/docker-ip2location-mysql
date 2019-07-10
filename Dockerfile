FROM debian:stretch-slim
MAINTAINER IP2Location <support@ip2location.com>

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt -qy install apt-utils mysql-server wget unzip

# Add MySQL configuration
ADD custom.cnf /etc/mysql/mariadb.conf.d/999-custom.cnf

# Add MySQL scripts
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# Exposed ENV
ENV TOKEN FALSE
ENV CODE FALSE

# Add VOLUMEs
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

EXPOSE 3306 33060
CMD ["/run.sh"]
