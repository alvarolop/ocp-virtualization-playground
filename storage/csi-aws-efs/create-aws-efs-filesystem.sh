#!/bin/sh

set -e

source $1

# User defined variables
AWS_EFS_FILESYSTEM_NAME="default-filesystem"

# Print environment variables
echo -e "\n=============="
echo -e "ENVIRONMENT VARIABLES:"
echo -e " * AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo -e " * AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo -e " * AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"
echo -e " * AWS_S3_BUCKET: $AWS_S3_BUCKET"
echo -e "==============\n"

if ! which aws &> /dev/null; then 
    echo "You need the AWS CLI to run this Quickstart, please, refer to the official documentation:"
    echo -e "\thttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

if aws efs describe-file-systems --region $AWS_DEFAULT_REGION | grep ${AWS_EFS_FILESYSTEM_NAME} &> /dev/null; then
    FILE_SYSTEM_ID=$(aws efs describe-file-systems --region $AWS_DEFAULT_REGION | jq -r '.FileSystems[0].FileSystemId')
    echo -e "Check. The EFS ${AWS_EFS_FILESYSTEM_NAME} already exists with ID $FILE_SYSTEM_ID, do nothing."
    exit 0
else
    echo -e "Check. Creating EFS ${AWS_EFS_FILESYSTEM_NAME} file system..."   
fi

FILE_SYSTEM_ID=$(aws efs create-file-system \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --region $AWS_DEFAULT_REGION \
    --tags Key=Name,Value=${AWS_EFS_FILESYSTEM_NAME} \
    | jq -r '.FileSystemId')

echo -e "\nThe EFS file system has id $FILE_SYSTEM_ID"
for i in {5..0}; do echo -ne "Waiting $i seconds..."'\r'; sleep 1; done; echo 

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

aws efs create-mount-target \
    --region $AWS_DEFAULT_REGION \
    --file-system-id "$FILE_SYSTEM_ID" \
    --subnet-id $SUBNET_ID \
    --security-groups $SECURITY_GROUP

aws ec2 authorize-security-group-ingress \
    --region $AWS_DEFAULT_REGION \
    --group-id $SECURITY_GROUP \
    --protocol tcp --port 2049 \
    --cidr 10.0.0.0/16

echo -e "\nThe EFS file system $FILE_SYSTEM_ID mounted at "

oc process -f storage-csi-aws-efs/30-storage-class-efs.yaml \
    -p FILE_SYSTEM_ID=$FILE_SYSTEM_ID | oc apply -f -
