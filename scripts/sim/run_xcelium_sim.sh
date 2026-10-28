#!/usr/bin/env bash
set -euo pipefail

#DEFAULTS
TOP_FILE=""
EN_MEM=false
PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TOP_SOURCE=""
TOP_MODULE=""
MEM_FILE_LIST=""
usage() {
    cat <<EOF
Usage:
  run_xcelium.sh --top <testbench.sv> [--mem <mem_files.f>]
  run_xcelium.sh --top <tb/testbench.sv> [--mem <mem_files.f>]

Options:
  -h, --help            Show this help message
      --top FILE        Compile and run FILE; its filename without .sv is the top module
      --mem FILE        Include FILE in the Xrun file lists

Examples:
  run_xcelium.sh --top tb_riscv_programs.sv
  run_xcelium.sh --top tb_alu.sv
  run_xcelium.sh --top tb_riscv_programs.sv --mem mem_files.f

Testbench files can be in the current directory, the workspace root, or tb/.
The RTL paths in rtl_files.f are relative to sim/xcelium/<top>.
Xrun must be available on PATH.
EOF
}

while (($#)); do
    argument=$1
    shift
    case "$argument" in
        --top)
            if (($# == 0)) || [[ -z "$1" ]] || [[ -n "$TOP_FILE" ]]; then
                usage >&2
                exit 2
            fi
            TOP_FILE=$1
            shift
            ;;
        --mem)
            if (($# == 0)) || [[ -z "$1" ]] || [[ "$EN_MEM" == true ]]; then
                usage >&2
                exit 2
            fi
            MEM_FILE_LIST=$1
            EN_MEM=true
            shift
            ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

environment_check() {
    if ! xrun_bin=$(which xrun 2>/dev/null); then
        echo "Cannot find xrun. Load the Cadence environment on the remote host first." >&2
        exit 127
    fi
}

check_top_file() {
    if [[ -z "$TOP_FILE" || "$TOP_FILE" != *.sv ]]; then
        usage >&2
        exit 2
    fi

    if [[ ! -f "$TOP_FILE" ]]; then
        echo "Cannot find top file: $TOP_FILE" >&2
        exit 2
    fi
}

update_top_src_and_top_modulde() {
    TOP_SOURCE=$(realpath -- "$TOP_FILE")
    TOP_MODULE=${TOP_FILE##*/}
    TOP_MODULE=${TOP_MODULE%.sv}
}

check_rtl_files() {
    RTL_FILE_LIST="$PROJECT_DIR/rtl_files.f"
    if [[ ! -f "$RTL_FILE_LIST" ]]; then
        echo "Cannot find RTL file list: $RTL_FILE_LIST" >&2
        exit 2
    fi
}

check_mem_file_list() {
    if [[ "$EN_MEM" == true ]]; then
        if [[ ! -f "$MEM_FILE_LIST" ]]; then
            echo "Cannot find memory file list: $MEM_FILE_LIST" >&2
            exit 2
        fi
        MEM_FILE_LIST=$(realpath -- "$MEM_FILE_LIST")
    fi
}

create_output_dir() {
    local output_root="$PROJECT_DIR/sim/xcelium"
    mkdir -p -- "$output_root/$TOP_MODULE"
    OUTPUT_DIR=$(cd -- "$output_root/$TOP_MODULE" && pwd)
}

run_behavioral_sim() {
    local status
    local -a xrun_args
    local -a xrun_cmd
    xrun_args+=(-64bit)
    xrun_args+=(-sv)
    xrun_args+=(-top "$TOP_MODULE")
    xrun_args+=(-l xrun.log)
    xrun_args+=(-f "$RTL_FILE_LIST")
    if [[ "$EN_MEM" == true ]]; then
        xrun_args+=(-f "$MEM_FILE_LIST")
    fi
    xrun_args+=("$TOP_SOURCE")
    xrun_cmd=("$xrun_bin" "${xrun_args[@]}")
    cd -- "$OUTPUT_DIR"
    echo
    echo "===== top $TOP_MODULE: $PWD ====="
    echo "Running: ${xrun_cmd[*]}"
    if "${xrun_cmd[@]}" > console.log 2>&1; then
        cat console.log
        echo "PASS: top $TOP_MODULE compiled and ran successfully"
    else
        status=$?
        cat console.log
        echo "FAIL: top $TOP_MODULE (xrun exit $status). See $PWD/console.log" >&2
        exit "$status"
    fi
}

main() {
    environment_check
    check_top_file
    update_top_src_and_top_modulde
    check_rtl_files
    check_mem_file_list
    create_output_dir
    run_behavioral_sim
}

main
