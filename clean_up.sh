#!/bin/zsh

PROJECT="WeatherSample"
MACHINE="dev"
KEY_NAME="$PROJECT-Key"
KEY_FILE="$KEY_NAME.pem"

# instances
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name, Values=WeatherSample-dev" --output json --query 'Reservations[].Instances[].InstanceId')
aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
# Take name of instance to speed up removal
echo "INSTANCE $INSTANCE_IDS"

aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS

# EIPs
EIP_IDS=$(aws ec2 describe-addresses --filters "Name=tag:Name, Values=$PROJECT-$MACHINE" --output text --query 'Addresses[].AllocationId')
aws ec2 release-address --allocation-id $EIP_IDS
echo "EIP $EIP_IDS"

# Security groups
SG_IDS=$(aws ec2 describe-security-groups --group-names $PROJECT-$MACHINE --output text --query 'SecurityGroups[].GroupId')
aws ec2 delete-security-group --group-id $SG_IDS
echo "SG $SG_IDS"

# Keys
KEY_ID=$(aws ec2 describe-key-pairs --filters "Name=tag:Name, Values=WeatherSample-Key" --output json --query 'KeyPairs[0].KeyPairId')
aws ec2 delete-key-pair --key-pair-id $KEY_ID
rm $KEY_FILE