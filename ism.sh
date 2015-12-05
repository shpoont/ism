#!/bin/bash

ISM_DATA_DIR=${ISM_DATA_DIR:-${HOME}/.ism}
ISM_DATA_FILE="${ISM_DATA_DIR}/data.json"
ISM_DATA_TTL=${ISM_DATA_TTL:-30}
ISM_ALERT_FAILURES_COUNT=${ISM_ALERT_FAILURES_COUNT:-10}

ISM_LAST_COMMAND=""
ISM_LAST_COMMAND_JSON=""
ISM_LAST_EXIT_CODE=0

function _ism.init {
    _ism.check-requirements
    if [ "$?" -ne "0" ]; then
        return 1;
    fi
    
    # Create data dir and file if they dont exist
    if [ ! -d "${ISM_DATA_DIR}" ]; then
        mkdir -p "${ISM_DATA_DIR}"
        _ism.create-data-file "${ISM_DATA_FILE}"
    fi

    preexec_functions+=(_ism.preexec)
    precmd_functions+=(_ism.postexec)
  
    complete -F _ism.complete ism
    
    _ism.cleanup
}

function _ism.check-requirements {
    if [ "$__bp_imported" != "defined" ]; then
        echo "ism requires bash-preexec - https://github.com/rcaloras/bash-preexec"
        return 1
    fi
    if ! command -v jq > /dev/null; then
        echo "ism requires jq - https://stedolan.github.io/jq"
        return 1
    fi
    if ! command -v python > /dev/null; then
        echo "ism requires python"
        return 1
    fi
}

function _ism.preexec {
    ISM_LAST_COMMAND="$1"
    ISM_LAST_COMMAND_JSON=$(echo -n "${ISM_LAST_COMMAND}" | python -c "import sys,json; print json.dumps(sys.stdin.read())")
}

function _ism.postexec {
    ISM_LAST_EXIT_CODE="$?" # This has to be the first command in this function
    if [ -z "${ISM_LAST_COMMAND}" ]; then
        return ${ISM_LAST_EXIT_CODE}
    fi
    local EXEC_TIME=$(date +%F\|%T)
    local DATE_TODAY=$(date +%F)

    _ism.save "${EXEC_TIME}" "${ISM_DATA_FILE}"
    _ism.save "${EXEC_TIME}" "${ISM_DATA_DIR}/${DATE_TODAY}.json"
    _ism.check-alerts "${ISM_LAST_EXIT_CODE}"
    jobs > /dev/null
    return ${ISM_LAST_EXIT_CODE}
}

function _ism.save {
    local EXEC_TIME=$1
    local DATA_FILE=$2
    local STATE=""

    if [ ! -f "${DATA_FILE}" ]; then
        _ism.create-data-file "${DATA_FILE}"
    fi

    if [ "${ISM_LAST_EXIT_CODE}" == "0" ]; then
        STATE="success"
    else
        STATE="failure"
    fi

    local CURRENT_RECORD_INDEX=$(jq "index(.[] | select(.command==""${ISM_LAST_COMMAND_JSON}""))" "${DATA_FILE}")
    local TMP_FILE=$(mktemp)
    if [ -z "${CURRENT_RECORD_INDEX}" ]; then
        jq ". += [{\"command\":""${ISM_LAST_COMMAND_JSON}"",\"${STATE}\":1,\"date\":\"${EXEC_TIME}\"}]" "${DATA_FILE}" > "${TMP_FILE}"
    else
        jq ".["${CURRENT_RECORD_INDEX}"]."${STATE}"+=1 | .["${CURRENT_RECORD_INDEX}"].date=\"${EXEC_TIME}\"" "${DATA_FILE}" > "${TMP_FILE}"
    fi
    if [ -s "${TMP_FILE}" ]; then
        mv "${TMP_FILE}" "${DATA_FILE}"
    else
        return 1
    fi
}

function _ism.create-data-file {
    local FILE_NAME=$1

    if [ ! -f "${FILE_NAME}" ]; then
        echo "[]" > "${FILE_NAME}"
    fi
}

function ism {
    case "$1" in
        "--help")
            _ism.usage
            ;;
        "--stats")
            case "$2" in
                "--sort-failure" | "*")
                    local STATS_SORT="failure"
                    local STATS_ORDER=" | reverse "
                    ;;
                "--sort-success")
                    local STATS_SORT="success"
                    local STATS_ORDER="| reverse "
                    ;;
                "--sort-date")
                    local STATS_SORT="date"
                    local STATS_ORDER=" | reverse "
                    ;;
                "--sort-command")
                    local STATS_SORT="command"
                    local STATS_ORDER=""
                    ;;
            esac
            echo -e "Failure\tSuccess\tLast execution\t\tCommand"
            jq --raw-output "sort_by(.${STATS_SORT}) ${STATS_ORDER}| .[] | \"\(if .failure == null then 0 else .failure end)\t\(if .success == null then 0 else .success end)\t\(.date)\t\(.command)\"" "${ISM_DATA_FILE}"
            ;;
        "*")
            _ism.usage
            ;;
    esac
}

function _ism.usage {
    echo "ism Get alerts about your most unsuccessful bash commands and improve the way you work."
    echo "  --help - this help"
    echo "  --stats - print stats for successful and unsuccessful commands"
    echo "      [--sort-failure] - sort by unsuccessful command"
    echo "      [--sort-success] - sort by successful command"
    echo "      [--sort-date] - sort by last execution date"
    echo "      [--sort-command] - sort by command name"
}

function _ism.complete {
    local CURR_ARG="${COMP_WORDS[COMP_CWORD]}"
    local PREV_ARG="${COMP_WORDS[COMP_CWORD-1]}"
    if [ "${COMP_CWORD}" = "1" ]; then
        COMPREPLY=( $(compgen -W '--help --stats' -- "${CURR_ARG}") )
    elif [ "${COMP_CWORD}" = "2" -a "${PREV_ARG}" = "--stats" ]; then
        COMPREPLY=( $(compgen -W '--sort-failure --sort-success --sort-date --sort-command' -- "${CURR_ARG}") )
    fi
}

function _ism.check-alerts {
    if [ "${ISM_LAST_EXIT_CODE}" != "0" ]; then
        if [ "${ISM_ALERT_FAILURES_COUNT}" != "0" ]; then
            local COMMAND_FAILURES=$(jq --raw-output ".[] | select(.command==""${ISM_LAST_COMMAND_JSON}"") | if .failure == null then 0 else .failure end" "${ISM_DATA_FILE}")
            if [ $COMMAND_FAILURES -gt 0 -a $((COMMAND_FAILURES % ISM_ALERT_FAILURES_COUNT)) -eq 0 ]; then
                echo "-----------"
                echo "ism notice: This command is failing too often:"
                echo ""
                echo "     ${ISM_LAST_COMMAND}"
                echo ""
                echo "ism suggestion: try to fix this"
                echo "-----------"
            fi
        fi
    fi
    # TODO: Optionally alert with terminal-notifier in OS X
}

function _ism.cleanup {
    local EXPRATION_DATE=$(date -v-${ISM_DATA_TTL}d +%F\|%T)
    local TMP_FILE=$(mktemp)
    jq "map(select(.date > \"${EXPRATION_DATE}\"))" "${ISM_DATA_FILE}" > "${TMP_FILE}"
    if [ -s "${TMP_FILE}" ]; then
        mv "${TMP_FILE}" "${ISM_DATA_FILE}"
    fi
}

_ism.init
