# Bookinfo Setup

This project can be used to install the Istio Bookinfo example application, install 
virtualservices which will cause occasional delays and faults in that application, and install
a traffic generator to create traces.  

## Installation Instructions
Note: This requires being logged into an OCP cluster with cluster-admin access
### Install ServiceMesh and other Operators
This step should be done manually as scripting installation of operators has proven problematic.
- Log into your OCP cluster as a user who has cluster-admin access
- Click on *Operators* and then on *OperatorHub*
- Install the following operators.  In all cases use the default settings, and be sure to install the version provided by Red Hat rather than the
  community or other version.
  - **ElasticSearch Operator** *provided by Red Hat, Inc*
  - **Red Hat OpenShift Jaeger** *provided by Red Hat*
  - **Kiali Operater** *provided by Red Hat*
  - **Red Hat OpenShift Service Mesh** *provided by Red Hat, Inc*
- Click on the *Installed Operators* link under *Operators* to verify that *Status* is *Succeeded* for all operators.  

If desired, details of this installation can be found in [Installing Red Hat OpenShift Service Mesh](https://docs.openshift.com/container-platform/4.6/service_mesh/v2x/installing-ossm.html)

### Create a Service Mesh Control Plane and Install Bookinfo
Login to the OCP cluster in a shell and run the *createSMCPandInstallBookinfo.sh* to create a service mesh control plan 
and install the BookInfo application.  For reference full details can be found [here](https://docs.openshift.com/container-platform/4.6/service_mesh/v2x/prepare-to-deploy-applications-ossm.html#ossm-tutorial-bookinfo-overview_deploying-applications-ossm)

### Add Faults
Run the *addFaults.sh* script.  This will create an occasional delay accessing bookinfo's ratings
service, and an occasional abort accessing the details service.  

The frequency of these faults can be change by editing the **virtual-service-ratings-test-abort.yaml** or 
**virtual-service-details-test-delay.yaml** files before running the *addFaults.sh* script.  **Percentage** can be
specified as a value between 0.0 and 100.0.  Please note that the defaults in these files are set to 50.0 and
25.0 for testing purposes which may be quite high for other use.

Alternatively faults can be created by using the [Kiali Wizards](https://www.openshift.com/blog/introducing-openshift-service-mesh-2.0)

### Start the Traffic Generator
First update the **DURATION** and **RATE** values in the *startTraffic.sh* script, then run that script to start
generating traffic.

**DURATION** can be set to 0 to run indefinitely, or to a specific time like "120s" or "10m"
**RATE** is the number of operations per second or per time unit.  It can be set to something like "10" for 10 
transactions per second, or "1/5s" for one transaction every 5 seconds.



