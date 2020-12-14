# Create a control plane and service mesh member roll
set -x
set +e

export CONTROL_PLANE_NAMESPACE=istio-system
export CONTROL_PLANE_NAME=istio-system
export BOOKINFO_NAMESPACE=bookinfo
export BOOKINFO_BASE="https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/"
export BOOKINFO_YAML="${BOOKINFO_BASE}/platform/kube/bookinfo.yaml"
export BOOKINFO_GATEWAY="${BOOKINFO_BASE}/networking/bookinfo-gateway.yaml"
export BOOKINFO_DESTINATION_RULES="${BOOKINFO_BASE}/networking/destination-rule-all.yaml"
export TRAFFIC_GENERATOR_NAMESPACE=traffic

oc delete project ${CONTROL_PLANE_NAMESPACE} || true
oc wait --for=delete namespace/${CONTROL_PLANE_NAMESPACE}  --timeout=120s
oc new-project ${CONTROL_PLANE_NAMESPACE} || true
set -e
oc create -f service-mesh-control-plane-v2.yaml

sleep 90
start_time=`date +%s`
set +e
maxtime="5 minute"
endtime=$(date -ud "$maxtime" +%s)
while [[ $(date -u +%s) -le $endtime ]]
do
    STATUS=$(oc get smcp istio-system --namespace ${CONTROL_PLANE_NAMESPACE} | grep istio-system | awk '{print $3}')
    echo control plane istio-system status: ${STATUS}
    if [ "${STATUS}" == "InstallSuccessful" ] ; then
        oc get smcp --namespace ${CONTROL_PLANE_NAMESPACE}
        break;
    fi
    sleep 10
done
set -e

# Make sure we haven't fallen thru the loop above because of time out.
oc get smcp --namespace ${CONTROL_PLANE_NAMESPACE}
oc get deployments --namespace ${CONTROL_PLANE_NAMESPACE}
oc wait --for=condition=available deployment/istio-egressgateway --namespace ${CONTROL_PLANE_NAMESPACE}

# Create the member roll
oc apply --namespace ${CONTROL_PLANE_NAMESPACE} -f service-mesh-member-roll.yaml

# Wait for the Jaeger instance to be ready
sleep 60
export JAEGER_OPERATOR_NAMESPACE=$(oc get deployments --all-namespaces | grep jaeger-operator | awk '{print $1}')
oc wait --for=condition=available deployment/jaeger-operator --namespace ${JAEGER_OPERATOR_NAMESPACE} --timeout=120s

# Install bookinfo
oc delete project ${BOOKINFO_NAMESPACE} || true
oc wait --for=delete namespace/${BOOKINFO_NAMESPACE} --timeout=120s || true
oc new-project ${BOOKINFO_NAMESPACE}
oc apply -n ${BOOKINFO_NAMESPACE} -f ${BOOKINFO_YAML}

sleep 30
for deployment in details-v1 productpage-v1 ratings-v1 reviews-v1 reviews-v2 reviews-v3 ; do
    oc wait --for=condition=available deployment/${deployment} --namespace ${BOOKINFO_NAMESPACE} --timeout=120s
done

oc apply -n ${BOOKINFO_NAMESPACE} -f ${BOOKINFO_GATEWAY}
oc apply -n ${BOOKINFO_NAMESPACE} -f ${BOOKINFO_DESTINATION_RULES}

export GATEWAY_URL=$(oc -n ${CONTROL_PLANE_NAMESPACE} get route istio-ingressgateway -o jsonpath='{.spec.host}')
echo "The URL for the productpage is http://${GATEWAY_URL}/productpage"

# TODO we either need to wait or retry here.Verify that it is installed -it should return a 200
sleep 30
curl -o /dev/null -s -w "%{http_code}\n" http://$GATEWAY_URL/productpage
