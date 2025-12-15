"""
PySpark Job for Big Data Processing
Reads data from S3, processes it, and writes results back to S3
"""
import argparse
import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, count, sum, avg, max, min,
    when, lit, to_date, year, month, dayofmonth,
    trim, upper, lower, regexp_replace
)
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, IntegerType, TimestampType
from datetime import datetime


def create_spark_session(app_name="BigDataProcessing"):
    """Create and configure Spark session"""
    spark = SparkSession.builder \
        .appName(app_name) \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .config("spark.dynamicAllocation.enabled", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .getOrCreate()

    spark.sparkContext.setLogLevel("WARN")
    return spark


def read_data_from_s3(spark, input_path, file_format="parquet"):
    """
    Read data from S3
    Supports multiple formats: parquet, csv, json
    """
    print(f"Reading data from: {input_path}")

    try:
        if file_format.lower() == "csv":
            df = spark.read \
                .option("header", "true") \
                .option("inferSchema", "true") \
                .csv(input_path)
        elif file_format.lower() == "json":
            df = spark.read.json(input_path)
        elif file_format.lower() == "parquet":
            df = spark.read.parquet(input_path)
        else:
            raise ValueError(f"Unsupported file format: {file_format}")

        print(f"Successfully read {df.count()} rows")
        print("Schema:")
        df.printSchema()

        return df
    except Exception as e:
        print(f"Error reading data: {str(e)}")
        raise


def clean_data(df):
    """
    Data cleaning and preprocessing
    - Remove duplicates
    - Handle null values
    - Standardize formats
    """
    print("Starting data cleaning...")

    initial_count = df.count()

    # Remove duplicates
    df_cleaned = df.dropDuplicates()

    # Remove rows with all nulls
    df_cleaned = df_cleaned.dropna(how='all')

    # Trim string columns
    string_columns = [field.name for field in df_cleaned.schema.fields
                      if field.dataType == StringType()]
    for col_name in string_columns:
        df_cleaned = df_cleaned.withColumn(col_name, trim(col(col_name)))

    final_count = df_cleaned.count()
    print(f"Cleaned data: {initial_count} -> {final_count} rows")

    return df_cleaned


def transform_data(df):
    """
    Apply business logic transformations
    This is a sample transformation - customize based on your needs
    """
    print("Applying transformations...")

    # Example: Add processing timestamp
    df_transformed = df.withColumn("processed_at", lit(datetime.now()))

    # Example: Add derived columns (customize based on your data)
    # if 'amount' in df.columns:
    #     df_transformed = df_transformed.withColumn(
    #         "amount_category",
    #         when(col("amount") < 100, "small")
    #         .when(col("amount") < 1000, "medium")
    #         .otherwise("large")
    #     )

    # Example: Parse dates if present
    # if 'date_string' in df.columns:
    #     df_transformed = df_transformed.withColumn(
    #         "date", to_date(col("date_string"), "yyyy-MM-dd")
    #     )
    #     df_transformed = df_transformed.withColumn("year", year(col("date")))
    #     df_transformed = df_transformed.withColumn("month", month(col("date")))

    print(f"Transformation complete: {df_transformed.count()} rows")
    return df_transformed


def aggregate_data(df):
    """
    Perform aggregations on the data
    This is a sample aggregation - customize based on your needs
    """
    print("Performing aggregations...")

    # Example aggregation by a key column
    # Uncomment and modify based on your data schema
    """
    if 'category' in df.columns and 'amount' in df.columns:
        df_aggregated = df.groupBy("category").agg(
            count("*").alias("total_count"),
            sum("amount").alias("total_amount"),
            avg("amount").alias("avg_amount"),
            max("amount").alias("max_amount"),
            min("amount").alias("min_amount")
        )
        
        print("Aggregation results:")
        df_aggregated.show()
        
        return df_aggregated
    """

    # If no specific aggregation needed, return original dataframe
    return df


def write_data_to_s3(df, output_path, file_format="parquet", partition_by=None):
    """
    Write processed data back to S3
    Supports partitioning for efficient querying
    """
    print(f"Writing data to: {output_path}")

    try:
        writer = df.write \
            .mode("overwrite") \
            .option("compression", "snappy")

        if partition_by:
            writer = writer.partitionBy(partition_by)

        if file_format.lower() == "csv":
            writer.option("header", "true").csv(output_path)
        elif file_format.lower() == "json":
            writer.json(output_path)
        elif file_format.lower() == "parquet":
            writer.parquet(output_path)
        else:
            raise ValueError(f"Unsupported file format: {file_format}")

        print(f"Successfully wrote data to {output_path}")

    except Exception as e:
        print(f"Error writing data: {str(e)}")
        raise


def generate_summary_statistics(spark, df):
    """Generate and save summary statistics"""
    print("Generating summary statistics...")

    # Basic statistics
    summary_df = df.describe()

    # Count by column (non-null values)
    counts = []
    for column in df.columns:
        non_null_count = df.filter(col(column).isNotNull()).count()
        counts.append((column, non_null_count))

    counts_df = spark.createDataFrame(
        counts, ["column_name", "non_null_count"])

    print("Summary Statistics:")
    summary_df.show()

    print("\nColumn Counts:")
    counts_df.show()

    return summary_df, counts_df


def main():
    """Main execution function"""
    parser = argparse.ArgumentParser(
        description='Big Data Processing with PySpark')
    parser.add_argument('--input-path', required=True, help='S3 input path')
    parser.add_argument('--output-path', required=True, help='S3 output path')
    parser.add_argument('--input-format', default='parquet',
                        help='Input file format (parquet, csv, json)')
    parser.add_argument('--output-format', default='parquet',
                        help='Output file format (parquet, csv, json)')
    parser.add_argument('--partition-by', default=None,
                        help='Comma-separated list of columns to partition by')

    args = parser.parse_args()

    # Parse partition columns
    partition_cols = args.partition_by.split(
        ',') if args.partition_by else None

    print("=" * 80)
    print("BIG DATA PROCESSING JOB STARTED")
    print("=" * 80)
    print(f"Input Path: {args.input_path}")
    print(f"Output Path: {args.output_path}")
    print(f"Input Format: {args.input_format}")
    print(f"Output Format: {args.output_format}")
    print(f"Partition By: {partition_cols}")
    print("=" * 80)

    # Initialize Spark
    spark = create_spark_session()

    try:
        # Read data from S3
        df = read_data_from_s3(spark, args.input_path, args.input_format)

        # Clean data
        df_cleaned = clean_data(df)

        # Transform data
        df_transformed = transform_data(df_cleaned)

        # Aggregate data (optional)
        df_aggregated = aggregate_data(df_transformed)

        # Write main results
        write_data_to_s3(
            df_transformed,
            args.output_path + "/processed_data",
            args.output_format,
            partition_cols
        )

        # Write aggregated results if different from main data
        if df_aggregated is not df_transformed:
            write_data_to_s3(
                df_aggregated,
                args.output_path + "/aggregated_data",
                args.output_format
            )

        # Generate and save summary statistics
        summary_df, counts_df = generate_summary_statistics(
            spark, df_transformed)
        write_data_to_s3(
            summary_df,
            args.output_path + "/summary_statistics",
            "parquet"
        )
        write_data_to_s3(
            counts_df,
            args.output_path + "/column_counts",
            "parquet"
        )

        print("=" * 80)
        print("BIG DATA PROCESSING JOB COMPLETED SUCCESSFULLY")
        print("=" * 80)

    except Exception as e:
        print("=" * 80)
        print(f"JOB FAILED: {str(e)}")
        print("=" * 80)
        raise

    finally:
        spark.stop()


if __name__ == "__main__":
    main()
