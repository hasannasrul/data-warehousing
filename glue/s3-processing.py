import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, when, coalesce

# Get job parameters
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'S3_BUCKET'
])

# Initialize Glue Job
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

try:
    # Read raw data from S3
    raw_input_path = f"s3://{args['S3_BUCKET']}/raw/"
    print(f"Reading raw data from {raw_input_path}...")

    raw_dyf = glueContext.create_dynamic_frame.from_options(
        format_options={"multiline": False},
        connection_type="s3",
        format="parquet",
        connection_options={
            "paths": [raw_input_path],
            "recurse": True
        }
    )

    # Convert to Spark DataFrame for easier transformation
    df = raw_dyf.toDF()

    # Apply data cleaning and transformation
    print("Applying data transformations...")

    # Remove null values in key columns
    df = df.dropna(subset=['id'])

    # Handle duplicates
    df = df.dropDuplicates(['id'])

    # Data type conversions and standardization
    # Example: ensure date columns are properly typed
    # df = df.withColumn("created_date", col("created_date").cast("date"))

    # Add processing metadata
    from pyspark.sql.functions import current_timestamp
    df = df.withColumn("processed_at", current_timestamp())
    df = df.withColumn("data_quality_check",
                       when(col("id").isNotNull(), "PASSED").otherwise("FAILED"))

    # Convert back to DynamicFrame
    processed_dyf = DynamicFrame.fromDF(df, glueContext, "processed_data")

    # Write to processed folder in S3
    processed_output_path = f"s3://{args['S3_BUCKET']}/processed/"
    print(f"Writing processed data to {processed_output_path}...")

    glueContext.write_dynamic_frame.from_options(
        frame=processed_dyf,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": processed_output_path,
            "partitionKeys": []
        }
    )

    print("Data processing and transformation completed successfully")
    job.commit()

except Exception as e:
    print(f"Error during data processing: {str(e)}")
    job.commit()
    sys.exit(1)
