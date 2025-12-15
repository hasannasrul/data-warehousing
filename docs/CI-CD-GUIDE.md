# CI/CD Configuration Summary

## GitHub Actions Workflows

This project uses GitHub Actions for continuous integration and continuous deployment.

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD Pipeline                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  1. Code Push/PR                                                     │
│     ↓                                                                 │
│  2. Validate (Parallel)                                              │
│     ├─ validate.yml (Python linting, tests)                         │
│     ├─ cloudformation-lint.yml (CloudFormation templates)            │
│     ├─ dag-syntax-check.yml (Airflow DAG parsing)                   │
│     └─ security-scan.yml (Secrets, vulnerabilities)                  │
│     ↓                                                                 │
│  3. Branch Protection Checks                                         │
│     ├─ All tests must pass                                           │
│     ├─ Code review required                                          │
│     └─ Status checks required                                        │
│     ↓                                                                 │
│  4. Merge to develop                                                 │
│     ↓                                                                 │
│  5. Deploy to Dev (Automatic)                                        │
│     └─ deploy-dev.yml (CloudFormation + DAG upload)                 │
│     ↓                                                                 │
│  6. Manual Approval                                                  │
│     ↓                                                                 │
│  7. Deploy to Prod (Manual)                                          │
│     └─ deploy-prod.yml (Production deployment)                      │
│     ↓                                                                 │
│  8. Release (Tag Push)                                               │
│     └─ release.yml (GitHub Release + Artifacts)                     │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Workflow Files

| File                      | Purpose                      | Trigger                 |
| ------------------------- | ---------------------------- | ----------------------- |
| `validate.yml`            | Python validation (3.9-3.11) | Push/PR to main/develop |
| `cloudformation-lint.yml` | CloudFormation validation    | CloudFormation changes  |
| `security-scan.yml`       | Security scanning            | Push/PR + Weekly        |
| `dag-syntax-check.yml`    | DAG validation               | DAG changes             |
| `deploy-dev.yml`          | Dev deployment               | Push to develop         |
| `deploy-prod.yml`         | Prod deployment              | Manual dispatch         |
| `release.yml`             | Release management           | Version tag push        |

## Setting Up GitHub Actions

### Step 1: Enable GitHub Actions

1. Go to repository settings
2. Navigate to Actions
3. Click "Enable GitHub Actions"

### Step 2: Configure AWS OIDC (Recommended)

**In AWS Account**:

```bash
# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create IAM role for GitHub Actions
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:GITHUB_ORG/GITHUB_REPO:ref:refs/heads/*"
          }
        }
      }
    ]
  }'

# Attach policies to role
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess  # Or more restrictive policy
```

### Step 3: Add GitHub Secrets

1. Go to repository Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Add the following secrets:

```
Name: AWS_ROLE_TO_ASSUME
Value: arn:aws:iam::DEV_ACCOUNT_ID:role/GitHubActionsRole

Name: AWS_ROLE_TO_ASSUME_PROD
Value: arn:aws:iam::PROD_ACCOUNT_ID:role/GitHubActionsRole
```

### Step 4: Configure Branch Protection

1. Go to repository Settings > Branches
2. Click "Add branch protection rule"
3. Configure:
   - Branch name pattern: `main`
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass
   - ✅ Require branches to be up to date
   - ✅ Require code reviews before merging (1 reviewer)
   - ✅ Dismiss stale pull request approvals

### Step 5: Add CODEOWNERS

Create `.github/CODEOWNERS`:

```
* @your-username
/cloudformation/ @devops-team
/dags/ @data-team
```

## Workflow Usage

### Running Validations

Validations run automatically on:

- Every push to `main` or `develop`
- Every pull request to `main` or `develop`

**View results**:

1. Go to repository
2. Click "Actions" tab
3. Select workflow
4. Click commit to see details

### Deploying to Development

Development deployment runs automatically when code is merged to `develop`:

1. All validations pass ✅
2. Code review approved ✅
3. Merge to develop → Deploy starts
4. Check Actions tab for deployment progress

### Deploying to Production

Production deployment requires manual approval:

1. Go to Actions tab
2. Select "Deploy to Production"
3. Click "Run workflow"
4. Select parameters:
   - `separate_buckets`: yes/no
5. Click "Run workflow"
6. Confirm deployment

### Creating Releases

```bash
# Tag a version
git tag v1.0.0
git push origin v1.0.0

# Release workflow runs automatically
# Creates GitHub Release with artifacts
```

## Cost Considerations

- **Free**: Public repositories get unlimited free Actions minutes
- **Paid**: Private repositories get 2,000 minutes/month (free tier)
- **Optimization**:
  - Cache dependencies to reduce run time
  - Parallel matrix testing
  - Reusable workflows to share code

## Monitoring and Debugging

### View Workflow Logs

1. Go to Actions tab
2. Click on workflow run
3. Click on job to see detailed logs
4. Search for errors with Ctrl+F

### Common Issues

| Issue                       | Solution                              |
| --------------------------- | ------------------------------------- |
| AWS credentials error       | Check OIDC provider and trust policy  |
| Tests timeout               | Increase timeout in workflow          |
| DAG parsing fails           | Check Python version and imports      |
| CloudFormation deploy fails | Check parameter values and AWS quotas |

### Debug Mode

Enable debug logging in GitHub Actions:

1. Go to repository Settings > Secrets
2. Add secret: `ACTIONS_STEP_DEBUG` = `true`
3. Re-run workflow

Logs will show additional debug information.

## Security Best Practices

- ✅ Use OIDC instead of long-lived credentials
- ✅ Limit IAM role permissions (least privilege)
- ✅ Scan for hardcoded secrets with Bandit
- ✅ Check dependencies with Safety
- ✅ Use branch protection rules
- ✅ Require code reviews
- ✅ Monitor workflow execution logs
- ✅ Regular security audits

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS OIDC Provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [GitHub Actions Security Guide](https://docs.github.com/en/actions/security-guides)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
