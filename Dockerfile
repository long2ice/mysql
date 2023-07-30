FROM ubuntu
ENV BACKUP_CRON="0 0 * * *"
RUN apt update -y && apt install mysql-server zstd wget lsb-release curl rclone gnupg cron -y
RUN sed -i 's/^# datadir.*$/datadir = \/var\/lib\/mysql/' /etc/mysql/mysql.conf.d/mysqld.cnf && touch /var/log/cron.log && usermod -d /var/lib/mysql/ mysql
RUN wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb && dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb && rm -f percona-release_latest.$(lsb_release -sc)_all.deb && percona-release enable-only tools release && apt update -y && apt install percona-xtrabackup-80 -y && apt clean -y && apt autoremove -y
RUN mkdir /backup
COPY ./backup.sh /backup/
WORKDIR /backup
RUN chmod +x /backup/backup.sh && echo "${BACKUP_CRON} cd /backup && ./backup.sh backup >> /var/log/cron.log" | crontab
ENTRYPOINT ["/bin/bash", "-c", "service cron start && service mysql start && tail -f /var/log/cron.log"]
