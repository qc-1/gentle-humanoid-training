#!/usr/bin/env bash

set -euo pipefail

DATASET_ROOT="${DATASET_ROOT:-/home/qc/data/retarget_g1}"

mkdir -p dataset

python scripts/data_process/generate_dataset.py \
    --dataset-root "${DATASET_ROOT}/LAFAN" \
    --allowlist scripts/data_process/allowlist_lafan.json \
    --mem-path dataset/lafan
