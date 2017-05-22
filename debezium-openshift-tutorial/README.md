# Debezium tutorial deployed to an OpenShift environment

This set of templates allows the user to emulate the workflow defined in [Debezium Tutorial](http://debezium.io/docs/tutorial/) and create the tutorial environment in an OpenShift instance.

## Prerequisities
- `oc` - [OpenShift client](https://github.com/openshift/origin/releases)
- A running Openshift instance, obtained on of
    - [Cluster installation](https://docs.openshift.org/latest/install_config/index.html)
    - [Local cluster instance](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md) - `oc cluster up`
    - a [Minishift](https://github.com/minishift/minishift) local instance
## Deployment steps
### Deploy images streams
Deploy image streams with four images used by the tutorial
- MySQL
- ZooKeeper
- Kafka
- Debezium
```
oc create -f https://raw.githubusercontent.com/jpechane/openshift-templates/master/debezium-openshift-tutorial/image-streams.yaml
```
The result of the operation should be
```
imagestream "zookeeper" created
imagestream "kafka" created
imagestream "connect" created
imagestream "mysql" created
```
### Deploy a MySQL instance
The MySQL image is derived from [MySQL CentOS image](https://hub.docker.com/r/centos/mysql-57-centos7/) and has enabled replication and contains a prepopulate database script. Deploy the MySQL instance using command
```
oc process -f https://raw.githubusercontent.com/jpechane/openshift-templates/master/debezium-openshift-tutorial/templates/mysql-ephemeral-template.json -p MYSQL_USER=mysqluser -p MYSQL_PASSWORD=mysqlpw -p MYSQL_ROOT_PASSWORD=debezium -p MYSQL_MASTER_USER=debezium -p MYSQL_MASTER_PASSWORD=dbz -p NAMESPACE=$(oc project -q) | oc create -f -
```
The result of the operation should be
```
secret "mysql" created
service "mysql" created
deploymentconfig "mysql" created
```
A new MySQL instance should be up and running in the OpenShift namespace
```
oc get pods -w
NAME            READY     STATUS    RESTARTS   AGE
mysql-1-p0jm3   1/1       Running   0          50s
```
### Deploy a Debezium environment
Create a Debezium runtime environemnt consisting of a single ZooKeeper server, a single Kafka server and a single Debezium instance
```
oc process -f https://raw.githubusercontent.com/jpechane/openshift-templates/master/debezium-openshift-tutorial/templates/debezium-template.yaml | oc create -f -
```
The result of the operation should be
```
deploymentconfig "zookeeper" created
deploymentconfig "kafka" created
deploymentconfig "connect" created
service "kafka" created
service "zookeeper" created
service "connect" created
route "connect" created
```
After a while the environment should be up and running.

*Note: As OpenShift does not define dependencies between services it is possible that some of the pods will restart during the deployment process*
```
oc get pods -w
NAME                READY     STATUS    RESTARTS   AGE
connect-1-1r19p     1/1       Running   0          5m
kafka-1-04n0w       1/1       Running   4          5m
mysql-1-p0jm3       1/1       Running   0          10m
zookeeper-1-b314l   1/1       Running   0          5m
```
Kafka Connect is now up and running and is exposed via a route. To find a hostname on which it is running, use
```
oc get route
NAME      HOST/PORT                           PATH      SERVICES   PORT      TERMINATION   WILDCARD
connect   connect-jpechane.apps.devel                   connect    8083                    None
```
Connect endpoint is thus `CONNECT_URL=http://connect-jpechane.apps.devel`.
### Configure MySQL connector
- Verify that connector is up and running
```
curl ${CONNECT_URL}/connectors
[]
```
- Configure MySQL connector and establish a link between the connector and the MySQL instance
```
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" ${CONNECT_URL}/connectors/ -d '{ "name": "inventory-connector", "config": { "connector.class": "io.debezium.connector.mysql.MySqlConnector", "tasks.max": "1", "database.hostname": "mysql", "database.port": "3306", "database.user": "debezium", "database.password": "dbz", "database.server.id": "184054", "database.server.name": "dbserver1", "database.whitelist": "inventory", "database.history.kafka.bootstrap.servers": "kafka:9092", "database.history.kafka.topic": "dbhistory.inventory" } }'
HTTP/1.1 201 Created
Date: Mon, 22 May 2017 09:07:55 GMT
Location: http://connect-jpechane.apps.devel.xpaas/connectors/inventory-connector
Content-Type: application/json
Content-Length: 471
Server: Jetty(9.2.15.v20160210)
Set-Cookie: 28f8b64e7ee4ef8a86561e966e488699=f2534918cdf272d0fdf2501479430a80; path=/; HttpOnly

{"name":"inventory-connector","config":{"connector.class":"io.debezium.connector.mysql.MySqlConnector","tasks.max":"1","database.hostname":"mysql","database.port":"3306","database.user":"debezium","database.password":"dbz","database.server.id":"184054","database.server.name":"dbserver1","database.whitelist":"inventory","database.history.kafka.bootstrap.servers":"kafka:9092","database.history.kafka.topic":"dbhistory.inventory","name":"inventory-connector"},"tasks":[]}```
```
- Check Connect logs
```
oc logs -f $(oc get pods -o name | grep connect-1)
.
.
.
2017-05-22 09:08:16,180 INFO   MySQL|dbserver1|task  Attempting to generate a filtered GTID set   [io.debezium.connector.mysql.MySqlTaskContext]
2017-05-22 09:08:16,181 INFO   MySQL|dbserver1|task  GTID set from previous recorded offset: 7759b1b6-3ecb-11e7-8440-32e44caed099:1-14   [io.debezium.connector.mysql.MySqlTaskContext]
2017-05-22 09:08:16,182 INFO   MySQL|dbserver1|task  GTID set available on server: 7759b1b6-3ecb-11e7-8440-32e44caed099:1-14   [io.debezium.connector.mysql.MySqlTaskContext]
2017-05-22 09:08:16,182 INFO   MySQL|dbserver1|task  Final merged GTID set to use when connecting to MySQL: 7759b1b6-3ecb-11e7-8440-32e44caed099:1-14   [io.debezium.connector.mysql.MySqlTaskContext]
2017-05-22 09:08:16,182 INFO   MySQL|dbserver1|task  Registering binlog reader with GTID set: 7759b1b6-3ecb-11e7-8440-32e44caed099:1-14   [io.debezium.connector.mysql.BinlogReader]
May 22, 2017 9:08:16 AM com.github.shyiko.mysql.binlog.BinaryLogClient connect
INFO: Connected to mysql:3306 at 7759b1b6-3ecb-11e7-8440-32e44caed099:1-14 (sid:184054, cid:238)
2017-05-22 09:08:16,288 INFO   MySQL|dbserver1|binlog  Connected to MySQL binlog at mysql:3306, starting at GTIDs 7759b1b6-3ecb-11e7-8440-32e44caed099:1-14 and binlog file 'mysql-bin.000003', pos=194, skipping 0 events plus 0 rows   [io.debezium.connector.mysql.BinlogReader]
.
.
.
```
