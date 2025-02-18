#!/bin/sh

MACHINESET_NAME=$(oc get machinesets -n openshift-machine-api --template '{{ (index .items 0).metadata.name }}')

oc process -p INFRASTRUCTURE_ID=$(oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster) \
    -p AMI=$(oc get machineset $MACHINESET_NAME -n openshift-machine-api -o jsonpath='{.spec.template.spec.providerSpec.value.ami.id}') \
    -p REGION=$AWS_DEFAULT_REGION -f scripts/template-baremetal-instance.yaml | oc apply -n openshift-machine-api -f -
