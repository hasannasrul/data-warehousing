-- Redshift Initialization Script
-- Run this script on your Redshift cluster after deployment

-- Create schema for data warehouse
CREATE SCHEMA IF NOT EXISTS warehouse;

-- Create fact table
CREATE TABLE IF NOT EXISTS warehouse.fact_sales (
    sales_id BIGINT IDENTITY(1, 1) PRIMARY KEY,
    product_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    date_id INTEGER NOT NULL,
    quantity INTEGER,
    amount DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
DISTKEY(customer_id)
SORTKEY(date_id, customer_id);

-- Create dimension tables
CREATE TABLE IF NOT EXISTS warehouse.dim_customer (
    customer_id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    category VARCHAR(50),
    country VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
DISTKEY(customer_id);

CREATE TABLE IF NOT EXISTS warehouse.dim_product (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(50),
    price DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouse.dim_date (
    date_id INTEGER PRIMARY KEY,
    date_value DATE,
    year INTEGER,
    month INTEGER,
    day INTEGER,
    quarter INTEGER,
    week_of_year INTEGER,
    day_of_week VARCHAR(20)
);

-- Create staging table for data loads
CREATE TABLE IF NOT EXISTS warehouse.stg_sales (
    product_id INTEGER,
    customer_name VARCHAR(255),
    email VARCHAR(255),
    category VARCHAR(50),
    amount DECIMAL(10, 2),
    transaction_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
DISTKEY(customer_name);

-- Create summary tables for analytics
CREATE TABLE IF NOT EXISTS warehouse.summary_daily_sales (
    summary_date DATE,
    total_sales DECIMAL(12, 2),
    total_quantity INTEGER,
    unique_customers INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SORTKEY(summary_date);

-- Create index
CREATE INDEX idx_fact_sales_date ON warehouse.fact_sales(date_id);
CREATE INDEX idx_fact_sales_customer ON warehouse.fact_sales(customer_id);
CREATE INDEX idx_dim_customer_category ON warehouse.dim_customer(category);

-- Insert sample dimension data
INSERT INTO warehouse.dim_customer (customer_id, name, email, category, country)
VALUES
    (1, 'John Doe', 'john@example.com', 'Premium', 'USA'),
    (2, 'Jane Smith', 'jane@example.com', 'Standard', 'USA'),
    (3, 'Bob Johnson', 'bob@example.com', 'Premium', 'Canada'),
    (4, 'Alice Williams', 'alice@example.com', 'Standard', 'UK');

-- Insert date dimensions
INSERT INTO warehouse.dim_date (date_id, date_value, year, month, day, quarter, week_of_year, day_of_week)
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'), '99999999'),
    d,
    EXTRACT(YEAR FROM d),
    EXTRACT(MONTH FROM d),
    EXTRACT(DAY FROM d),
    EXTRACT(QUARTER FROM d),
    EXTRACT(WEEK FROM d),
    TO_CHAR(d, 'Day')
FROM (
    SELECT DATE '2024-01-01' + ROW_NUMBER() OVER (ORDER BY 1) - 1 AS d
    FROM warehouse.dim_customer
    LIMIT 365
) dates;

-- Create view for analytics
CREATE OR REPLACE VIEW warehouse.v_sales_summary AS
SELECT
    c.category,
    d.year,
    d.month,
    COUNT(DISTINCT f.sales_id) as total_transactions,
    SUM(f.quantity) as total_quantity,
    SUM(f.amount) as total_amount,
    AVG(f.amount) as avg_transaction_amount,
    COUNT(DISTINCT f.customer_id) as unique_customers
FROM warehouse.fact_sales f
JOIN warehouse.dim_customer c ON f.customer_id = c.customer_id
JOIN warehouse.dim_date d ON f.date_id = d.date_id
GROUP BY c.category, d.year, d.month
ORDER BY d.year, d.month, total_amount DESC;

-- Create stored procedure for data refresh
CREATE OR REPLACE PROCEDURE warehouse.sp_refresh_summary_tables()
AS $$
BEGIN
    -- Refresh daily sales summary
    DELETE FROM warehouse.summary_daily_sales
    WHERE summary_date >= CURRENT_DATE - INTERVAL '7 days';
    
    INSERT INTO warehouse.summary_daily_sales (summary_date, total_sales, total_quantity, unique_customers)
    SELECT
        d.date_value,
        SUM(f.amount),
        SUM(f.quantity),
        COUNT(DISTINCT f.customer_id)
    FROM warehouse.fact_sales f
    JOIN warehouse.dim_date d ON f.date_id = d.date_id
    WHERE d.date_value >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY d.date_value;
    
    COMMIT;
END;
$$ LANGUAGE plpgsql;

-- Enable query logging
ALTER SYSTEM SET log_min_duration_statement TO 1000;

-- Display summary
SELECT 'Redshift Initialization Complete' as status;
SELECT COUNT(*) as customer_count FROM warehouse.dim_customer;
SELECT COUNT(*) as date_dimension_records FROM warehouse.dim_date;
SELECT * FROM warehouse.v_sales_summary LIMIT 10;
