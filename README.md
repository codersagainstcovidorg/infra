# CAC Terraform

This has some MVP prelim code to launch the infra resources for CAC

This has quick code to launch frontend and backend resources. 

## Requirements
TF > 12.22

## Overview
Environments: 

* `staging` - deploys from develop and development
* `production` - deploys from master

Components:

* `frontend` - Cloudfront, S3, all resources to get the frontend running
* `route53` - All resources to create hosted zones, dns records, etc

## Usage
Very WIP for MVP launch

Each folder under the `terraform` directory is a component consisting of a module and config. To apply the config, run `beatcovid19.sh` and supply the component and environment as arguments.

It will init, run a plan, and ask for confirmation. If the plan looks good, you can accept and it will use that exact plan to apply changes.

Ex. To deploy the frontend infra (S3, Cloudfront, etc)
```
./beatcovid19.sh frontend staging|production
```