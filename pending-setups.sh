#!/usr/bin/env bash

PENDING_SETUPS_DIR="/etc/zextras/pending-setups.d/"
PERFORMED_SETUPS_DIR="/etc/zextras/pending-setups.d/done/"
SETUP_CONSUL_TOKEN="${SETUP_CONSUL_TOKEN:-}"

check_root() {
  if [[ "$(whoami)" != "root" ]]; then
    echo "Please run as root"
    exit 1
  fi
}

check_token() {
  if [[ "${SETUP_CONSUL_TOKEN}" == "" ]]; then
    echo -n "Insert the cluster credential password: "
    SETUP_CONSUL_TOKEN=$(service-discover bootstrap-token --setup)
    EXIT_CODE="$?"
    if [[ "${EXIT_CODE}" != "0" ]]; then
      echo "Cannot access to bootstrap token"
      exit 1
    fi
    echo ""
  fi
}

check_folder() {
  if [[ ! -d "${PENDING_SETUPS_DIR}" ]] || [[ ! -r "${PENDING_SETUPS_DIR}" ]]; then
    echo "Cannot list directory ${PENDING_SETUPS_DIR}"
    exit 1
  fi
}

execute_script() {
  SCRIPT="${1}"
  echo "executing ${SCRIPT}"
  # limit visibility of secret token as much as possible
  export SETUP_CONSUL_TOKEN
  bash "${SCRIPT}"
  EXIT_CODE="$?"
  export -n SETUP_CONSUL_TOKEN

  if [[ "${EXIT_CODE}" == "0" ]]; then
    echo "setup successful, moving ${SCRIPT} in ${PERFORMED_SETUPS_DIR}"
    mv "${SCRIPT}" "${PERFORMED_SETUPS_DIR}"
  else
    echo "setup script failed, keeping it"
    exit 1
  fi
}

interactive_menu() {
  check_root
  check_token
  check_folder

  local input
  input="${1}"

  while :; do
    SETUPS=()

    while IFS= read -r -d '' LINE; do
      SETUPS+=("${LINE}")
    done < <(find "${PENDING_SETUPS_DIR}" -maxdepth 1 -type f -name "*.sh" -print0)

    LEN=${#SETUPS[@]}

    if [[ "${LEN}" == "0" ]]; then
      exit 0
    fi

    echo "You have ${LEN} pending setups"

    INDEX=0
    while (( ${INDEX} < ${LEN} )); do
      SETUP="${SETUPS[${INDEX}]}"
      NAME=$(basename "${SETUP}")
      echo "${INDEX}) ${NAME}"
      ((INDEX++))
    done
    echo "a) execute all"
    echo "q) quit"

    echo -n "> "
    read -r input

    case "${input}" in
      "a" | "all")
        echo "executing all setup scripts"
        INDEX=0
        while (( ${INDEX} < ${LEN} )); do
          execute_script "${SETUPS[${INDEX}]}"
          ((INDEX++))
        done
        ;;
      "q")
        exit 0
        ;;
      [0-9]*)
        if (( "${input}" < ${LEN} )); then
          execute_script "${SETUPS[${INPUT}]}"
        else
          echo "invalid selection"
        fi
        ;;
      *)
        echo "invalid selection"
        ;;
    esac

    echo
  done
}

usage() {
  echo "Keep track of needed setups for Zextras products"
  echo "Without arguments it will show an interactive menu"
  echo
  echo "Optional arguments"
  echo "  --execute-all or -a  process all the scripts under ${PENDING_SETUPS_DIR}"
  echo "                       (doesn't require user interactivity)"
  echo "  --help or -h         show this help message"
}

process_args() {
  case "${1}" in
    --help | -h) usage ;;
    --execute-all | -a) interactive_menu all ;;
    *) interactive_menu ;;
  esac
}

process_args "$@"
