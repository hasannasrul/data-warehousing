"""
Sample data generator for testing the pipeline
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os


def generate_sample_data(num_rows: int = 10000, output_path: str = 'data/sample_data.csv'):
    """
    Generate sample data for testing the pipeline

    Args:
        num_rows: Number of rows to generate
        output_path: Path to save the generated data
    """
    np.random.seed(42)

    # Generate sample data
    start_date = datetime(2025, 1, 1)

    data = {
        'id': range(1, num_rows + 1),
        'timestamp': [start_date + timedelta(hours=i) for i in range(num_rows)],
        'category': np.random.choice(['A', 'B', 'C', 'D', 'E'], num_rows),
        'amount': np.random.uniform(10, 10000, num_rows).round(2),
        'quantity': np.random.randint(1, 100, num_rows),
        'status': np.random.choice(['active', 'inactive', 'pending'], num_rows),
        'region': np.random.choice(['North', 'South', 'East', 'West'], num_rows),
        'product': np.random.choice(['Product_1', 'Product_2', 'Product_3', 'Product_4', 'Product_5'], num_rows),
    }

    df = pd.DataFrame(data)

    # Add some null values for testing
    df.loc[df.sample(frac=0.02).index, 'amount'] = np.nan
    df.loc[df.sample(frac=0.01).index, 'status'] = np.nan

    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # Save to CSV
    df.to_csv(output_path, index=False)
    print(f"Generated {num_rows} rows of sample data")
    print(f"Saved to: {output_path}")
    print(f"\nData shape: {df.shape}")
    print(f"\nFirst few rows:")
    print(df.head())
    print(f"\nData types:")
    print(df.dtypes)

    # Also save as Parquet
    parquet_path = output_path.replace('.csv', '.parquet')
    df.to_parquet(parquet_path, index=False)
    print(f"\nAlso saved as Parquet: {parquet_path}")


if __name__ == '__main__':
    generate_sample_data()
