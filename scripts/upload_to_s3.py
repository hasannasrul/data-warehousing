"""
Script to upload files to S3
"""
from utils.config_loader import ConfigLoader
from utils.s3_helper import S3Helper
import argparse
import os
import sys
from pathlib import Path

# Add parent directory to path to import utils
sys.path.append(str(Path(__file__).parent.parent))


def upload_directory_to_s3(local_dir: str, bucket: str, s3_prefix: str):
    """
    Upload directory contents to S3

    Args:
        local_dir: Local directory path
        bucket: S3 bucket name
        s3_prefix: S3 prefix/folder
    """
    s3_helper = S3Helper()

    print(f"Uploading files from {local_dir} to s3://{bucket}/{s3_prefix}")

    uploaded_count = 0
    failed_count = 0

    for root, dirs, files in os.walk(local_dir):
        for file in files:
            local_path = os.path.join(root, file)
            relative_path = os.path.relpath(local_path, local_dir)
            s3_key = os.path.join(s3_prefix, relative_path).replace('\\', '/')

            if s3_helper.upload_file(local_path, bucket, s3_key):
                uploaded_count += 1
            else:
                failed_count += 1

    print(f"\nUpload complete:")
    print(f"  Uploaded: {uploaded_count} files")
    print(f"  Failed: {failed_count} files")


def main():
    parser = argparse.ArgumentParser(description='Upload files to S3')
    parser.add_argument('--local-path', required=True,
                        help='Local file or directory path')
    parser.add_argument(
        '--bucket', help='S3 bucket name (from config if not provided)')
    parser.add_argument('--s3-prefix', required=True, help='S3 prefix/folder')
    parser.add_argument('--config', help='Path to config file')

    args = parser.parse_args()

    # Load configuration if bucket not provided
    bucket = args.bucket
    if not bucket:
        config_loader = ConfigLoader(args.config)
        s3_config = config_loader.get_s3_config()
        bucket = s3_config.get('bucket')

        if not bucket:
            print("Error: S3 bucket not specified and not found in config")
            sys.exit(1)

    # Upload file or directory
    if os.path.isfile(args.local_path):
        s3_helper = S3Helper()
        filename = os.path.basename(args.local_path)
        s3_key = os.path.join(args.s3_prefix, filename).replace('\\', '/')

        if s3_helper.upload_file(args.local_path, bucket, s3_key):
            print(
                f"Successfully uploaded {args.local_path} to s3://{bucket}/{s3_key}")
        else:
            print("Upload failed")
            sys.exit(1)

    elif os.path.isdir(args.local_path):
        upload_directory_to_s3(args.local_path, bucket, args.s3_prefix)

    else:
        print(f"Error: {args.local_path} is not a valid file or directory")
        sys.exit(1)


if __name__ == '__main__':
    main()
