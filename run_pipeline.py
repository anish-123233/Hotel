from pathlib import Path
from datetime import datetime
import sys
import time
import warnings

import nbformat
from nbclient import NotebookClient

# ============================================================
# SUPPRESS JUPYTER / ZMQ WARNINGS
# ============================================================

warnings.filterwarnings("ignore",message="Proactor event loop does not implement add_reader")



# ============================================================
# PROJECT CONFIGURATION
# ============================================================

PROJECT_DIR = Path(__file__).resolve().parent

PIPELINE_NOTEBOOK = PROJECT_DIR/'src'/'quality_pipeline.ipynb'

REPORTS_DIR = PROJECT_DIR/'reports'

SCORECARD_FILE = REPORTS_DIR/'quality_scorecard.csv'

# ============================================================
# VALIDATE PROJECT STRUCTURE
# ============================================================

if not PIPELINE_NOTEBOOK.exists():
    print(f"ERROR: Pipeline notebook not found: {PIPELINE_NOTEBOOK}")
    sys.exit(1)

REPORTS_DIR.mkdir(parents=True,exist_ok=True)

# ============================================================
# LOAD PIPELINE NOTEBOOK
# ============================================================

with open(PIPELINE_NOTEBOOK,'r',encoding = 'utf-8') as file:
    notebook = nbformat.read(file,as_version = 4)

# ============================================================
# RUN PIPELINE
# ============================================================

start_time = time.perf_counter()
run_timestamp = datetime.now()

print("=" * 70)
print("HOTEL BOOKING DATA QUALITY PIPELINE")
print("=" * 70)

print(f'Run started : {run_timestamp}')
print(f'Pipeline    : {PIPELINE_NOTEBOOK}')
print()

try:
    client = NotebookClient(
        notebook,timeout = 1200,kernel_name = 'python3',allow_errors = False,extra_arguments=["--IPKernelApp.log_level=ERROR"]
    )
    # The quality_pipeline notebook uses Path.cwd()
    # and expects to be executed from the src directory.

    # Suppress Jupyter/ZeroMQ warning messages
    # while the notebook is being executed.
    client.execute(cwd=str(PIPELINE_NOTEBOOK.parent))

except Exception as error:
    runtime_seconds = time.perf_counter() - start_time

    print("\n" + "=" * 70)
    print("PIPELINE FAILED")
    print("=" * 70)

    print(f"Runtime : {runtime_seconds:.2f} seconds")
    print(f"Error   : {error}")

    sys.exit(1)

runtime_seconds = time.perf_counter() - start_time

# ============================================================
# CHECK SCORECARD
# ============================================================

if not SCORECARD_FILE.exists():

    print("\n" + "=" * 70)
    print("PIPELINE FAILED")
    print("=" * 70)

    print("Pipeline execution completed, but quality_scorecard.csv was not generated.")

    sys.exit(1)

# ============================================================
# READ QUALITY GATE
# ============================================================

import pandas as pd

scorecard = pd.read_csv(SCORECARD_FILE)

scorecard_values = dict(
    zip(scorecard["Metric"],scorecard["Result"])
)

quality_gate = scorecard_values.get("Quality Gate")

# ============================================================
# FINAL PIPELINE RESULT
# ============================================================

print("\n" + "=" * 70)

if quality_gate == 'PASSED':
    print("PIPELINE COMPLETED SUCCESSFULLY")
    print("=" * 70)

    print(f"Tables processed        :   {scorecard_values.get('Tables Processed', 'N/A')}")

    print(f"Raw records processed   :   {scorecard_values.get('Raw Records Processed', 'N/A')}")

    print(f"Records quarantined     :   {scorecard_values.get('Records Quarantined', 'N/A')}")

    print(f"Validation pass rate    :   {scorecard_values.get('Validation Pass Rate', 'N/A')}")

    print(f"Data retention rate     :   {scorecard_values.get('Data Retention Rate', 'N/A')}")

    print(f"Runtime                 :   {runtime_seconds:.2f} seconds")

    print(f"\nQuality gate          :   PASSED")

    print(f"Scorecard               :   {SCORECARD_FILE}")

    sys.exit(0)

else:
    print("PIPELINE QUALITY GATE FAILED")
    print("=" * 70)

    print(f"Quality gate : {quality_gate}")

    print("\nReview the validation and quarantine reports before using the processed data.")

    sys.exit(1)

