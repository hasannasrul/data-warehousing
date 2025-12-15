"""
Unit tests for big_data_processing DAG
"""
from big_data_processing_dag import dag, validate_input_data, notify_completion
import os
import sys
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch

import pytest

# Add dags directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../dags'))


class TestBigDataProcessingDAG:
    """Test cases for Big Data Processing DAG"""

    def test_dag_exists(self):
        """Test that DAG is defined"""
        assert dag is not None
        assert dag.dag_id == 'big_data_processing_pipeline'

    def test_dag_has_correct_tasks(self):
        """Test that DAG contains all expected tasks"""
        expected_tasks = [
            'list_s3_input_files',
            'validate_input_data',
            'create_emr_cluster',
            'add_spark_processing_step',
            'wait_for_spark_step',
            'terminate_emr_cluster',
            'notify_completion',
        ]
        actual_tasks = [task.task_id for task in dag.tasks]

        for expected_task in expected_tasks:
            assert expected_task in actual_tasks, f"Task {expected_task} not found in DAG"

    def test_dag_schedule_interval(self):
        """Test that DAG has correct schedule interval"""
        assert dag.schedule_interval == '@daily'

    def test_dag_catchup_disabled(self):
        """Test that catchup is disabled"""
        assert dag.catchup is False

    def test_validate_input_data_returns_true(self):
        """Test validate_input_data function"""
        result = validate_input_data()
        assert result is True

    def test_notify_completion_returns_true(self):
        """Test notify_completion function"""
        context = {
            'ti': MagicMock(),
            'execution_date': datetime.now(),
        }
        result = notify_completion(**context)
        assert result is True

    @patch.dict(os.environ, {'DATA_BUCKET_NAME': 'test-bucket'})
    def test_configuration_from_environment(self):
        """Test that configuration is read from environment variables"""
        from big_data_processing_dag import get_config

        bucket_name = get_config('DATA_BUCKET_NAME', 'default')
        assert bucket_name == 'test-bucket'

    @patch.dict(os.environ, {}, clear=True)
    def test_configuration_defaults(self):
        """Test that default configuration is used when env vars not set"""
        from big_data_processing_dag import get_config

        bucket_name = get_config('DATA_BUCKET_NAME', 'default')
        assert bucket_name == 'default'


class TestDAGDependencies:
    """Test task dependencies"""

    def test_task_dependencies_chain(self):
        """Test that tasks are properly chained"""
        task_ids = {task.task_id: task for task in dag.tasks}

        # Verify dependencies
        list_tasks = task_ids['list_s3_input_files'].downstream_list
        assert task_ids['validate_input_data'] in list_tasks

        validate_tasks = task_ids['validate_input_data'].downstream_list
        assert task_ids['create_emr_cluster'] in validate_tasks


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
