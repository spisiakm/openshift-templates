# Debezium tutorial deployed to OpenShift environment

This set of templates allows the user to emulate the workflow defined in [Debezium Tutorial](http://debezium.io/docs/tutorial/) and create the tutorial environment in an OpenShift instance.

## Prerequisities
- `oc` - [OpenShift client](https://github.com/openshift/origin/releases)
- A running Openshift instance, obtained on of
    - [Cluster installation](https://docs.openshift.org/latest/install_config/index.html)
    - [Local cluster instance](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md) - `oc cluster up`
    - a [Minishift](https://github.com/minishift/minishift) local instance
