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
* `bastion` - Bastion server per env for an ssh tunnel
* `csv_processor` - A lambda pipeline to watch for files in s3 to process, convert csv into json and insert into API
* `database` - RDS and related resources
* `frontend` - Cloudfront, S3, all resources to get the frontend running
* `kms` - KMS resources
* `route53` - All resources to create hosted zones, dns records, etc
* `vpc` - All resources for launching VPC components
* `website` - All resources for launching website components

## Usage
Very WIP for MVP launch

Each folder under the `terraform` directory is a component consisting of a module and config. To apply the config, run `beatcovid19.sh` and supply the component and environment as arguments.

It will init, run a plan, and ask for confirmation. If the plan looks good, you can accept and it will use that exact plan to apply changes.

Ex. To deploy the frontend infra (S3, Cloudfront, etc)
```
./beatcovid19.sh frontend staging|production
```

## Using the Bastion

Prerequisites: 

- AWS CLI 
- [Install Session Manager Plugin for the AWS CLI](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- Correct IAM permissions for your identity - [see here for more information](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Connect-using-EC2-Instance-Connect.html)

```
./scripts/start-tunnel.sh <environment>
```

### Loading PostGIS extension
Simply execute the SQL in `sql/load_postgis_extension.sql` as master user after the database has been created
