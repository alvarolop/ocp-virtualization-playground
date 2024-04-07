#!/bin/sh

oc process -f scripts/template-baremetal-instance.yaml \
    -p INFRASTRUCTURE_ID=$(oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster) \
| oc apply -n openshift-machine-api -f -
