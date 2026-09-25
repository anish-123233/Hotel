"""
===============================================================================
HOTEL BOOKING DATA QUALITY AUTOMATION
===============================================================================

Purpose:
    Automates the complete data quality workflow by running the pipeline
    followed by automated validation tests.

Process:
    1. Executes run_pipeline.py to clean and validate the data.
    2. Runs the pytest data quality test suite.
    3. Reports the overall pipeline and test status.
    4. Returns an appropriate exit code based on the test results.

Output:
    Processed datasets, data quality reports, and test results.

Exit Code:
    0 -> Pipeline and tests PASSED
    1 -> Pipeline or tests FAILED
===============================================================================
"""

from pathlib import Path
from datetime import datetime
import subprocess
import sys
import time


# ============================================================
# PROJECT PATH
# ============================================================

PROJECT_DIR = Path(__file__).resolve().parent

RUN_PIPELINE = PROJECT_DIR / "run_pipeline.py"
TESTS_DIR = PROJECT_DIR / "tests"

# ============================================================
# START TIME
# ============================================================

start_time = time.perf_counter()
run_timestamp = datetime.now()

print("=" * 70)
print("HOTEL BOOKING DATA QUALITY AUTOMATION")
print("=" * 70)

print(f"Run started : {run_timestamp}")
print()

# ============================================================
# VERIFY REQUIRED FILES
# ============================================================

if not RUN_PIPELINE.exists():
    print(f"ERROR: run_pipeline.py was not found: {RUN_PIPELINE}")
    sys.exit(1)


if not TESTS_DIR.exists():
    print(f"ERROR: tests directory was not found: {TESTS_DIR}")
    sys.exit(1)

# ============================================================
# STEP 1 — RUN DATA QUALITY PIPELINE
# ============================================================

print("=" * 70)
print("STEP 1 — RUNNING DATA QUALITY PIPELINE")
print("=" * 70)
print()

pipeline_result = subprocess.run([sys.executable,str(RUN_PIPELINE)],cwd = PROJECT_DIR)

if pipeline_result.returncode != 0:
    runtime_seconds = time.perf_counter() - start_time

    print("\n" + "=" * 70)
    print("PIPELINE FAILED")
    print("=" * 70)

    print("\nTests were not executed because the data pipeline failed.")

    print(f"Runtime : {runtime_seconds:.2f} seconds")

    sys.exit(pipeline_result.returncode)

# ============================================================
# STEP 2 — RUN PYTEST
# ============================================================

print("\n" + "=" * 70)
print("STEP 2 — RUNNING DATA QUALITY TESTS")
print("=" * 70)
print()

test_result = subprocess.run([sys.executable,'-m','pytest',str(TESTS_DIR),'-v'],cwd = PROJECT_DIR)

# ============================================================
# CALCULATE TOTAL RUNTIME
# ============================================================

runtime_seconds = time.perf_counter() - start_time

# ============================================================
# FINAL RESULT
# ============================================================

print("\n" + "=" * 70)

if test_result.returncode == 0:

    print("PIPELINE + TESTS COMPLETED SUCCESSFULLY")

else:

    print("PIPELINE COMPLETED, BUT TESTS FAILED")

print("=" * 70)
print(f"Runtime     : {runtime_seconds:.2f} seconds")
print("=" * 70)

sys.exit(test_result.returncode)
