-- RDS Initialization Script
-- Run this script on your RDS PostgreSQL instance after deployment

-- Create schema
CREATE SCHEMA IF NOT EXISTS public;

-- Create sample source table (to be extracted by Glue)
CREATE TABLE IF NOT EXISTS public.source_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    category VARCHAR(50),
    amount DECIMAL(10, 2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Create index for better query performance
CREATE INDEX idx_source_table_category ON public.source_table(category);
CREATE INDEX idx_source_table_created_date ON public.source_table(created_date);

-- Insert sample data
INSERT INTO public.source_table (name, email, category, amount)
VALUES
    ('John Doe', 'john@example.com', 'Electronics', 1500.00),
    ('Jane Smith', 'jane@example.com', 'Clothing', 750.50),
    ('Bob Johnson', 'bob@example.com', 'Electronics', 2500.00),
    ('Alice Williams', 'alice@example.com', 'Books', 150.25),
    ('Charlie Brown', 'charlie@example.com', 'Clothing', 500.75)
ON CONFLICT (email) DO UPDATE SET updated_date = CURRENT_TIMESTAMP;

-- Create audit table
CREATE TABLE IF NOT EXISTS public.audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(255),
    operation VARCHAR(10),
    record_id INTEGER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details JSONB
);

-- Create function for audit logging
CREATE OR REPLACE FUNCTION public.log_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_log (table_name, operation, record_id, details)
        VALUES (TG_TABLE_NAME, TG_OP, OLD.id, row_to_json(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.audit_log (table_name, operation, record_id, details)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO public.audit_log (table_name, operation, record_id, details)
        VALUES (TG_TABLE_NAME, TG_OP, NEW.id, row_to_json(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS source_table_audit ON public.source_table;
CREATE TRIGGER source_table_audit
AFTER INSERT OR UPDATE OR DELETE ON public.source_table
FOR EACH ROW EXECUTE FUNCTION public.log_changes();

-- Grant permissions for Glue service
GRANT CONNECT ON DATABASE warehouse TO public;
GRANT USAGE ON SCHEMA public TO public;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO public;
GRANT SELECT, INSERT, UPDATE ON public.audit_log TO public;

-- Create view for analytics
CREATE OR REPLACE VIEW public.category_summary AS
SELECT
    category,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount,
    MIN(amount) as min_amount,
    MAX(amount) as max_amount,
    COUNT(DISTINCT name) as unique_customers
FROM public.source_table
WHERE is_active = true
GROUP BY category
ORDER BY total_amount DESC;

-- Display summary
SELECT 'RDS Initialization Complete' as status;
SELECT * FROM public.source_table;
SELECT * FROM public.category_summary;
