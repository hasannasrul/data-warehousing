# GitHub Actions Quick Reference

## Workflow Files Location

```
.github/workflows/
├── validate.yml                    # Code validation & testing
├── cloudformation-lint.yml         # CloudFormation template lint
├── security-scan.yml               # Security scanning
├── dag-syntax-check.yml            # Airflow DAG validation
├── deploy-dev.yml                  # Development deployment
├── deploy-prod.yml                 # Production deployment
├── release.yml                     # Release management
└── README.md                       # Detailed workflow documentation
```

## Workflow Status Badges

Add these to your README.md:

```markdown
[![Validate Code](https://github.com/username/repo/actions/workflows/validate.yml/badge.svg)](https://github.com/username/repo/actions/workflows/validate.yml)
[![CloudFormation Lint](https://github.com/username/repo/actions/workflows/cloudformation-lint.yml/badge.svg)](https://github.com/username/repo/actions/workflows/cloudformation-lint.yml)
[![Security Scan](https://github.com/username/repo/actions/workflows/security-scan.yml/badge.svg)](https://github.com/username/repo/actions/workflows/security-scan.yml)
[![DAG Syntax Check](https://github.com/username/repo/actions/workflows/dag-syntax-check.yml/badge.svg)](https://github.com/username/repo/actions/workflows/dag-syntax-check.yml)
```

## Quick Commands

### Test Locally Before Pushing

```bash
# Format code
black dags/ scripts/ utils/
isort dags/ scripts/ utils/

# Run tests
pytest tests/ -v --cov

# Check linting
flake8 dags/ scripts/ utils/ --max-line-length=120

# Validate CloudFormation
cfn-lint cloudformation/*.yaml

# Parse DAG
python -c "from dags.big_data_processing_dag import dag; print(dag.dag_id)"
```

### GitHub Actions Setup (One-time)

```bash
# 1. Enable GitHub Actions in repository settings
# 2. Create AWS OIDC provider
# 3. Create IAM role with CloudFormation permissions
# 4. Add secrets to GitHub:
#    - AWS_ROLE_TO_ASSUME=arn:aws:iam::ACCOUNT:role/GitHubActionsRole
#    - AWS_ROLE_TO_ASSUME_PROD=arn:aws:iam::PROD_ACCOUNT:role/GitHubActionsRole

# 5. Configure branch protection on 'main'
# 6. Create .github/CODEOWNERS file
```

### Common Workflow Triggers

```bash
# Push to develop → Runs validation & deploys to dev
git checkout develop
git commit -m "feature: add new functionality"
git push origin develop

# Create PR to main → Runs validation
git checkout -b feature/my-feature
git commit -m "Add feature"
git push origin feature/my-feature
# Create pull request on GitHub

# Deploy to prod → Manual workflow dispatch
# GitHub → Actions → Deploy to Production → Run workflow

# Create release → Push version tag
git tag v1.0.0
git push origin v1.0.0
```

## Workflow Details

### validate.yml

- **Trigger**: Push/PR to main/develop
- **Duration**: ~5-10 minutes
- **Tests**: Python 3.9, 3.10, 3.11
- **Checks**: Formatting, imports, linting, unit tests, coverage

### cloudformation-lint.yml

- **Trigger**: Changes to cloudformation/
- **Duration**: ~2-3 minutes
- **Validates**: YAML syntax, CloudFormation best practices

### security-scan.yml

- **Trigger**: Push/PR to main/develop, weekly schedule
- **Duration**: ~3-5 minutes
- **Scans**: Hardcoded secrets, dependency vulnerabilities

### dag-syntax-check.yml

- **Trigger**: Changes to dags/
- **Duration**: ~2-3 minutes
- **Validates**: DAG parsing, imports, syntax

### deploy-dev.yml

- **Trigger**: Push to develop
- **Duration**: ~30-40 minutes (MWAA takes time)
- **Actions**: Deploy CloudFormation stacks, upload DAGs

### deploy-prod.yml

- **Trigger**: Manual workflow dispatch
- **Duration**: ~30-40 minutes
- **Requires**: Separate AWS account/role
- **Options**: Separate buckets (yes/no)

### release.yml

- **Trigger**: Push version tag (v\*)
- **Duration**: ~2-3 minutes
- **Actions**: Create GitHub release, upload artifacts

## Status Checks Required for Merge

All of these must pass before merging to main:

- [x] Validate Code
- [x] CloudFormation Lint
- [x] Security Scan
- [x] DAG Syntax Check
- [x] Code Review (1 approver)

## Environment Variables in Workflows

### validate.yml

```yaml
AIRFLOW_HOME: ${{ github.workspace }}
AIRFLOW__CORE__DAGS_FOLDER: ${{ github.workspace }}/dags
AIRFLOW__CORE__LOAD_EXAMPLES: "False"
AIRFLOW__CORE__UNIT_TEST_MODE: "True"
```

### deploy-dev.yml

```yaml
ENVIRONMENT: dev
SEPARATE_BUCKETS: "no"
AWS_REGION: us-east-1
```

### deploy-prod.yml

```yaml
ENVIRONMENT: prod
SEPARATE_BUCKETS: ${{ github.event.inputs.separate_buckets }}
AWS_REGION: us-east-1
```

## Secrets Required

Add these to GitHub Settings → Secrets:

```
AWS_ROLE_TO_ASSUME         # Dev account role ARN
AWS_ROLE_TO_ASSUME_PROD    # Prod account role ARN
```

## Viewing Logs

1. Go to repository → Actions tab
2. Click on workflow run
3. Click on job name
4. Expand each step to see logs
5. Search with Ctrl+F

## Troubleshooting

### Workflow won't run

- Check GitHub Actions enabled in settings
- Verify branch name matches trigger conditions
- Check for syntax errors in workflow file

### Tests fail

- Run tests locally: `pytest tests/ -v`
- Check Python version matches workflow
- Verify dependencies in requirements.txt

### Deployment fails

- Check AWS credentials (OIDC provider setup)
- Verify IAM role has CloudFormation permissions
- Check CloudFormation stack events in AWS console
- Review deployment log artifacts

### CloudFormation validation fails

- Use `cfn-lint cloudformation/*.yaml` locally
- Check parameter values
- Verify resource names don't conflict with existing stacks

## Performance Optimization

- Cache pip dependencies (30-60 seconds saved)
- Use matrix testing for parallel Python versions
- Only deploy on develop/main changes
- Skip expensive tests in PRs with `@pytest.mark.slow`

## Cost Savings

- Free for public repositories (unlimited minutes)
- Free tier: 2,000 minutes/month for private repos
- Caching reduces run time
- Matrix testing is parallelized, not sequential

## Next Steps

1. ✅ Review `.github/workflows/` files
2. ✅ Update workflows with your AWS account IDs
3. ✅ Create AWS OIDC provider and IAM roles
4. ✅ Add GitHub secrets
5. ✅ Configure branch protection rules
6. ✅ Push a test commit to verify workflows run
7. ✅ Check Actions tab for workflow results

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [AWS OIDC Configuration](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
