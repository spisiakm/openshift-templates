FROM centos/mysql-57-centos7:5.7

COPY post-init.sh /usr/share/container-scripts/mysql/post-init.sh
RUN curl -s https://raw.githubusercontent.com/debezium/docker-images/master/examples/mysql/0.5/inventory.sql > /usr/share/container-scripts/mysql/inventory.sql
