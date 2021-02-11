# Create a control plane and service mesh member roll

export CONTROL_PLANE_NAMESPACE=istio-system
# If the first parameter is elasticsearch the Jaeger instance created will be backed by ElasticSearch, otherwise
# we will use an all-in-one instance
jaegerstorage=$1

oc delete project ${CONTROL_PLANE_NAMESPACE} || true
oc wait --for=delete namespace/${CONTROL_PLANE_NAMESPACE}  --timeout=120s
oc new-project ${CONTROL_PLANE_NAMESPACE} || true
set -e

if [ "${jaegerstorage}" == "elasticsearch" ]; then
  echo "Creating control plane - using elasticsearch as Jaeger storage"
  oc create -f service-mesh-control-plane-v2.yaml
else
  echo "Creating control plane - using Jaeger with in-memory storage"
  oc create -f service-mesh-control-plane-basic.yaml
fi

sleep 90
start_time=`date +%s`
set +e
set -x
maxtime="5 minute"
endtime=$(date -ud "$maxtime" +%s)
while [[ $(date -u +%s) -le $endtime ]]
do
    STATUS=$(oc get smcp ${CONTROL_PLANE_NAMESPACE} --namespace ${CONTROL_PLANE_NAMESPACE} | grep ${CONTROL_PLANE_NAMESPACE} | awk '{print $3}')
    echo control plane ${CONTROL_PLANE_NAMESPACE} status: ${STATUS}
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
# sleep 60
oc wait --for=condition=available deployment/jaeger --namespace ${CONTROL_PLANE_NAMESPACE} --timeout=120s
