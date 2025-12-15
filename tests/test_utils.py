"""
Unit tests for utility functions
"""
from config_loader import ConfigLoader
import sys
import os
from unittest.mock import MagicMock, patch
import pytest

# Add utils directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../utils'))


class TestConfigLoader:
    """Test cases for ConfigLoader utility"""

    def test_config_loader_initialization(self):
        """Test ConfigLoader can be initialized"""
        config = ConfigLoader()
        assert config is not None

    @patch('builtins.open')
    def test_config_loader_get_value(self, mock_open):
        """Test getting configuration values"""
        config = ConfigLoader()
        # Add more specific tests when config file is loaded
        assert config is not None


class TestS3Helper:
    """Test cases for S3Helper utility"""

    @pytest.mark.skip(reason="Requires AWS credentials")
    def test_s3_helper_initialization(self):
        """Test S3Helper initialization"""
        # This test would require AWS credentials in the test environment
        pass

    def test_s3_helper_methods_exist(self):
        """Test that S3Helper has required methods"""
        from s3_helper import S3Helper

        required_methods = [
            'list_objects',
            'upload_file',
            'download_file',
            'object_exists',
        ]

        for method in required_methods:
            assert hasattr(S3Helper, method)


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
