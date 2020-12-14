#
# Run this script to add an occasional delay and abort to the bookinfo application
#
export BOOKINFO_NAMESPACE=bookinfo

oc delete virtualservice --namespace ${BOOKINFO_NAMESPACE} ratings  --ignore-not-found=true
oc delete virtualservice --namespace ${BOOKINFO_NAMESPACE} details-delay --ignore-not-found=true

oc create --namespace ${BOOKINFO_NAMESPACE} -f virtual-service-ratings-test-abort.yaml
oc create --namespace ${BOOKINFO_NAMESPACE} -f virtual-service-details-test-delay.yaml

oc get virtualservice --namespace ${BOOKINFO_NAMESPACE}

