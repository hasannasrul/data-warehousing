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
    'S3_BUCKET'
])

# Initialize Glue Job
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

try:
    # Read processed data from S3
    processed_input_path = f"s3://{args['S3_BUCKET']}/processed/"
    print(f"Reading processed data from {processed_input_path}...")

    processed_dyf = glueContext.create_dynamic_frame.from_options(
        format_options={"multiline": False},
        connection_type="s3",
        format="parquet",
        connection_options={
            "paths": [processed_input_path],
            "recurse": True
        }
    )

    # Apply ApplyMapping for schema refinement (optional)
    # mapped_dyf = ApplyMapping.apply(
    #     frame=processed_dyf,
    #     mappings=[
    #         ("id", "bigint", "id", "bigint"),
    #         ("name", "string", "name", "string"),
    #         # Add more mappings as needed
    #     ],
    #     transformation_ctx="mapped"
    # )

    # Convert to DataFrame for final transformations
    df = processed_dyf.toDF()

    # Optional: Aggregations or additional transformations
    # Example: Group by and aggregate
    # df = df.groupBy("category").agg({"amount": "sum"})

    # Curate data for Redshift
    print("Preparing data for Redshift...")

    # Ensure data is partitioned efficiently for Redshift
    df = df.repartition(100)  # Adjust partition count based on data volume

    # Convert back to DynamicFrame
    curated_dyf = DynamicFrame.fromDF(df, glueContext, "curated_data")

    # Write to Redshift using UNLOAD to S3
    redshift_output_path = f"s3://{args['S3_BUCKET']}/curated/"
    print(f"Writing curated data to {redshift_output_path}...")

    glueContext.write_dynamic_frame.from_options(
        frame=curated_dyf,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": redshift_output_path,
            "partitionKeys": ["processed_at"]  # Partition by processing date
        }
    )

    print("Data successfully prepared for Redshift ingestion")
    print(f"Total records processed: {df.count()}")

    job.commit()

except Exception as e:
    print(f"Error during S3 to Redshift preparation: {str(e)}")
    job.commit()
    sys.exit(1)
