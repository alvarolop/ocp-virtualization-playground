#!/bin/sh

source $1

# Print environment variables
echo -e "\n=============="
echo -e "ENVIRONMENT VARIABLES:"
echo -e " * AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo -e " * AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo -e " * AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"
echo -e "==============\n"

# The following command lists all the subnets, filtering the only one that is private and also in the availability zone A and retrieves its SubnetId.
SUBNET_ID=$(aws ec2 describe-subnets \
    --region $AWS_DEFAULT_REGION \
    --filters Name=tag:Name,Values=*-private-${AWS_DEFAULT_REGION}a \
    --query "Subnets[*].SubnetId" \
    --output text)

SECURITY_GROUP=$(aws ec2 describe-security-groups \
    --region $AWS_DEFAULT_REGION \
    --filters Name=tag:Name,Values=*worker* \
    --query "SecurityGroups[*].GroupId" \
    --output text)

echo "This is the SUBNET_ID: $SUBNET_ID"
echo "This is the SECURITY_GROUP: $SECURITY_GROUP"


# The following command creates an interface in the same private region as the Metal instance is.
NETWORK_INTERFACE_ID=$(aws ec2 create-network-interface \
    --region $AWS_DEFAULT_REGION \
    --subnet-id $SUBNET_ID \
    --description "Second interface for the VM" \
    --groups $SECURITY_GROUP | jq -r .NetworkInterface.NetworkInterfaceId)
    # --private-ip-address 10.0.2.17

echo "This is the NETWORK_INTERFACE_ID: $NETWORK_INTERFACE_ID"

# This command provides both the instance id and the subnet id. Although we are getting the network in a different way above.
# INSTANCE_ID=$(aws ec2 describe-instances \
#     --region $AWS_DEFAULT_REGION \
#     --filters Name=instance-type,Values=c5.metal  Name=instance-state-code,Values=16 \
#     --query "Reservations[*].Instances[*].{Instance:InstanceId,Subnet:SubnetId}")

# The following command retrieves the ID of the metal instance
INSTANCE_ID=$(aws ec2 describe-instances \
    --region $AWS_DEFAULT_REGION \
    --filters Name=instance-type,Values=c5.metal Name=instance-state-code,Values=16 \
    --query "Reservations[*].Instances[*].{Instance:InstanceId}" \
    --output text)

echo "This is the INSTANCE_ID: $INSTANCE_ID"

# The following command attaches the network interface to the metal instance 
aws ec2 attach-network-interface \
    --region $AWS_DEFAULT_REGION \
    --network-interface-id $NETWORK_INTERFACE_ID \
    --instance-id $INSTANCE_ID \
    --device-index 1