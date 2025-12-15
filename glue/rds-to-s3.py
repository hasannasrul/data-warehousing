import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

# Get job parameters
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'RDS_ENDPOINT',
    'RDS_DATABASE',
    'RDS_USERNAME',
    'RDS_PASSWORD',
    'S3_BUCKET'
])

# Initialize Glue Job
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# JDBC connection options for RDS
jdbc_url = f"jdbc:postgresql://{args['RDS_ENDPOINT']}:5432/{args['RDS_DATABASE']}"
connection_options = {
    "url": jdbc_url,
    "user": args['RDS_USERNAME'],
    "password": args['RDS_PASSWORD'],
    "driver": "org.postgresql.Driver",
    "dbtable": "public.source_table"  # Replace with actual table name
}

try:
    # Read data from RDS using JDBC
    print(f"Connecting to RDS at {args['RDS_ENDPOINT']}...")

    rds_df = spark.read \
        .format("jdbc") \
        .options(**connection_options) \
        .load()

    # Convert to Glue DynamicFrame for processing
    rds_dyf = DynamicFrame.fromDF(rds_df, glueContext, "rds_data")

    # Apply transformations (example)
    # Remove duplicates
    transformed_dyf = rds_dyf.drop_duplicates()

    # Write to S3 in Parquet format
    s3_output_path = f"s3://{args['S3_BUCKET']}/raw/rds-data/"
    print(f"Writing data to {s3_output_path}...")

    glueContext.write_dynamic_frame.from_options(
        frame=transformed_dyf,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": s3_output_path,
            "partitionKeys": []
        }
    )

    print("Successfully extracted data from RDS and loaded to S3")
    job.commit()

except Exception as e:
    print(f"Error: {str(e)}")
    job.commit()
    sys.exit(1)
