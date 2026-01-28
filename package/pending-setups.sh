#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2023-2025 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

PENDING_SETUPS_DIR="/etc/zextras/pending-setups.d/"
PERFORMED_SETUPS_DIR="/etc/zextras/pending-setups.d/done/"
SETUP_CONSUL_TOKEN="${SETUP_CONSUL_TOKEN:-}"
LOG_PATH="/var/log/pending-setups"
NUMBER_OF_LOGS_TO_KEEP=100
CURRENT_LOG_DATE="$(date --iso-8601=ns)"

repeated_char() {
  printf "%$1s" | tr " " "$2"
}

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
  repeated_char 80 "-"
  echo
  echo "Executing ${SCRIPT}"
  # limit visibility of secret token as much as possible
  export SETUP_CONSUL_TOKEN
  bash "${SCRIPT}"
  EXIT_CODE="$?"
  export -n SETUP_CONSUL_TOKEN

  if [[ "${EXIT_CODE}" == "0" ]]; then
    local script_basename
    script_basename=$(basename "${SCRIPT}")
    echo "Setup successful, moving $script_basename to ${PERFORMED_SETUPS_DIR}"
    mv "${SCRIPT}" "${PERFORMED_SETUPS_DIR}"
    repeated_char 80 "-"
  else
    echo "Setup script failed, keeping it"
    repeated_char 80 "-"
    exit 1
  fi
}

interactive_menu() {
  local invalid_selection
  invalid_selection=false
  check_root
  check_token
  check_folder

  local input
  input="${1}"

  while :; do
    SETUPS=()

    while IFS= read -r -d '' LINE; do
      SETUPS+=("${LINE}")
    done < <(find "${PENDING_SETUPS_DIR}" -maxdepth 1 -type f -name "*.sh" -print0 | sort -zV)

    LEN=${#SETUPS[@]}

    if [[ "${LEN}" == "0" ]]; then
      echo "There are no pending-setups to run. Exiting!"
      exit 0
    fi

    if [[ -z "${input}" ]]; then
      echo
      echo "You have $LEN pending setups to run"
      for ((i = 0; i < LEN; i++)); do
        SETUP="${SETUPS[${i}]}"
        NAME=$(basename "${SETUP}")
        echo "${i}) ${NAME}"
      done
      echo
      echo "a) execute all"
      echo "q) quit"
      echo
      echo "Please input your selection:"
      echo -n "> "
      read -r input
    fi

    shopt -s extglob

    case "${input}" in
    "a" | "all")
      echo
      echo "Executing all setup scripts..."
      echo
      for ((i = 0; i < LEN; i++)); do
        execute_script "${SETUPS[${i}]}"
        echo
      done
      ;;
    "q")
      exit 0
      ;;
    [0-9]*)
      if [[ ${input} -lt ${LEN} ]]; then
        echo
        execute_script "${SETUPS[${input}]}"
        echo
        break
      else
        echo
        echo "Invalid selection, please try again..."
        invalid_selection=true
        echo
        break
      fi
      ;;
    *)
      echo
      echo "Invalid selection, please try again..."
      echo
      break
      ;;
    esac
    echo
  done

  if [ $invalid_selection = true ] || [ "$LEN" -gt 0 ]; then
    interactive_menu
  fi
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

check_and_rotate() {
  local number_of_logs
  number_of_logs="$(find "${LOG_PATH}" -type f -iname "*.log" 2> /dev/null | wc -l)"

  if [[ ${number_of_logs} -gt ${NUMBER_OF_LOGS_TO_KEEP} ]]
  then
    local number_of_files_to_delete

    number_of_files_to_delete=$((number_of_logs - NUMBER_OF_LOGS_TO_KEEP))
    find "${LOG_PATH}" -type f -iname "*.log" 2> /dev/null | sort | head -n"${number_of_files_to_delete}" | xargs rm
  fi
}

process_args() {
  case "${1}" in
  --help | -h) usage ;;
  --execute-all | -a) interactive_menu all ;;
  *) interactive_menu ;;
  esac
}

(check_and_rotate && process_args "$@") 2>&1 | tee -a "${LOG_PATH}/${CURRENT_LOG_DATE}.log"
