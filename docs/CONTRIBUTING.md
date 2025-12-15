# Code Style Guide

This project follows consistent code style standards for maintainability and readability.

## Python Code Style

### PEP 8 Compliance

- Line length: 120 characters (configurable, default 88 for Black)
- Indentation: 4 spaces (no tabs)
- Two blank lines between top-level definitions
- One blank line between method definitions

### Tools

**Black** - Code formatter

```bash
# Format code
black dags/ scripts/ utils/

# Check without formatting
black --check dags/ scripts/ utils/
```

**isort** - Import sorter

```bash
# Sort imports
isort dags/ scripts/ utils/

# Check without modifying
isort --check-only dags/ scripts/ utils/
```

**Flake8** - Linter

```bash
# Check code
flake8 dags/ scripts/ utils/ --max-line-length=120
```

## Naming Conventions

### Variables and Functions

- Use `snake_case` for variables and functions
- Use descriptive names
- Avoid single-letter names except for loop counters

```python
# Good
def process_data(input_path):
    """Process data from input path."""
    file_list = get_files(input_path)
    return cleaned_data

# Bad
def pd(ip):
    """Process data."""
    fl = get_files(ip)
    return cd
```

### Classes

- Use `PascalCase` for class names
- Use `CONSTANT_CASE` for module-level constants

```python
# Good
class DataProcessor:
    MAX_RETRIES = 3

    def __init__(self):
        pass

# Bad
class data_processor:
    max_retries = 3
```

## Documentation

### Docstrings

- Use triple-quoted strings for all public modules, functions, classes, and methods
- Follow Google/NumPy docstring style

```python
def process_data(input_path, output_format='parquet'):
    """Process data from input path.

    Args:
        input_path (str): Path to input data in S3 or local filesystem
        output_format (str): Output format ('parquet' or 'csv'). Defaults to 'parquet'

    Returns:
        DataFrame: Processed data

    Raises:
        FileNotFoundError: If input_path does not exist
        ValueError: If output_format is not supported

    Example:
        >>> data = process_data('s3://bucket/data/', 'csv')
    """
    pass
```

### Comments

- Write meaningful comments for complex logic
- Explain WHY, not WHAT (code shows what)
- Keep comments up-to-date with code changes

```python
# Good
# Skip header row as it contains metadata
for line in file[1:]:
    process_line(line)

# Bad
# Skip a line
for line in file[1:]:
    process_line(line)
```

## CloudFormation Style

### YAML Formatting

- Use 2-space indentation
- Use meaningful resource names
- Always add Description for resources
- Group related resources together

```yaml
# Good
DataProcessingBucket:
  Type: AWS::S3::Bucket
  Description: S3 bucket for processed data storage
  Properties:
    BucketName: !Sub "${ProjectName}-data-${AWS::AccountId}"
    VersioningConfiguration:
      Status: Enabled

# Bad
DB:
  Type: AWS::S3::Bucket
  Properties:
    BucketName: my-bucket
```

### Parameter Naming

- Use PascalCase for parameter names
- Include description for each parameter
- Set appropriate defaults

```yaml
Parameters:
  ProjectName:
    Type: String
    Default: big-data-processing
    Description: Project name for resource naming
```

## Airflow DAG Style

### DAG Definition

- Use meaningful DAG ID
- Set appropriate `default_args`
- Add descriptive description
- Define task dependencies clearly

```python
# Good
default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'start_date': days_ago(1),
    'retries': 2,
}

with DAG(
    'big_data_processing_pipeline',
    default_args=default_args,
    description='Process big data from S3 using EMR',
    schedule_interval='@daily',
) as dag:
    pass

# Bad
dag = DAG('dag', schedule_interval='@daily')
```

### Task Naming

- Use descriptive `task_id`
- Keep task IDs under 50 characters
- Use snake_case for task IDs
- Group related tasks with naming convention

```python
# Good
list_s3_files = S3ListOperator(task_id='list_s3_input_files')
validate_data = PythonOperator(task_id='validate_input_data')
create_cluster = EmrCreateJobFlowOperator(task_id='create_emr_cluster')

# Bad
t1 = S3ListOperator(task_id='s3')
t2 = PythonOperator(task_id='validate')
t3 = EmrCreateJobFlowOperator(task_id='emr')
```

## Bash Script Style

- Use meaningful variable names in UPPERCASE
- Add comments for complex logic
- Use set -e to exit on error
- Quote all variables: `"$VAR"`
- Use double brackets for conditionals: `[[ ]]`

```bash
#!/bin/bash
set -e

# Configuration
PROJECT_NAME="big-data-processing"
ENVIRONMENT="${1:-dev}"

echo "Deploying $PROJECT_NAME to $ENVIRONMENT"

if [[ -z "$AWS_REGION" ]]; then
    echo "ERROR: AWS_REGION not set"
    exit 1
fi
```

## Testing Standards

### Unit Tests

- Filename: `test_*.py`
- Test function naming: `test_*`
- One assertion per test when possible
- Use descriptive test names

```python
# Good
def test_process_data_with_valid_input():
    """Test process_data returns DataFrame."""
    result = process_data('valid_path')
    assert isinstance(result, DataFrame)

# Bad
def test_process():
    df = process_data('valid_path')
    assert df is not None
```

## Pre-commit Hooks

Run before committing:

```bash
# Format code
black dags/ scripts/ utils/
isort dags/ scripts/ utils/

# Run tests
pytest tests/ -v

# Check linting
flake8 dags/ scripts/ utils/
```

## Resources

- [PEP 8](https://pep8.org/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [AWS CloudFormation Best Practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)
