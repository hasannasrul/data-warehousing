---
name: Infrastructure Issue
about: Report infrastructure or DevOps related issues
title: "[INFRA] Brief description"
labels: infrastructure
assignees: ""
---

## Description

A clear and concise description of the infrastructure issue.

## Affected Components

- [ ] VPC Configuration
- [ ] CloudFormation Templates
- [ ] IAM Roles/Policies
- [ ] S3 Buckets
- [ ] MWAA Environment
- [ ] EMR Cluster
- [ ] Security Groups
- [ ] Other: \_\_\_\_

## CloudFormation Stack

Which CloudFormation stack is affected?

- [ ] 01-vpc-infrastructure.yaml
- [ ] 02-iam-roles.yaml
- [ ] 03-s3-buckets.yaml
- [ ] 04-mwaa-environment.yaml

## Environment

- AWS Region: [e.g., us-east-1]
- Environment: [dev/staging/prod]
- Account ID: [masked]

## Error Messages

```
Paste any CloudFormation events or error messages
```

## Steps to Reproduce

1. Deploy CloudFormation stack
2. ...
3. See error

## Expected Behavior

What should happen

## Actual Behavior

What actually happened

## Deployment Output

```
Include relevant CloudFormation events or CLI output
```

## Suggested Fix

If you have a solution in mind, describe it here.

## Related Issues

Link to related issues: #issue_number
