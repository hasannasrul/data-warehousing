"""
Big Data Processing DAG for AWS MWAA
Orchestrates reading from S3, processing on EMR, and storing results back to S3
Compatible with both local Airflow and AWS Managed Workflows for Apache Airflow (MWAA)
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.amazon.aws.operators.emr import (
    EmrCreateJobFlowOperator,
    EmrAddStepsOperator,
    EmrTerminateJobFlowOperator
)
from airflow.providers.amazon.aws.sensors.emr import EmrStepSensor
from airflow.providers.amazon.aws.operators.s3 import S3ListOperator
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago
from airflow.models import Variable
import json
import os

# Get configuration from environment variables (MWAA) or Airflow Variables


def get_config(key, default=None):
    """Get configuration from environment variable or Airflow Variable"""
    return os.environ.get(key, Variable.get(key, default_var=default))


# Configuration
PROJECT_NAME = get_config('PROJECT_NAME', 'big-data-processing')
ENVIRONMENT = get_config('ENVIRONMENT', 'dev')
DATA_BUCKET = get_config('DATA_BUCKET_NAME', 'your-data-bucket')
MWAA_BUCKET = get_config('MWAA_BUCKET_NAME', 'your-mwaa-bucket')
EMR_LOGS_BUCKET = get_config('EMR_LOGS_BUCKET_NAME', 'your-emr-logs-bucket')
# Falls back to DATA_BUCKET if not set
PROCESSED_DATA_BUCKET = get_config('PROCESSED_DATA_BUCKET_NAME', DATA_BUCKET)
AWS_REGION = get_config('AWS_REGION', 'us-east-1')
INPUT_PREFIX = get_config('INPUT_PREFIX', 'raw-data/')
OUTPUT_PREFIX = get_config('OUTPUT_PREFIX', 'processed-data/')

# EMR IAM Roles (from CloudFormation stack)
EMR_SERVICE_ROLE = get_config(
    'EMR_SERVICE_ROLE', f'{PROJECT_NAME}-{ENVIRONMENT}-emr-service-role')
EMR_INSTANCE_PROFILE = get_config(
    'EMR_INSTANCE_PROFILE', f'{PROJECT_NAME}-{ENVIRONMENT}-emr-ec2-instance-profile')

# EMR Security Groups (from CloudFormation stack)
EMR_MASTER_SG = get_config('EMR_MASTER_SECURITY_GROUP', None)
EMR_SLAVE_SG = get_config('EMR_SLAVE_SECURITY_GROUP', None)

# VPC Configuration (from CloudFormation stack)
SUBNET_ID = get_config('EMR_SUBNET_ID', None)  # Private subnet for EMR

# Default arguments for the DAG
default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'start_date': days_ago(1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# EMR Cluster Configuration
JOB_FLOW_OVERRIDES = {
    'Name': f'{PROJECT_NAME}-{ENVIRONMENT}-cluster',
    'ReleaseLabel': 'emr-6.15.0',
    'Applications': [
        {'Name': 'Spark'},
        {'Name': 'Hadoop'},
    ],
    'Instances': {
        'InstanceGroups': [
            {
                'Name': 'Master nodes',
                'Market': 'ON_DEMAND',
                'InstanceRole': 'MASTER',
                'InstanceType': 'm5.xlarge',
                'InstanceCount': 1,
            },
            {
                'Name': 'Worker nodes',
                'Market': 'SPOT',
                'InstanceRole': 'CORE',
                'InstanceType': 'm5.xlarge',
                'InstanceCount': 2,
            }
        ],
        'KeepJobFlowAliveWhenNoSteps': True,
        'TerminationProtected': False,
    },
    'JobFlowRole': EMR_INSTANCE_PROFILE,
    'ServiceRole': EMR_SERVICE_ROLE,
    'LogUri': f's3://{EMR_LOGS_BUCKET}/',
    'VisibleToAllUsers': True,
}

# Add VPC configuration if subnet is provided (required for MWAA in VPC)
if SUBNET_ID:
    JOB_FLOW_OVERRIDES['Instances']['Ec2SubnetId'] = SUBNET_ID

# Add security groups if provided
if EMR_MASTER_SG and EMR_SLAVE_SG:
    JOB_FLOW_OVERRIDES['Instances']['EmrManagedMasterSecurityGroup'] = EMR_MASTER_SG
    JOB_FLOW_OVERRIDES['Instances']['EmrManagedSlaveSecurityGroup'] = EMR_SLAVE_SG


# Spark Step Configuration
SPARK_STEPS = [
    {
        'Name': 'Process Big Data',
        'ActionOnFailure': 'CONTINUE',
        'HadoopJarStep': {
            'Jar': 'command-runner.jar',
            'Args': [
                'spark-submit',
                '--deploy-mode', 'cluster',
                '--master', 'yarn',
                '--conf', 'spark.sql.adaptive.enabled=true',
                '--conf', 'spark.sql.adaptive.coalescePartitions.enabled=true',
                '--conf', 'spark.dynamicAllocation.enabled=true',
                '--driver-memory', '4g',
                '--executor-memory', '4g',
                '--executor-cores', '2',
                f's3://{MWAA_BUCKET}/scripts/spark_processing.py',
                '--input-path', f's3://{DATA_BUCKET}/{INPUT_PREFIX}',
                '--output-path', f's3://{PROCESSED_DATA_BUCKET}/{OUTPUT_PREFIX}',
            ],
        },
    }
]


def validate_input_data(**context):
    """Validate that input data exists in S3"""
    print(f"Validating data in s3://{DATA_BUCKET}/{INPUT_PREFIX}")
    print(f"Environment: {ENVIRONMENT}")
    print(f"Region: {AWS_REGION}")
    # Add your validation logic here
    return True


def notify_completion(**context):
    """Send notification about job completion"""
    ti = context['ti']
    execution_date = context['execution_date']
    print(f"Job completed successfully at {execution_date}")
    print(f"Output location: s3://{PROCESSED_DATA_BUCKET}/{OUTPUT_PREFIX}")
    # Add notification logic (SNS, email, etc.)
    # Example: Send SNS notification if topic ARN is configured
    # sns_topic = get_config('SNS_TOPIC_ARN', None)
    # if sns_topic:
    #     # Send notification using boto3
    #     pass
    return True


# Create the DAG
with DAG(
    'big_data_processing_pipeline',
    default_args=default_args,
    description='Process big data from S3 using EMR and store results back to S3 (MWAA Compatible)',
    schedule_interval='@daily',
    catchup=False,
    tags=['big-data', 'emr', 's3', 'spark', 'mwaa'],
) as dag:

    # Task 1: List files in S3 input bucket
    list_s3_files = S3ListOperator(
        task_id='list_s3_input_files',
        bucket=DATA_BUCKET,
        prefix=INPUT_PREFIX,
        delimiter='/',
        aws_conn_id='aws_default',
    )

    # Task 2: Validate input data
    validate_data = PythonOperator(
        task_id='validate_input_data',
        python_callable=validate_input_data,
        provide_context=True,
    )

    # Task 3: Create EMR cluster
    create_emr_cluster = EmrCreateJobFlowOperator(
        task_id='create_emr_cluster',
        job_flow_overrides=JOB_FLOW_OVERRIDES,
        aws_conn_id='aws_default',
        region_name=AWS_REGION,
    )

    # Task 4: Add Spark processing step to EMR
    add_spark_step = EmrAddStepsOperator(
        task_id='add_spark_processing_step',
        job_flow_id="{{ task_instance.xcom_pull(task_ids='create_emr_cluster', key='return_value') }}",
        aws_conn_id='aws_default',
        steps=SPARK_STEPS,
    )

    # Task 5: Wait for Spark step to complete
    wait_for_step = EmrStepSensor(
        task_id='wait_for_spark_step',
        job_flow_id="{{ task_instance.xcom_pull(task_ids='create_emr_cluster', key='return_value') }}",
        step_id="{{ task_instance.xcom_pull(task_ids='add_spark_processing_step', key='return_value')[0] }}",
        aws_conn_id='aws_default',
        poke_interval=60,
        timeout=3600,
    )

    # Task 6: Terminate EMR cluster
    terminate_emr_cluster = EmrTerminateJobFlowOperator(
        task_id='terminate_emr_cluster',
        job_flow_id="{{ task_instance.xcom_pull(task_ids='create_emr_cluster', key='return_value') }}",
        aws_conn_id='aws_default',
    )

    # Task 7: Notify completion
    notify = PythonOperator(
        task_id='notify_completion',
        python_callable=notify_completion,
        provide_context=True,
    )

    # Define task dependencies
    list_s3_files >> validate_data >> create_emr_cluster >> add_spark_step >> wait_for_step >> terminate_emr_cluster >> notify
