#!/bin/zsh

PROJECT="WeatherSample"
MACHINE="dev"

INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$PROJECT-$MACHINE" "Name=instance-state-name,Values=running"  --output json --query 'Reservations[].Instances[].InstanceId')
echo "Stopping $INSTANCE_IDS"
aws ec2 stop-instances --instance-ids $INSTANCE_IDS