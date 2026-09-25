from pathlib import Path

import pandas as pd
import psycopg2
from sqlalchemy import create_engine

# ============================================================
# PROJECT PATHS
# ============================================================

PROJECT_DIR = Path(__file__).resolve().parent
PARQUET_DIR = PROJECT_DIR / 'data_cleaning' / 'data' / 'parquet'

# ============================================================
# POSTGRESQL CONFIGURATION
# ============================================================

DB_USER = 'postgres'
DB_PASSWORD = 'sql'
DB_HOST = 'localhost'
DB_PORT = '5432'
DB_NAME = 'Hotels'

# ============================================================
# STEP 1 — CREATE DATABASE
# ============================================================

connection = psycopg2.connect(
    host = DB_HOST,
    port = DB_PORT,
    user = DB_USER,
    password = DB_PASSWORD,
    database = 'postgres'
)

connection.autocommit = True

cursor = connection.cursor()

cursor.execute(
    f"""
    SELECT 1 FROM pg_database where datname = '{DB_NAME}';
    """
)

database_exists = cursor.fetchone()

if database_exists:
    print(f'Database {DB_NAME} already exists.')
else:
    cursor.execute(f'CREATE DATABASE "{DB_NAME}";')
    print(f"Database '{DB_NAME}' created successfully.")

cursor.close()
connection.close()

# ============================================================
# STEP 2 — CONNECT TO HOTELS DATABASE
# ============================================================

DATABASE_URL = (f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

engine = create_engine(DATABASE_URL)

# ============================================================
# STEP 3 — TABLE CONFIGURATION
# ============================================================

TABLES = {
    "fact_bookings": "fact_bookings_clean.parquet",
    "fact_aggregated_bookings": "fact_aggregated_bookings_clean.parquet",
    "dim_hotels": "dim_hotels_clean.parquet",
    "dim_rooms": "dim_rooms_clean.parquet",
    "dim_date": "dim_date_clean.parquet",
}


# ============================================================
# STEP 4 — IMPORT CLEANED CSV FILES
# ============================================================

for table_name,file_name in TABLES.items():
    file_path = PARQUET_DIR / file_name
    print(f"\nLoading: {file_name}")

    df = pd.read_parquet(file_path)

    df.to_sql(
        name = table_name,
        con = engine,
        schema = 'public',
        if_exists = 'replace',
        index = False
    )

    print(f"Rows loaded: {len(df)}")
    print(f"Table created: {table_name}")

# ============================================================
# STEP 5 — VERIFY IMPORTED TABLES
# ============================================================

with engine.connect() as connection:
    result = connection.exec_driver_sql(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        ORDER BY table_name;

        """
        
    )
    print("\nTables currently in Hotels database:")
    for row in result:
            print(f"  - {row[0]}")


