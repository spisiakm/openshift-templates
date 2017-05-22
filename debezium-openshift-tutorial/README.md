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
Debezium Connector is now up and running and is exposed via a route. To find a hostname on which it is running, use
```
oc get route
NAME      HOST/PORT                           PATH      SERVICES   PORT      TERMINATION   WILDCARD
connect   connect-jpechane.apps.devel                   connect    8083                    None
```
Connector endopint is thus `http://connect-jpechane.apps.devel`.
