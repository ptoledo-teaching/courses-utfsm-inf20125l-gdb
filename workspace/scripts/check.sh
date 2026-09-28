#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CODE_DIR="${WORKSPACE}/code"
PASSWORD_FILE="${WORKSPACE}/password.txt"
SYMBOLS_SOURCE="${CODE_DIR}/symbols.c"
SYMBOLS_PROGRAM="${CODE_DIR}/symbols"
SYMBOLS_DEBUG_PROGRAM="${CODE_DIR}/symbols_g"
BOMB_SOURCE="${CODE_DIR}/thermal_detonator.c"
BOMB_PROGRAM="${CODE_DIR}/thermal_detonator"
TEMP_DIR="$(mktemp -d)"
PASSES=0
FAILURES=0

trap 'rm -rf -- "${TEMP_DIR}"' EXIT

pass() {
    printf 'PASS: %s\n' "$1"
    PASSES=$((PASSES + 1))
}

fail() {
    printf 'FAIL: %s\n' "$1"
    FAILURES=$((FAILURES + 1))
}

check() {
    local description="$1"
    shift

    if "$@"; then
        pass "${description}"
    else
        fail "${description}"
    fi
}

is_binary_executable() {
    local path="$1"
    local description=""

    [[ -f "${path}" && -x "${path}" ]] || return 1
    description="$(file -b -- "${path}")"
    [[ "${description}" == ELF*executable* ]]
}

has_debug_information() {
    local path="$1"
    local description=""

    is_binary_executable "${path}" || return 1
    description="$(file -b -- "${path}")"
    [[ "${description}" == *"with debug_info"* ]]
}

lacks_debug_information() {
    local path="$1"
    local description=""

    is_binary_executable "${path}" || return 1
    description="$(file -b -- "${path}")"
    [[ "${description}" != *"with debug_info"* ]]
}

source_is_restored() {
    [[ -f "${SYMBOLS_SOURCE}" ]]
}

password_has_four_integers() {
    local values=()
    local value=""

    [[ -f "${PASSWORD_FILE}" ]] || return 1
    mapfile -t values < "${PASSWORD_FILE}"
    [[ ${#values[@]} -eq 4 ]] || return 1

    for value in "${values[@]}"; do
        [[ "${value}" =~ ^-?[0-9]+$ ]] || return 1
    done
}

bomb_is_defused() {
    local output_file="${TEMP_DIR}/bomb.out"
    local error_file="${TEMP_DIR}/bomb.err"
    local final_line=""

    is_binary_executable "${BOMB_PROGRAM}" || return 1
    password_has_four_integers || return 1

    timeout 3 "${BOMB_PROGRAM}" < "${PASSWORD_FILE}" \
        > "${output_file}" 2> "${error_file}" || return 1
    [[ ! -s "${error_file}" ]] || return 1

    final_line="$(tail -n 1 -- "${output_file}")"
    [[ "${final_line}" == "Thermal detonator disabled" ]]
}

printf '%s\n' '========================================='
printf '%s\n' '==   Verificación de laboratorio GDB   =='
printf '%s\n' '========================================='
printf '\n== Actividades ==========================\n\n'

check "[1.1] symbols corresponde a un binario sin símbolos de depuración" \
    lacks_debug_information "${SYMBOLS_PROGRAM}"
check "[1.1] symbols_g contiene símbolos de depuración" \
    has_debug_information "${SYMBOLS_DEBUG_PROGRAM}"
check "[1.5] symbols.c tiene su nombre original" source_is_restored
check "[2.1] El detonador corresponde a un binario ejecutable" \
    is_binary_executable "${BOMB_PROGRAM}"
check "[2.1] El detonador contiene símbolos de depuración" \
    has_debug_information "${BOMB_PROGRAM}"
check "[2.1] thermal_detonator.c está disponible para GDB" \
    test -f "${BOMB_SOURCE}"
check "[6.2] password.txt contiene cuatro números enteros" \
    password_has_four_integers
check "[7.1] La clave desactiva el detonador" bomb_is_defused
check "[7.2] check.sh tiene permiso de ejecución" \
    test -x "${SCRIPT_DIR}/check.sh"

printf '\n== Resumen ===============================\n\n'
TOTAL=$((PASSES + FAILURES))
COUNT_WIDTH=${#TOTAL}
printf '%-26s %*d\n' 'Comprobaciones exitosas:' "${COUNT_WIDTH}" "${PASSES}"
printf '%-26s %*d\n\n' 'Comprobaciones pendientes:' "${COUNT_WIDTH}" "${FAILURES}"

if (( FAILURES == 0 )); then
    exit 0
fi

exit 1
