# CAC Terraform

This has some MVP prelim code to launch the infra resources for CAC

This has quick code to launch frontend and backend resources. 

## Requirements
TF > 0.12.24

## Overview
Environments: 

* `staging` 
* `production`

Components:

* `backend` - Fargate and other ecs resources for backend api
* `kms` - KMS resources
* `frontend` - Cloudfront, S3, all resources to get the frontend running
* `route53` - All resources to create hosted zones, dns records, etc
* `vpc` - All resources for launching VPC components
* `database` - RDS and related resources

## Usage
Very WIP for MVP launch

Each folder under the `terraform` directory is a component consisting of a module and config. To apply the config, run `beatcovid19.sh` and supply the component and environment as arguments.

It will init, run a plan, and ask for confirmation. If the plan looks good, you can accept and it will use that exact plan to apply changes.

Ex. To deploy the frontend infra (S3, Cloudfront, etc)
```
./beatcovid19.sh frontend staging|production
```

## Using the Bastion

Prerequsites: 

- AWS CLI 
- (Optional) [Install Session Manager Plugin for the AWS CLI](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

Create a keypair: 
`echo -e 'y\n' | ssh-keygen -t rsa -f ~/.ssh/temp_ssm_key -N '' >/dev/null 2>&1`

Send public key to EC2 instance: 
`aws ec2-instance-connect send-ssh-public-key --instance-id ${INSTANCE_ID} --availability-zone ${AZ} --region=us-east-1 --instance-os-user ubuntu --ssh-public-key file://~/.ssh/temp_ssm_key.pub`

Ensure correct permissions on key: 
`chmod 400 ~/.ssh/temp_ssm_key`

Establish Tunnel via SSM: 
`ssh -i ~/.ssh/temp_ssm_key -Nf -M -L 5432:${DB_URL}:5432 -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" \
 -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p --region=us-east-1" ubuntu@${INSTANCE_ID}`
 
Kill Tunnel: 
`kill $(lsof -t -i :5432)`
