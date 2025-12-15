# GitHub Actions Workflows

This directory contains the CI/CD pipeline configurations for the Big Data Processing project.

## Workflows

### 1. **validate.yml** - Code Validation

Runs on every push and pull request to validate Python code.

**Features:**

- Tests against Python 3.9, 3.10, 3.11
- Code formatting check (Black)
- Import sorting check (isort)
- Linting (Flake8)
- Code analysis (Pylint)
- Unit tests with coverage reporting
- Coverage upload to Codecov

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

### 2. **cloudformation-lint.yml** - CloudFormation Validation

Validates CloudFormation templates.

**Features:**

- CFN-Lint for template validation
- AWS CloudFormation validation (when credentials available)
- Reports template syntax errors

**Triggers:**

- Push to `cloudformation/` directory on `main` or `develop`
- Pull requests affecting CloudFormation templates

### 3. **security-scan.yml** - Security Analysis

Scans for security vulnerabilities and hardcoded secrets.

**Features:**

- Bandit for Python security issues
- Safety for dependency vulnerabilities
- Hardcoded credentials check
- Hardcoded password detection

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Weekly schedule (Sunday 00:00 UTC)

### 4. **dag-syntax-check.yml** - Airflow DAG Validation

Validates Airflow DAG syntax and dependencies.

**Features:**

- DAG syntax validation
- Airflow parsing check
- Import dependency analysis
- Task list verification

**Triggers:**

- Push to `dags/` directory on `main` or `develop`
- Pull requests affecting DAG files

### 5. **deploy-dev.yml** - Development Deployment

Deploys infrastructure to development environment.

**Features:**

- CloudFormation validation
- Infrastructure deployment (VPC, IAM, S3, MWAA)
- DAG upload to MWAA
- Environment status verification
- Deployment report generation

**Triggers:**

- Push to `develop` branch
- Manual workflow dispatch with environment selection

**Required Secrets:**

- `AWS_ROLE_TO_ASSUME`: IAM role ARN for development account

### 6. **deploy-prod.yml** - Production Deployment

Deploys infrastructure to production environment (manual only).

**Features:**

- Manual approval required
- CloudFormation validation
- Production infrastructure deployment
- Resource verification
- Deployment tagging and notifications

**Triggers:**

- Manual workflow dispatch with bucket configuration option

**Required Secrets:**

- `AWS_ROLE_TO_ASSUME_PROD`: IAM role ARN for production account

### 7. **release.yml** - Release Management

Creates releases and publishes artifacts.

**Features:**

- Version extraction from git tags
- Release notes generation
- GitHub Release creation
- Artifact uploads

**Triggers:**

- Push of version tags (v\*)

## Setup Instructions

### 1. Prerequisites

- GitHub repository with Actions enabled
- AWS accounts for dev and production
- IAM roles with CloudFormation and related permissions

### 2. Configure AWS IAM Roles

For OpenID Connect (OIDC) authentication:

```bash
# Create IAM roles in dev and prod accounts
# Grant CloudFormation, S3, IAM, EMR, MWAA permissions
```

### 3. Add GitHub Secrets

In your GitHub repository settings, add:

```
AWS_ROLE_TO_ASSUME=arn:aws:iam::DEV_ACCOUNT:role/GitHubActionsRole
AWS_ROLE_TO_ASSUME_PROD=arn:aws:iam::PROD_ACCOUNT:role/GitHubActionsRole
```

### 4. Branch Protection Rules

Set up branch protection for `main`:

```
- Require status checks to pass
- Require code review (1+ reviewer)
- Dismiss stale reviews
- Require CODEOWNERS review
```

### 5. Create CODEOWNERS File

```
# .github/CODEOWNERS
* @your-username
/cloudformation/ @devops-team
/dags/ @data-team
```

## Usage Examples

### Run Validation on PR

```bash
# Create feature branch
git checkout -b feature/my-change
git commit -m "Add feature"
git push origin feature/my-change

# Create PR - validation runs automatically
```

### Deploy to Development

```bash
# Manual trigger
# Go to Actions > Deploy to Dev > Run workflow
# Select branch: develop
# Select environment: dev
```

### Deploy to Production

```bash
# Manual trigger with tag
git tag v1.0.0
git push origin v1.0.0

# Then manually deploy
# Go to Actions > Deploy to Production > Run workflow
# Select separate_buckets option
```

### Create Release

```bash
# Push version tag
git tag v1.0.0
git push origin v1.0.0

# Release workflow runs automatically
```

## Cost Optimization

- Workflows use shared runners (free for public repos)
- Cache dependencies to reduce install time
- Parallel matrix testing for Python versions
- Only deploy on specific branch changes

## Monitoring

- View workflow status in GitHub Actions tab
- Check logs for detailed output
- Monitor Codecov integration for coverage trends
- Review security scanning results

## Troubleshooting

### AWS Credentials Error

- Verify IAM role trust relationship allows GitHub
- Check OIDC provider configuration
- Confirm role has required permissions

### DAG Validation Fails

- Check Airflow dependencies in requirements.txt
- Validate Python syntax
- Review DAG import statements

### CloudFormation Deployment Fails

- Check stack naming conventions
- Verify parameter values
- Review CloudFormation events in AWS console

### Artifact Upload Fails

- Check file paths in upload step
- Verify artifact size limits
- Confirm permissions on artifacts directory
