from pathlib import Path

import pandas as pd

# ============================================================
# PROJECT PATHS
# ============================================================

PROJECT_DIR = Path(__file__).resolve().parent.parent

PROCESSED_DIR = (PROJECT_DIR/ "data"/ "processed")

RAW_DIR = (PROJECT_DIR/ "data"/ "raw")

QUARANTINE_DIR = (PROJECT_DIR/ "data"/ "quarantine")

REPORTS_DIR = (PROJECT_DIR/ "reports")

# ============================================================
# LOAD ACTUAL CLEANED TABLES
# ============================================================

def load_cleaned_table(table_name):
    file_path = (PROCESSED_DIR/f"{table_name}_clean.csv")

    assert file_path.exists(), (f'Cleaned table not found: {file_path}')

    return pd.read_csv(file_path)

# ============================================================
# TEST 1 — CLEANED TABLES CONTAIN NO EXACT DUPLICATE ROWS
# ============================================================

def test_clean_tables_have_no_exact_duplicates():
    table_names = [
        "fact_bookings",
        "fact_aggregated_bookings",
        "dim_hotels",
        "dim_rooms",
        "dim_date"
    ]

    for table_name in table_names:
        df = load_cleaned_table(table_name)
        duplicate_count = df.duplicated().sum()

        assert duplicate_count == 0, (f"{table_name} contains {duplicate_count} exact duplicate rows.")

# ============================================================
# TEST 2 — CLEANED DIMENSION TABLE KEYS ARE UNIQUE
# ============================================================

def test_dimension_keys_are_unique():
    dimension_rules = {
        "dim_hotels": ["property_id"],
        "dim_rooms": ["room_id"],
        "dim_date": ["date"]
    }

    for table_name,key_columns in dimension_rules.items():
        df = load_cleaned_table(table_name)
        duplicate_count = (df[key_columns].duplicated().sum())

        assert duplicate_count == 0, (f"{table_name} contains duplicate dimension keys.")

# ============================================================
# TEST 3 — CLEANED FACT TABLE BUSINESS KEYS ARE UNIQUE
# ============================================================

def test_fact_keys_are_unique():
    fact_rules = {
            "fact_bookings": ["booking_id"],
            "fact_aggregated_bookings": ["property_id","check_in_date","room_category"]
    }

    for table_name,key_columns in fact_rules.items():
        df = load_cleaned_table(table_name)

        duplicate_count = (df[key_columns].duplicated().sum())
        
        assert duplicate_count == 0, (f"{table_name} contains duplicate business keys.")

# ============================================================
# TEST 4 — CLEANED DATE COLUMNS CONTAIN VALID DATES
# ============================================================

def test_cleaned_date_columns_are_valid():

    date_columns = {
        "fact_bookings": ["booking_date","check_in_date","checkout_date"],
        "fact_aggregated_bookings": ["check_in_date"],
        "dim_date": ["date"]
    }
 
    for table_name, columns in date_columns.items():
        df = load_cleaned_table(table_name)

        for column in columns:
            converted_dates = pd.to_datetime(df[column],errors = 'coerce')
            invalid_count = (converted_dates.isna() & df[column].notna()).sum()

            assert invalid_count == 0 ,(f"{table_name}.{column} contains {invalid_count} invalid dates.")

# ============================================================
# TEST 5 — QUARANTINED SOURCE ROWS DO NOT EXIST IN CLEANED OUTPUT
# ============================================================

def test_quarantined_rows_are_not_in_cleaned_tables():

    table_names = [
        "fact_bookings",
        "fact_aggregated_bookings",
        "dim_hotels",
        "dim_rooms",
        "dim_date"
    ]

    for table_name in table_names:
        cleaned_df = load_cleaned_table(table_name)
        cleaned_source_ids = set(cleaned_df['_source_row_id'])

        quarantine_files = list(QUARANTINE_DIR.glob("f{table_name}_*.csv"))

        quarantined_source_ids = set()

        for file_path in quarantine_files:
            quarantine_df = pd.read_csv(file_path)

            if ("_source_row_id"in quarantine_df.columns):
                quarantined_source_ids.update(quarantine_df['_source_row_id'])

        overlap = (cleaned_source_ids & quarantined_source_ids)

        assert not overlap, (f"{table_name}: {len(overlap)} quarantined source rows are still present in the cleaned output.")



# ============================================================
# TEST 6 — CLEANED ROW COUNTS MATCH SCORECARD
# ============================================================

def test_cleaned_row_counts_match_scorecard():

    scorecard_path = (REPORTS_DIR/ "quality_scorecard.csv")

    assert scorecard_path.exists(), ('quality_scorecard.csv was not found')

    scorecard = pd.read_csv(scorecard_path)

    clean_records_from_scorecard = int(
        scorecard.loc[scorecard['Metric']=='Clean Records Output','Result'].iloc[0].replace(',','')
    )

    actual_clean_records = sum(
        len(load_cleaned_table(table_name))
        
        for table_name in [
            "fact_bookings",
            "fact_aggregated_bookings",
            "dim_hotels",
            "dim_rooms",
            "dim_date"    
        ]
    )

    assert actual_clean_records == (clean_records_from_scorecard),("Clean record count in the scorecard does not "
    "match the actual processed tables.")


                           
