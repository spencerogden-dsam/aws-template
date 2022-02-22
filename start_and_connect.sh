#!/bin/zsh

PROJECT="WeatherSample"
MACHINE="dev"

KEY_NAME="$PROJECT-Key"
KEY_FILE="$KEY_NAME.pem"

INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name, Values=$PROJECT-$MACHINE" "Name=instance-state-name,Values=stopped" --output text --query 'Reservations[0].Instances[0].InstanceId')

IP_ADDRESS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text --query 'Reservations[*].Instances[*].[PublicIpAddress]')

aws ec2 start-instances --instance-ids $INSTANCE_ID

aws ec2 wait instance-running --instance-ids $INSTANCE_ID

echo "Connecting to Instance $INSTANCE_ID at $IP_ADDRESS"

ssh-keygen -R $IP_ADDRESS
ssh-keyscan $IP_ADDRESS >> ~/.ssh/known_hosts
ssh -i $KEY_FILE ec2-user@$IP_ADDRESS