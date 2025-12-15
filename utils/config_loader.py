"""
Configuration loader utility
"""
import yaml
import os
import logging
from typing import Dict, Any, Optional
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ConfigLoader:
    """Helper class to load and manage configuration"""

    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize configuration loader

        Args:
            config_path: Path to config.yaml file. If None, searches in default locations
        """
        self.config_path = config_path or self._find_config_file()
        self.config = self._load_config()
        self.environment = os.getenv('ENVIRONMENT', 'development')

    def _find_config_file(self) -> str:
        """
        Find config.yaml file in standard locations

        Returns:
            Path to config file
        """
        possible_paths = [
            'config/config.yaml',
            '../config/config.yaml',
            '/opt/airflow/config/config.yaml',
            os.path.join(os.path.dirname(__file__), '../config/config.yaml')
        ]

        for path in possible_paths:
            if os.path.exists(path):
                logger.info(f"Found config file at: {path}")
                return path

        # Default fallback
        default_path = 'config/config.yaml'
        logger.warning(
            f"Config file not found, using default path: {default_path}")
        return default_path

    def _load_config(self) -> Dict[str, Any]:
        """
        Load configuration from YAML file

        Returns:
            Configuration dictionary
        """
        try:
            with open(self.config_path, 'r') as f:
                config = yaml.safe_load(f)
            logger.info(
                f"Successfully loaded configuration from {self.config_path}")
            return config
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {self.config_path}")
            return {}
        except yaml.YAMLError as e:
            logger.error(f"Error parsing YAML configuration: {e}")
            return {}

    def get(self, key_path: str, default: Any = None) -> Any:
        """
        Get configuration value using dot notation

        Args:
            key_path: Dot-separated path to config value (e.g., 'aws.region')
            default: Default value if key not found

        Returns:
            Configuration value
        """
        keys = key_path.split('.')
        value = self.config

        try:
            for key in keys:
                value = value[key]
            return value
        except (KeyError, TypeError):
            logger.warning(
                f"Configuration key not found: {key_path}, using default: {default}")
            return default

    def get_aws_config(self) -> Dict[str, Any]:
        """Get AWS configuration"""
        return self.get('aws', {})

    def get_s3_config(self) -> Dict[str, Any]:
        """Get S3 configuration"""
        return self.get('s3', {})

    def get_emr_config(self) -> Dict[str, Any]:
        """Get EMR configuration"""
        return self.get('emr', {})

    def get_spark_config(self) -> Dict[str, Any]:
        """Get Spark configuration"""
        return self.get('spark', {})

    def get_airflow_config(self) -> Dict[str, Any]:
        """Get Airflow configuration"""
        return self.get('airflow', {})

    def get_environment_config(self, environment: Optional[str] = None) -> Dict[str, Any]:
        """
        Get environment-specific configuration

        Args:
            environment: Environment name (development, staging, production)
                        If None, uses value from ENVIRONMENT env var

        Returns:
            Environment-specific configuration
        """
        env = environment or self.environment
        env_config = self.get(f'environments.{env}', {})

        if not env_config:
            logger.warning(f"No configuration found for environment: {env}")

        return env_config

    def merge_environment_config(self) -> Dict[str, Any]:
        """
        Merge base config with environment-specific overrides

        Returns:
            Merged configuration dictionary
        """
        merged_config = self.config.copy()
        env_config = self.get_environment_config()

        # Deep merge environment config
        for key, value in env_config.items():
            if key in merged_config and isinstance(merged_config[key], dict) and isinstance(value, dict):
                merged_config[key].update(value)
            else:
                merged_config[key] = value

        return merged_config

    def validate_config(self) -> bool:
        """
        Validate required configuration keys are present

        Returns:
            True if configuration is valid, False otherwise
        """
        required_keys = [
            'aws.region',
            's3.bucket',
            'emr.cluster_name',
            'emr.service_role',
            'emr.job_flow_role'
        ]

        is_valid = True
        for key_path in required_keys:
            value = self.get(key_path)
            if value is None:
                logger.error(f"Required configuration missing: {key_path}")
                is_valid = False

        if is_valid:
            logger.info("Configuration validation passed")
        else:
            logger.error("Configuration validation failed")

        return is_valid

    def get_s3_paths(self) -> Dict[str, str]:
        """
        Get complete S3 paths for data locations

        Returns:
            Dictionary with input, output, scripts, and logs paths
        """
        s3_config = self.get_s3_config()
        bucket = s3_config.get('bucket', '')

        return {
            'input': f"s3://{bucket}/{s3_config.get('input_prefix', '')}",
            'output': f"s3://{bucket}/{s3_config.get('output_prefix', '')}",
            'scripts': f"s3://{bucket}/{s3_config.get('scripts_prefix', '')}",
            'logs': f"s3://{bucket}/{s3_config.get('logs_prefix', '')}"
        }

    def get_emr_job_flow_overrides(self) -> Dict[str, Any]:
        """
        Build EMR job flow configuration from config file

        Returns:
            EMR job flow overrides dictionary
        """
        emr_config = self.get_emr_config()
        aws_config = self.get_aws_config()

        job_flow_overrides = {
            'Name': emr_config.get('cluster_name', 'BigDataProcessingCluster'),
            'ReleaseLabel': emr_config.get('release_label', 'emr-6.15.0'),
            'Applications': [{'Name': app} for app in emr_config.get('applications', ['Spark', 'Hadoop'])],
            'Instances': {
                'InstanceGroups': [
                    {
                        'Name': 'Master nodes',
                        'Market': emr_config.get('master', {}).get('market', 'ON_DEMAND'),
                        'InstanceRole': 'MASTER',
                        'InstanceType': emr_config.get('master', {}).get('instance_type', 'm5.xlarge'),
                        'InstanceCount': emr_config.get('master', {}).get('instance_count', 1),
                    },
                    {
                        'Name': 'Worker nodes',
                        'Market': emr_config.get('core', {}).get('market', 'SPOT'),
                        'InstanceRole': 'CORE',
                        'InstanceType': emr_config.get('core', {}).get('instance_type', 'm5.xlarge'),
                        'InstanceCount': emr_config.get('core', {}).get('instance_count', 2),
                    }
                ],
                'KeepJobFlowAliveWhenNoSteps': True,
                'TerminationProtected': False,
            },
            'JobFlowRole': emr_config.get('job_flow_role', 'EMR_EC2_DefaultRole'),
            'ServiceRole': emr_config.get('service_role', 'EMR_DefaultRole'),
            'LogUri': emr_config.get('log_uri', ''),
            'VisibleToAllUsers': True,
        }

        # Add optional EC2 key name if specified
        if emr_config.get('ec2_key_name'):
            job_flow_overrides['Instances']['Ec2KeyName'] = emr_config.get(
                'ec2_key_name')

        # Add optional subnet if specified
        if emr_config.get('subnet_id'):
            job_flow_overrides['Instances']['Ec2SubnetId'] = emr_config.get(
                'subnet_id')

        return job_flow_overrides

    def __repr__(self) -> str:
        """String representation of ConfigLoader"""
        return f"ConfigLoader(config_path='{self.config_path}', environment='{self.environment}')"
