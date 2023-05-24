#!/bin/bash

help()
{
    echo "
Usage: setup-iprotate-win.sh
               [ -p | --port           ]
               [ -a | --aws_profile    ]
               [ -d | --instance_id    ]
               [ -k | --keypair        ]
               [ -r | --region         ]
    [ -h | --help           ]"
    return 2
}

SHORT=p:,a:,d:,k:,r:,h
LONG=port:,aws_profile:,instance_id:,keypair:,region:,help
OPTS=$(getopt --alternative --name setup_aws --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
    case "$1" in
        
        -p | --port )
            port="$2"
            shift 2
        ;;
        -a | --aws_profile )
            aws_profile="$2"
            shift 2
        ;;
        -d | --instance_id )
            instance_id="$2"
            shift 2
        ;;
        -k | --keypair )
            keypair="$2"
            shift 2
        ;;
        -r | --region )
            region="$2"
            shift 2
        ;;
        -h | --help)
            help
        ;;
        --)
            shift;
            break
        ;;
        *)
            echo "Unexpected option: $1"
            return 1
        ;;
    esac
done

# Check if AWS CLI is installed
if ! which aws >/dev/null; then
    echo "AWS CLI is not installed. Please install it and try again."
    return 1
fi

# Check if jq is installed
if ! which jq >/dev/null; then
    echo "jq is not installed. Please install it and try again."
    return 1
fi

# Check if wget is installed
if ! which wget >/dev/null; then
    echo "wget is not installed. Please install it and try again."
    return 1
fi

# Check if ssh is installed
if ! which ssh >/dev/null; then
    echo "ssh is not installed. Please install it and try again."
    return 1
fi

# All required tools are installed, continue with the rest of the script
echo "All required tools are installed. Continuing with the rest of the script..."


if [ ! -f "$HOME/.ssh/config" ]; then
    mkdir -p $HOME/.ssh/ && touch $HOME/.ssh/config
cat >> $HOME/.ssh/config <<EOL
Host *
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
EOL
fi

if [[ -z $port ]]; then
    echo "port is set ! setup exited"
    return 0
fi

if [[ -z $aws_profile ]]; then
    echo "aws profile is not set ! setup exited"
    return 0
fi

if [[ -z $keypair ]]; then
    echo "keypair is not set ! setup exited"
    return 0
fi

if [[ -z $region ]]; then
    echo "region profile is not set ! setup exited"
    return 0
fi

if [[ -z $instance_id ]]; then
    echo "instance_id is not set ! setup exited"
    return 0
fi

fulladmin_check=$(aws sts get-caller-identity | jq ".Arn" | grep "fulladmin" | wc -l)

if [[ $fulladmin_check -eq 0 ]]; then
    echo "aws credentials does not have fulladmin policies ! setup exited"
    return 0
fi

export AWS_PROFILE=$aws_profile

chown $USER:$USER $HOME/.ssh/config
chmod 600 $HOME/.ssh/config

#check if keypair is valid
if [ ! -f "$keypair" ]; then
    echo "Keypair file not found"
    return 0
fi

chmod 600 $keypair

#get instance data
datainstance=$(aws ec2 describe-instances --instance-ids $instance_id --region $region)
amidesc=$(aws ec2 describe-images --image-ids $(echo $datainstance | jq -r '.Reservations[].Instances[].ImageId') --region $region | jq -r '.Images[].Description')

#check if amidesc contains "Ubuntu, 20.04 LTS, amd64 focal"
if [[ $amidesc == *"Ubuntu, 20.04 LTS, amd64 focal"* ]]; then
    echo "Ubuntu 20.04 LTS detected"
else
    echo "Ubuntu 20.04 LTS not detected. Please Check your parameter Tutorial"
    return 0
fi

#get nic details
nicinstance=$(echo $datainstance | jq -r '.Reservations[].Instances[].NetworkInterfaces[].NetworkInterfaceId')
subnetid=$(echo $datainstance | jq -r '.Reservations[].Instances[].SubnetId')
vpcid=$(echo $datainstance | jq -r '.Reservations[].Instances[].VpcId')
groupid=$(echo $datainstance | jq -r '.Reservations[].Instances[].SecurityGroups[].GroupId')
attach_id=$(echo $datainstance | jq -r '.Reservations[].Instances[].NetworkInterfaces[].Attachment.AttachmentId')
instance_public_ip=$(echo $datainstance | jq -r '.Reservations[].Instances[].PublicIpAddress')

#check if keypair_fingerprint is equal to key_fingerprint
touch /tmp/test
scp -i $keypair /tmp/test ubuntu@$instance_public_ip:/tmp/test
if [ $? -ne 0 ]; then
    echo "Keypair fingerprint is not valid"
    return 0
else
    return "Keypair fingerprint is valid"
fi

wget https://raw.githubusercontent.com/ilyasbit/all-about-cpu-mining/muter/allowssh.sh -O /tmp/allowssh.sh

echo "Allowing root login via ssh"
ssh -i $keypair ubuntu@$instance_public_ip 'bash -s' < '/tmp/allowssh.sh'

#create IAM
aws iam create-user --user-name $instance_id
aws iam attach-user-policy --user-name $instance_id --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
#list current access keys on user
accesskeys=$(aws iam list-access-keys --user-name $instance_id | jq -r '.AccessKeyMetadata[].AccessKeyId')
#delete existing access key on user
for key in ${accesskeys[@]}; do
    aws iam delete-access-key --user-name $instance_id --access-key-id $key
done

#generate new access key
generatedaccesskey=$(aws iam create-access-key --user-name $instance_id)
access_key=$(echo $generatedaccesskey | jq -r '.AccessKey.AccessKeyId')
secret_key=$(echo $generatedaccesskey | jq -r '.AccessKey.SecretAccessKey')

#create elastic ip
elasticip=$(aws ec2 allocate-address --domain vpc --region $region)

#create network interface
networkinterface=$(aws ec2 create-network-interface --subnet-id $subnetid --description "static" --groups $groupid --region $region)

#associate elastic ip
associateelasticip=$(aws ec2 associate-address --allocation-id $(echo $elasticip | jq -r '.AllocationId') --network-interface-id $(echo $networkinterface | jq -r '.NetworkInterface.NetworkInterfaceId') --private-ip-address $(echo $networkinterface | jq -r '.NetworkInterface.PrivateIpAddress') --region $region)

#attach network interface
attachnetworkinterface=$(aws ec2 attach-network-interface --network-interface-id $(echo $networkinterface | jq -r '.NetworkInterface.NetworkInterfaceId') --instance-id $instance_id --device-index 1 --region $region)

#add security group rules
aws ec2 authorize-security-group-ingress --group-id $groupid --protocol all --cidr 0.0.0.0/0 --region $region

echo "curl https://raw.githubusercontent.com/ilyasbit/all-about-cpu-mining/muter/setup-instance | bash -s -- --port \"$port\" --instance_id \"$instance_id\" --access_key \"$access_key\" --secret_key \"$secret_key\" --region \"$region\" --nic_static \"$(echo $networkinterface | jq -r '.NetworkInterface.NetworkInterfaceId')\"" > setup-${instance_id}.sh

ssh -i $keypair root@$instance_public_ip 'bash -s' < setup-${instance_id}.sh

#setup-${instance_id}.sh | ssh root@$instance_public_ip -i $keypair"
#cat setup-${instance_id}.sh | ssh root@$instance_public_ip -i $keypair
