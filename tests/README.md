# Unit Tests

This directory contains unit tests for the Big Data Processing project.

## Test Structure

```
tests/
├── __init__.py
├── test_big_data_processing_dag.py    # DAG tests
├── test_utils.py                       # Utility function tests
└── conftest.py                         # Pytest configuration
```

## Running Tests

### Run all tests

```bash
pytest tests/ -v
```

### Run specific test file

```bash
pytest tests/test_big_data_processing_dag.py -v
```

### Run specific test

```bash
pytest tests/test_big_data_processing_dag.py::TestBigDataProcessingDAG::test_dag_exists -v
```

### Run with coverage

```bash
pytest tests/ --cov=dags --cov=scripts --cov=utils --cov-report=html -v
```

### Run with markers

```bash
# Run only fast tests
pytest tests/ -m "not slow" -v

# Run only AWS tests
pytest tests/ -m "aws" -v
```

## Writing Tests

### Test Naming

- Test files: `test_*.py`
- Test classes: `Test*`
- Test functions: `test_*`

### Test Structure

```python
import pytest

class TestMyFeature:
    """Test cases for my feature"""

    def test_something_works(self):
        """Test description"""
        # Arrange
        input_data = "test"

        # Act
        result = my_function(input_data)

        # Assert
        assert result == "expected"

    def test_error_handling(self):
        """Test error cases"""
        with pytest.raises(ValueError):
            my_function("invalid")
```

### Using Fixtures

```python
@pytest.fixture
def sample_data():
    """Provide sample data for tests"""
    return {
        'id': 1,
        'name': 'test',
    }

def test_with_fixture(sample_data):
    """Test using fixture"""
    assert sample_data['id'] == 1
```

### Mocking AWS Services

```python
from unittest.mock import MagicMock, patch

@patch('boto3.client')
def test_s3_operation(mock_s3):
    """Test S3 operation with mock"""
    mock_client = MagicMock()
    mock_s3.return_value = mock_client
    mock_client.list_objects.return_value = {'Contents': []}

    # Test your code
    # assert ...
```

## Test Coverage

Target coverage: **> 80%**

View coverage report:

```bash
pytest tests/ --cov=dags --cov=scripts --cov=utils --cov-report=html
open htmlcov/index.html
```

## Continuous Integration

Tests run automatically in GitHub Actions:

- On every push to `main` or `develop`
- On every pull request
- Matrix testing for Python 3.9, 3.10, 3.11
- Coverage reports uploaded to Codecov

## Best Practices

✅ **Do**:

- Write descriptive test names
- Test both happy path and error cases
- Use fixtures for reusable test data
- Mock external dependencies (AWS, databases)
- Keep tests fast and independent
- Group related tests in classes

❌ **Don't**:

- Test implementation details, test behavior
- Use `test_` prefix for helper functions
- Make tests dependent on external services
- Have slow tests without `@pytest.mark.slow`
- Skip tests without good reason

## Debugging Tests

```bash
# Show print statements
pytest tests/ -s -v

# Stop on first failure
pytest tests/ -x

# Show local variables on failure
pytest tests/ -l

# Drop into debugger on failure
pytest tests/ --pdb
```

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Pytest Fixtures](https://docs.pytest.org/en/stable/fixture.html)
- [Unit Testing Best Practices](https://docs.pytest.org/en/latest/goodpractices.html)
