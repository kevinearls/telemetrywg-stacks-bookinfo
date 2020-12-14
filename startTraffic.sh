# This script will install the traffic generator.
export ROUTE="http://"$(oc get route --namespace istio-system | grep bookinfo-bookinfo-gateway | awk '{print $2}')/productpage
echo ROUTE is $ROUTE
export TRAFFIC_GENERATOR_NAMESPACE=traffic

oc delete project ${TRAFFIC_GENERATOR_NAMESPACE} || true
oc wait --for=delete namespace/${TRAFFIC_GENERATOR_NAMESPACE}  --timeout=120s
oc new-project ${TRAFFIC_GENERATOR_NAMESPACE}

# We need to create the configmap first
# Set duration to "0s" for traffic to never end.  Set RATE to number of operations per second or per time unit.  Default is per second, we can use something like 1/10s to run every 10 seconds
DURATION="2m"
RATE="20/5s"
curl https://raw.githubusercontent.com/kiali/kiali-test-mesh/master/traffic-generator/openshift/traffic-generator-configmap.yaml | DURATION="${DURATION}" ROUTE="$ROUTE" RATE="$RATE"  envsubst | oc apply -n ${TRAFFIC_GENERATOR_NAMESPACE} -f -
curl https://raw.githubusercontent.com/kiali/kiali-test-mesh/master/traffic-generator/openshift/traffic-generator.yaml | oc apply -n ${TRAFFIC_GENERATOR_NAMESPACE} -f -