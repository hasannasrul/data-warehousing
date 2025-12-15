"""
S3 Helper utilities for data operations
"""
import boto3
import logging
from typing import List, Dict, Optional
from botocore.exceptions import ClientError

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class S3Helper:
    """Helper class for S3 operations"""

    def __init__(self, region_name: str = 'us-east-1'):
        """
        Initialize S3 client

        Args:
            region_name: AWS region name
        """
        self.s3_client = boto3.client('s3', region_name=region_name)
        self.s3_resource = boto3.resource('s3', region_name=region_name)

    def list_objects(self, bucket: str, prefix: str = '', max_keys: int = 1000) -> List[Dict]:
        """
        List objects in S3 bucket

        Args:
            bucket: S3 bucket name
            prefix: Object prefix/path
            max_keys: Maximum number of keys to return

        Returns:
            List of object metadata dictionaries
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix,
                MaxKeys=max_keys
            )

            if 'Contents' in response:
                objects = response['Contents']
                logger.info(
                    f"Found {len(objects)} objects in s3://{bucket}/{prefix}")
                return objects
            else:
                logger.warning(f"No objects found in s3://{bucket}/{prefix}")
                return []

        except ClientError as e:
            logger.error(f"Error listing objects: {e}")
            raise

    def upload_file(self, local_path: str, bucket: str, s3_key: str) -> bool:
        """
        Upload file to S3

        Args:
            local_path: Local file path
            bucket: S3 bucket name
            s3_key: S3 object key

        Returns:
            True if successful, False otherwise
        """
        try:
            self.s3_client.upload_file(local_path, bucket, s3_key)
            logger.info(f"Uploaded {local_path} to s3://{bucket}/{s3_key}")
            return True
        except ClientError as e:
            logger.error(f"Error uploading file: {e}")
            return False

    def download_file(self, bucket: str, s3_key: str, local_path: str) -> bool:
        """
        Download file from S3

        Args:
            bucket: S3 bucket name
            s3_key: S3 object key
            local_path: Local file path to save

        Returns:
            True if successful, False otherwise
        """
        try:
            self.s3_client.download_file(bucket, s3_key, local_path)
            logger.info(f"Downloaded s3://{bucket}/{s3_key} to {local_path}")
            return True
        except ClientError as e:
            logger.error(f"Error downloading file: {e}")
            return False

    def delete_objects(self, bucket: str, keys: List[str]) -> bool:
        """
        Delete multiple objects from S3

        Args:
            bucket: S3 bucket name
            keys: List of S3 object keys to delete

        Returns:
            True if successful, False otherwise
        """
        try:
            objects = [{'Key': key} for key in keys]
            response = self.s3_client.delete_objects(
                Bucket=bucket,
                Delete={'Objects': objects}
            )

            deleted = len(response.get('Deleted', []))
            logger.info(f"Deleted {deleted} objects from s3://{bucket}")
            return True
        except ClientError as e:
            logger.error(f"Error deleting objects: {e}")
            return False

    def object_exists(self, bucket: str, key: str) -> bool:
        """
        Check if object exists in S3

        Args:
            bucket: S3 bucket name
            key: S3 object key

        Returns:
            True if object exists, False otherwise
        """
        try:
            self.s3_client.head_object(Bucket=bucket, Key=key)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                return False
            else:
                logger.error(f"Error checking object existence: {e}")
                raise

    def get_object_size(self, bucket: str, key: str) -> Optional[int]:
        """
        Get size of S3 object in bytes

        Args:
            bucket: S3 bucket name
            key: S3 object key

        Returns:
            Object size in bytes, or None if error
        """
        try:
            response = self.s3_client.head_object(Bucket=bucket, Key=key)
            size = response['ContentLength']
            logger.info(f"Object s3://{bucket}/{key} size: {size} bytes")
            return size
        except ClientError as e:
            logger.error(f"Error getting object size: {e}")
            return None

    def copy_object(self, source_bucket: str, source_key: str,
                    dest_bucket: str, dest_key: str) -> bool:
        """
        Copy object within S3

        Args:
            source_bucket: Source bucket name
            source_key: Source object key
            dest_bucket: Destination bucket name
            dest_key: Destination object key

        Returns:
            True if successful, False otherwise
        """
        try:
            copy_source = {'Bucket': source_bucket, 'Key': source_key}
            self.s3_client.copy_object(
                CopySource=copy_source,
                Bucket=dest_bucket,
                Key=dest_key
            )
            logger.info(
                f"Copied s3://{source_bucket}/{source_key} to s3://{dest_bucket}/{dest_key}")
            return True
        except ClientError as e:
            logger.error(f"Error copying object: {e}")
            return False

    def get_total_size(self, bucket: str, prefix: str = '') -> int:
        """
        Calculate total size of all objects under a prefix

        Args:
            bucket: S3 bucket name
            prefix: Object prefix/path

        Returns:
            Total size in bytes
        """
        total_size = 0
        try:
            paginator = self.s3_client.get_paginator('list_objects_v2')
            pages = paginator.paginate(Bucket=bucket, Prefix=prefix)

            for page in pages:
                if 'Contents' in page:
                    for obj in page['Contents']:
                        total_size += obj['Size']

            logger.info(
                f"Total size for s3://{bucket}/{prefix}: {total_size} bytes ({total_size / 1024 / 1024:.2f} MB)")
            return total_size
        except ClientError as e:
            logger.error(f"Error calculating total size: {e}")
            return 0

    def create_presigned_url(self, bucket: str, key: str, expiration: int = 3600) -> Optional[str]:
        """
        Generate presigned URL for S3 object

        Args:
            bucket: S3 bucket name
            key: S3 object key
            expiration: URL expiration time in seconds (default 1 hour)

        Returns:
            Presigned URL string, or None if error
        """
        try:
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': bucket, 'Key': key},
                ExpiresIn=expiration
            )
            logger.info(f"Generated presigned URL for s3://{bucket}/{key}")
            return url
        except ClientError as e:
            logger.error(f"Error generating presigned URL: {e}")
            return None

    def validate_bucket_access(self, bucket: str) -> bool:
        """
        Validate access to S3 bucket

        Args:
            bucket: S3 bucket name

        Returns:
            True if bucket is accessible, False otherwise
        """
        try:
            self.s3_client.head_bucket(Bucket=bucket)
            logger.info(f"Successfully validated access to bucket: {bucket}")
            return True
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                logger.error(f"Bucket {bucket} does not exist")
            elif error_code == '403':
                logger.error(f"Access denied to bucket {bucket}")
            else:
                logger.error(f"Error validating bucket access: {e}")
            return False
