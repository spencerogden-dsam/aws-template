#!/bin/zsh

PROJECT="WeatherSample"
MACHINE="dev"
IMAGE="ami-033b95fb8079dc481" # AWS Linux
TYPE="t2.micro"
PYTHON_VERSION='3.10.2'

# Create PEM
aws ec2 create-key-pair --key-name "$PROJECT-Key" --query 'KeyMaterial' --output text > "$PROJECT-Key.pem"
KEY_NAME="$PROJECT-Key"
KEY_FILE="$KEY_NAME.pem"
chmod 600 $KEY_FILE

# All resources are created under your default VPC

VPC_ID=$(aws ec2 describe-vpcs --filters 'Name=is-default,Values=true' --output text --query 'Vpcs[*].VpcId')
echo "Using VPC $VPC_ID"

EIP_ID=$(aws ec2 allocate-address --domain vpc --output text --query 'AllocationId')
aws ec2 create-tags --resources $EIP_ID --tags Key=Name,Value=$PROJECT-$MACHINE
IP_ADDRESS=$(aws ec2 describe-addresses --allocation-ids $EIP_ID --output text --query 'Addresses[*].PublicIp')
echo "Allocated IP $IP_ADRESS, ID $EIP_ID"

SG_ID=$(aws ec2 create-security-group --group-name $PROJECT-$MACHINE --description "$PROJECT-$MACHINE Security Group" --vpc-id $VPC_ID --output text --query 'GroupId')
echo "Created Security Group $SG_ID"
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr '0.0.0.0/0'
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr '0.0.0.0/0'
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 443 --cidr '0.0.0.0/0'
echo "Added rules for $SG_ID"

INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE --count 1 --instance-type $TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --output text --query 'Instances[*].InstanceId')

echo "Created Instance: $INSTANCE_ID. Waiting for running state"

aws ec2 wait instance-running --instance-ids $INSTANCE_ID

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$PROJECT-$MACHINE
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $EIP_ID

echo "Waiting for machine to finish initialization"

aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID

ssh-keygen -R $IP_ADDRESS
ssh-keyscan $IP_ADDRESS >> ~/.ssh/known_hosts
echo "Setting Up pyenv and poetry"
ssh -i $KEY_FILE ec2-user@$IP_ADDRESS  << 'EOF'
   sudo yum -y install git gcc zlib-devel bzip2 bzip2-devel readline readline-devel sqlite sqlite-devel openssl11 openssl11-devel libffi-devel
   curl -sSL https://install.python-poetry.org | python3 -
   curl https://pyenv.run | bash
   
   echo 'export PATH=$PATH:~/.pyenv/bin' >> ~/.bash_profile 
   echo 'eval "$(pyenv init --path)"' >> ~/.bash_profile
   echo 'export PATH=$PATH:~/.pyenv/bin' >> ~/.bashrc
   echo 'eval "$(pyenv init -)"' >> ~/.bashrc 
EOF

echo "Installing python"
ssh -i $KEY_FILE ec2-user@$IP_ADDRESS "~/.pyenv/bin/pyenv install $PYTHON_VERSION; ~/.pyenv/bin/pyenv local $PYTHON_VERSION"

echo "Setup complete"