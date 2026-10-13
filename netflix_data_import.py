"""
============================================================================
PROJECT:       Netflix TV Shows & Movies — Data Import Pipeline
AUTHOR:        Jatin Naresh Dolas
DATE:          13th October 2026
PURPOSE:       Fix structural anomalies in Kaggle CSV files and import 
               clean data into MySQL for SQL analysis.

DATASET:       Netflix TV Shows and Movies (by Victor Soeiro)
SOURCE:        https://www.kaggle.com/datasets/victorsoeiro/netflix-tv-shows-and-movies

WHY PYTHON IS NEEDED:
    The raw Kaggle CSV files contain two critical structural issues that 
    MySQL's native import tools CANNOT handle:

    1. titles.csv: Contains multi-line text within quoted description fields.
       MySQL Workbench treats each newline as a new row, breaking records.

    2. credits.csv: ALL 77,800+ records are concatenated into a single line 
       with NO line breaks between them. The end of one record (e.g., "ACTOR") 
       is smashed directly into the start of the next (e.g., "14658,tm84618...").

    Python's pandas and regex libraries handle both issues perfectly.

ARCHITECTURE:
    Kaggle CSV (Messy) → Python (ETL) → MySQL Database (Clean) → SQL Analysis

DEPENDENCIES:
    pip install pandas sqlalchemy pymysql
============================================================================
"""

import pandas as pd
import re
import csv
from sqlalchemy import create_engine, text


# ============================================================================
# CONFIGURATION
# ============================================================================
MYSQL_CONFIG = {
    'user': 'root',                    # ← Change: Your MySQL username
    'password': '1234',       # ← Change: Your MySQL password
    'host': 'localhost',
    'port': 3306,
    'database': 'netflix_analysis'
}

TITLES_FILE = 'titles.csv'
CREDITS_FILE = 'credits.csv'


# ============================================================================
# FUNCTION 1: PARSE TITLES.CSV
# ============================================================================
def parse_titles(filepath):
    """
    Parse titles.csv using pandas.
    
    pandas automatically handles multi-line text within quoted fields,
    which is why MySQL Workbench failed but Python succeeds.
    
    Args:
        filepath (str): Path to titles.csv
        
    Returns:
        pd.DataFrame: Cleaned titles DataFrame
    """
    print("=" * 60)
    print("STEP 1: Parsing titles.csv...")
    print("=" * 60)
    
    try:
        # pandas handles multi-line quoted fields automatically
        df = pd.read_csv(filepath, encoding='utf-8')
        print(f"✅ Titles loaded: {len(df)} rows")
        print(f"   Columns: {list(df.columns)}")
        print(f"   Type distribution:\n{df['type'].value_counts().to_string()}")
        return df
    except Exception as e:
        print(f"❌ Error reading titles.csv: {e}")
        return None


# ============================================================================
# FUNCTION 2: PARSE CREDITS.CSV (THE TRICKY ONE)
# ============================================================================
def parse_credits(filepath):
    """
    Parse credits.csv which has NO line breaks between records.
    
    THE PROBLEM:
        Raw data looks like: "...ACTOR14658,tm84618,Jodie Foster,..."
        The word "ACTOR" (end of record) is smashed into "14658" 
        (start of next record) with no newline or space.
    
    THE FIX:
        Use regex to inject newlines after "ACTOR" or "DIRECTOR" 
        ONLY when followed by a digit + ",tm" or ",ts" pattern 
        (which indicates the start of the next record).
    
    Args:
        filepath (str): Path to credits.csv
        
    Returns:
        pd.DataFrame: Cleaned credits DataFrame
    """
    print("\n" + "=" * 60)
    print("STEP 2: Parsing credits.csv (fixing missing line breaks)...")
    print("=" * 60)
    
    # Read the raw file content
    with open(filepath, 'r', encoding='utf-8') as f:
        raw_content = f.read()
    
    # THE KEY FIX: Inject newlines where records are smashed together
    # Pattern: "ACTOR" or "DIRECTOR" followed by digits + ",tm" or ",ts"
    raw_content = re.sub(
        r'(ACTOR|DIRECTOR)(?=\d+,(tm|ts)\d+)', 
        r'\1\n', 
        raw_content
    )
    
    # Split into individual lines
    lines = raw_content.strip().split('\n')
    
    # Remove header row (it gets merged with first data row, so drop it)
    lines = [line for line in lines if not line.startswith('person_id')]
    
    print(f"   Total records found: {len(lines)}")
    
    # Parse each line using Python's CSV reader
    credits_data = []
    errors = 0
    
    for line in lines:
        try:
            row = next(csv.reader([line]))
            
            if len(row) == 5:
                # Normal record: person_id, id, name, character, role
                credits_data.append(row)
            elif len(row) > 5:
                # Handle commas inside character names
                # e.g., "Self - Former Dir. of Business Development, Cambridge Analytica"
                person_id = row[0]
                show_id = row[1]
                name = row[2]
                role = row[-1]          # Last element is always ACTOR or DIRECTOR
                character = ','.join(row[3:-1])  # Everything in between
                credits_data.append([person_id, show_id, name, character, role])
            else:
                errors += 1
        except Exception:
            errors += 1
    
    print(f"✅ Successfully parsed: {len(credits_data)} records")
    print(f"   Errors skipped: {errors}")
    
    # Create DataFrame
    df = pd.DataFrame(
        credits_data, 
        columns=['person_id', 'id', 'name', 'character_name', 'role']
    )
    
    # Clean up role column
    df['role'] = df['role'].str.strip().str.upper()
    
    print(f"   Role distribution:\n{df['role'].value_counts().to_string()}")
    
    return df


# ============================================================================
# FUNCTION 3: CREATE DATABASE & IMPORT TO MYSQL
# ============================================================================
def import_to_mysql(titles_df, credits_df):
    """
    Create MySQL database and import both DataFrames.
    
    Args:
        titles_df (pd.DataFrame): Cleaned titles data
        credits_df (pd.DataFrame): Cleaned credits data
    """
    print("\n" + "=" * 60)
    print("STEP 3: Importing to MySQL...")
    print("=" * 60)
    
    # Build connection string
    conn_str = (
        f"mysql+pymysql://{MYSQL_CONFIG['user']}:{MYSQL_CONFIG['password']}"
        f"@{MYSQL_CONFIG['host']}:{MYSQL_CONFIG['port']}/"
    )
    
    try:
        # Step 3a: Create database if it doesn't exist
        engine_no_db = create_engine(conn_str)
        with engine_no_db.connect() as conn:
            conn.execute(text(f"CREATE DATABASE IF NOT EXISTS {MYSQL_CONFIG['database']}"))
            conn.commit()
        print(f"✅ Database '{MYSQL_CONFIG['database']}' ready")
        
        # Step 3b: Connect to the database
        engine = create_engine(conn_str + MYSQL_CONFIG['database'])
        
        # Step 3c: Drop existing tables
        with engine.connect() as conn:
            conn.execute(text("DROP TABLE IF EXISTS titles_raw"))
            conn.execute(text("DROP TABLE IF EXISTS credits_raw"))
            conn.commit()
        print("   Old tables dropped")
        
        # Step 3d: Import titles
        titles_df.to_sql(
            name='titles_raw',
            con=engine,
            if_exists='replace',
            index=False,
            chunksize=500,
            method='multi'
        )
        print(f"✅ titles_raw imported: {len(titles_df)} rows")
        
        # Step 3e: Import credits
        credits_df.to_sql(
            name='credits_raw',
            con=engine,
            if_exists='replace',
            index=False,
            chunksize=500,
            method='multi'
        )
        print(f"✅ credits_raw imported: {len(credits_df)} rows")
        
        # Step 3f: Verify
        with engine.connect() as conn:
            titles_count = conn.execute(text("SELECT COUNT(*) FROM titles_raw")).scalar()
            credits_count = conn.execute(text("SELECT COUNT(*) FROM credits_raw")).scalar()
        
        print(f"\n{'=' * 60}")
        print(f"🎉 IMPORT COMPLETE!")
        print(f"{'=' * 60}")
        print(f"  titles_raw:  {titles_count:,} rows")
        print(f"  credits_raw: {credits_count:,} rows")
        print(f"{'=' * 60}")
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        print("\nTroubleshooting:")
        print("  1. Make sure MySQL server is running")
        print("  2. Check MYSQL_CONFIG at the top of this script")
        print("  3. Make sure pymysql is installed: pip install pymysql")


# ============================================================================
# MAIN EXECUTION
# ============================================================================
def main():
    """Main entry point for the script."""
    
    print("\n" + "🎬 NETFLIX DATA IMPORT PIPELINE".center(60))
    print("=" * 60 + "\n")
    
    # Step 1: Parse titles
    titles_df = parse_titles(TITLES_FILE)
    if titles_df is None:
        print("Aborting: Could not read titles.csv")
        return
    
    # Step 2: Parse credits
    credits_df = parse_credits(CREDITS_FILE)
    if credits_df is None or len(credits_df) == 0:
        print("Aborting: Could not parse credits.csv")
        return
    
    # Step 3: Import to MySQL
    import_to_mysql(titles_df, credits_df)
    
    # Final message
    print(f"\n📋 NEXT STEPS:")
    print(f"  1. Open MySQL Workbench")
    print(f"  2. Run: USE {MYSQL_CONFIG['database']};")
    print(f"  3. Run: SELECT COUNT(*) FROM titles_raw;")
    print(f"  4. Run: SELECT * FROM titles_raw LIMIT 5;")
    print(f"  5. Proceed with netflix_analysis.sql for data cleaning & analysis")


if __name__ == '__main__':
    main()