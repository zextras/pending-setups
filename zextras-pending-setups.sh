#!/usr/bin/env bash

PENDING_SETUPS_DIR="/etc/zextras/pending-setups.d/"
PERFORMED_SETUPS_DIR="/etc/zextras/pending-setups.d/done/"

execute_script() {
  SCRIPT="$1"
  echo "executing ${SCRIPT}"
  # limit visibility of secret token as much as possible
  export SETUP_CONSUL_TOKEN
  bash "${SCRIPT}"
  export -n SETUP_CONSUL_TOKEN
  EXIT_CODE="$?"
  if [[ "${EXIT_CODE}" == "0" ]]; then
    echo "setup successful, moving ${SCRIPT} in ${PERFORMED_SETUPS_DIR}"
    mv "${SCRIPT}" "${PERFORMED_SETUPS_DIR}"
  else
    echo "setup script failed, keeping it"
    return
  fi
}

if [[ "$(whoami)" != "root" ]]; then
  echo "run as root";
  exit 1;
fi;

SETUP_CONSUL_TOKEN=$(service-discover bootstrap-token --setup)
EXIT_CODE="$?"
if [[ "${EXIT_CODE}" != "0" ]]; then
  echo "cannot access to bootstrap token"
  exit 1;
fi

if [[ ! -d "${PENDING_SETUPS_DIR}" ]] || [[ ! -r "${PENDING_SETUPS_DIR}" ]]; then
  echo "cannot list directory ${PENDING_SETUPS_DIR}"
  exit 1;
fi

while : ; do
  SETUPS=()

  while IFS= read -r -d '' LINE; do
    SETUPS+=("${LINE}")
  done < <(find "${PENDING_SETUPS_DIR}" -maxdepth 1 -type f -name "*.sh" -print0)

  LEN=${#SETUPS[@]}
  echo "You have ${LEN} pending setups"
  if [[ "${LEN}" == "0" ]]; then
    exit 0;
  fi

  INDEX=0
  while [[ ${INDEX} < ${LEN} ]] ; do
    SETUP="${SETUPS[${INDEX}]}"
    NAME=$(basename "${SETUP}")
    echo "${INDEX}) ${NAME}"
    (( INDEX++ ))
  done
  echo "a) execute all"
  echo "q) quit"

  echo -n "> "
  read -r INPUT
  case "${INPUT}" in 
    ("a") 
      echo "executing all setup scripts";
      INDEX=0
      while [[ ${INDEX} < ${LEN} ]]; do
        execute_script "${SETUPS[${INDEX}]}"
        (( INDEX++ ))
      done
    ;;
    ("q") 
      exit 0
    ;;
    ([0-9]*) 
      if [[ "${INPUT}" < ${LEN} ]]; then
        execute_script "${SETUPS[${INPUT}]}"
      else
        echo "invalid selection";
      fi
    ;;
    (*) echo "invalid selection"
    ;;
  esac

  echo ""
done;
