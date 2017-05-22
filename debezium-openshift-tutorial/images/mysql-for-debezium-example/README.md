# mysql-for-debezium

This image is derived from CentOS-based MySQL image. It runs in OpenShift out of the box and at the same time enables privileges necessary for an initial snapshot of database contents.

An (incomplete) pod specification for running in OpenShift or Kuberenetes looks like
```yaml
    spec:
      containers:
      - args:
        - run-mysqld-master
        env:
        - name: MYSQL_USER
          value: debezium
        - name: MYSQL_PASSWORD
          value: dbz
        - name: MYSQL_DATABASE
          value: sampledb
        - name: MYSQL_BINLOG_FORMAT
          value: row
        - name: MYSQL_MASTER_PASSWORD
          value: dbz
        - name: MYSQL_MASTER_USER
          value: debezium
        - name: MYSQL_ROOT_PASSWORD
          value: dbz
       ports:
        - containerPort: 3306
          protocol: TCP
       livenessProbe:
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 10
          successThreshold: 1
          tcpSocket:
            port: 3306
          timeoutSeconds: 1
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -i
            - -c
            - MYSQL_PWD="$MYSQL_PASSWORD" mysql -h 127.0.0.1 -u $MYSQL_USER -D $MYSQL_DATABASE
              -e 'SELECT 1'
          failureThreshold: 3
          initialDelaySeconds: 5
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1         
```
