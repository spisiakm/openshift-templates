# Setup the 'master' replication on the MySQL server

echo Populate database

for sql_file in /usr/share/container-scripts/mysql/*.sql; do
	mysql $mysql_flags < $sql_file
done
