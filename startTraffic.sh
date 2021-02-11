# This script will install and start the traffic generator.
export TRAFFIC_GENERATOR_NAMESPACE=traffic
export CONTROL_PLANE_NAMESPACE=istio-system

export ROUTE="http://"$(oc get route --namespace ${CONTROL_PLANE_NAMESPACE} | grep bookinfo-bookinfo-gateway | awk '{print $2}')/productpage
echo Bookinfo ROUTE is $ROUTE

oc delete project ${TRAFFIC_GENERATOR_NAMESPACE} || true
oc wait --for=delete namespace/${TRAFFIC_GENERATOR_NAMESPACE}  --timeout=120s
oc new-project ${TRAFFIC_GENERATOR_NAMESPACE}

# We need to create the configmap first
# Set duration to "0s" for traffic to never end.
# Set RATE to number of operations per second or per time unit.  Default is per second, we can use something like 1/10s to run every 10 seconds

## FIXME -  require from command line, or allow overriding?
DURATION="2m"
RATE="20/5s"
cat ./traffic-generator/openshift/traffic-generator-configmap.yaml | DURATION="${DURATION}" ROUTE="$ROUTE" RATE="$RATE"  envsubst | oc apply -n ${TRAFFIC_GENERATOR_NAMESPACE} -f -
cat ./traffic-generator/openshift/traffic-generator.yaml | oc apply -n ${TRAFFIC_GENERATOR_NAMESPACE} -f -