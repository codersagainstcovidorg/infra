#!/bin/bash
ENV=$1
REGION=${2-"us-east-1"}

# Get instance_id
INSTANCE_ID=$(aws ec2 describe-instances --filter Name=tag:Name,Values="cac-${ENV}-bastion" \
  --query 'Reservations[].Instances[].InstanceId' --region "${REGION}" \
  --output text \
)

# Get AZ
AZ=$(aws ec2 describe-instances --filter Name=tag:Name,Values="cac-${ENV}-bastion" \
  --query 'Reservations[].Instances[].Placement.AvailabilityZone' --region "${REGION}" \
  --output text \
)

# Get DB url
DB_URL=$(aws rds describe-db-cluster-endpoints --db-cluster-identifier "cac-${ENV}"\
  --query 'DBClusterEndpoints[].Endpoint' --region "${REGION}" --output text \
)

SSH_KEY_PATH=~/.ssh/temp_ssm_key
SSH_USER="ec2-user"

# generate temp key
echo -e 'y\n' | ssh-keygen -t rsa -f $SSH_KEY_PATH -N '' >/dev/null 2>&1
chmod 400 $SSH_KEY_PATH

# Send public key
aws ec2-instance-connect send-ssh-public-key \
  --instance-id "${INSTANCE_ID}" \
  --availability-zone "${AZ}" \
  --region="$REGION" \
  --instance-os-user $SSH_USER \
  --ssh-public-key file://$SSH_KEY_PATH.pub

# Bring up tunnel
ssh -i $SSH_KEY_PATH -N -M -L "5432:${DB_URL}:5432" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" \
  -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p --region=$REGION" "$SSH_USER@${INSTANCE_ID}"