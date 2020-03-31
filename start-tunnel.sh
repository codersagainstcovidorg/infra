INSTANCE_ID=$1
AZ=$2
DB_URL=$3

echo -e 'y\n' | ssh-keygen -t rsa -f ~/.ssh/temp_ssm_key -N '' >/dev/null 2>&1
aws ec2-instance-connect send-ssh-public-key --instance-id ${INSTANCE_ID} --availability-zone ${AZ} --region=us-east-1 --instance-os-user ubuntu --ssh-public-key file://~/.ssh/temp_ssm_key.pub
chmod 400 ~/.ssh/temp_ssm_key
ssh -i ~/.ssh/temp_ssm_key -Nf -M -L 5432:${DB_URL}:5432 -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" \
 -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p --region=us-east-1" ubuntu@${INSTANCE_ID}