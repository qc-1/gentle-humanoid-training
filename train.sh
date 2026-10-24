#!/usr/bin/env bash
set -euo pipefail

# ===== Global Configuration =====
WANDB_ENTITY="${WANDB_ENTITY:-qc13659041465-ustc}"
WANDB_PROJECT="${WANDB_PROJECT:-gentle_humanoid}"
NPROC="${NPROC:-1}"
NUM_ENVS="${NUM_ENVS:-1024}"
RUN_SUFFIX="${RUN_SUFFIX:-$(date +%Y%m%d_%H%M%S)}"
TORCHRUN="${TORCHRUN:-torchrun}"
SCRIPT="${SCRIPT:-scripts/train.py}"
PROJECT="${WANDB_ENTITY}/${WANDB_PROJECT}"

if [[ ! -f dataset/lafan/meta_motion.json ]]; then
  echo "LAFAN dataset not found at dataset/lafan" >&2
  exit 1
fi

run_pipeline() {
  local TASK="$1" TAG="$2" SUFFIX="$3"

  local ID_TRAIN="${TAG}_train_${SUFFIX}"
  local ID_ADAPT="${TAG}_adapt_${SUFFIX}"
  local ID_FINETUNE="${TAG}_finetune_${SUFFIX}"

  # ---------- TRAIN ----------
  cmd=("$TORCHRUN" --nproc_per_node="$NPROC" "$SCRIPT"
    task="$TASK" +exp=train
    task.num_envs="$NUM_ENVS"
    wandb.entity="$WANDB_ENTITY"
    wandb.project="$WANDB_PROJECT"
    wandb.id="$ID_TRAIN"
  )
  echo ">>> ${cmd[*]}"; "${cmd[@]}"

  # ---------- ADAPT ----------
  cmd=("$TORCHRUN" --nproc_per_node="$NPROC" "$SCRIPT"
    task="$TASK" +exp=adapt
    task.num_envs="$NUM_ENVS"
    wandb.entity="$WANDB_ENTITY"
    wandb.project="$WANDB_PROJECT"
    checkpoint_path="run:${PROJECT}/${ID_TRAIN}"
    wandb.id="$ID_ADAPT"
  )
  echo ">>> ${cmd[*]}"; "${cmd[@]}"

  # ---------- FINETUNE ----------
  cmd=("$TORCHRUN" --nproc_per_node="$NPROC" "$SCRIPT"
    task="$TASK" +exp=finetune
    task.num_envs="$NUM_ENVS"
    wandb.entity="$WANDB_ENTITY"
    wandb.project="$WANDB_PROJECT"
    checkpoint_path="run:${PROJECT}/${ID_ADAPT}"
    wandb.id="$ID_FINETUNE"
  )
  echo ">>> ${cmd[*]}"; "${cmd[@]}"
}

run_pipeline "G1/G1_gentle" "gentle" "$RUN_SUFFIX"
run_pipeline "G1/G1_no_force" "noforce" "$RUN_SUFFIX"
run_pipeline "G1/G1_extreme_force" "extremeforce" "$RUN_SUFFIX"
