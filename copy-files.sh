#!/usr/bin/env bash

usage() {
	local old_xtrace="$(shopt -po xtrace || :)"
	set +o xtrace
	echo "${name} - Copy ILP32 base files." >&2
	echo "Usage: ${name} [flags] <file-type>" >&2
	echo "Option flags:" >&2
	echo "  -h --help    - Show this help and exit." >&2
	echo "  -v --verbose - Verbose execution." >&2
	echo "Args:" >&2
	echo "  <file-type>  - File type {${file_types}}." >&2
	echo "                 Default: '${file_type}'." >&2
	eval "${old_xtrace}"
}

process_opts() {
	local short_opts="hv"
	local long_opts="help,verbose"

	local opts
	opts=$(getopt --options ${short_opts} --long ${long_opts} -n "${name}" -- "$@")

	eval set -- "${opts}"

	while true ; do
		case "${1}" in
		-h | --help)
			usage=1
			shift
			;;
		-v | --verbose)
			set -x
			verbose=1
			shift
			;;
		--)
			file_type=${2}
			if [[ ${usage} ]]; then
				break
			fi
			if ! shift 2; then
				echo "${name}: ERROR: Missing args: <file-type>" >&2
				usage
				exit 1
			fi
			if [[ -n "${1}" ]]; then
				echo "${name}: ERROR: Got extra args: '${@}'" >&2
				usage
				exit 1
			fi
			break
			;;
		*)
			echo "${name}: ERROR: Internal opts: '${@}'" >&2
			exit 1
			;;
		esac
	done
}

on_exit() {
	local result=${1}

	set +x
	echo "${name}: Done: ${result}" >&2
}

# program start

export PS4='\[\033[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-"?"}): \[\033[0;37m\]'
name="${0##*/}"

SCRIPTS_TOP=${SCRIPTS_TOP:-"$(cd "${0%/*}" && pwd)"}

trap "on_exit 'failed.'" EXIT
set -e

file_types="binfmt syscall signal"

process_opts "${@}"

if [[ ${usage} ]]; then
	usage
	trap - EXIT
	exit 0
fi

case "${file_type}" in
binfmt)
	cp -iv "${SCRIPTS_TOP}/fs/compat_binfmt_elf.c" \
		"${SCRIPTS_TOP}/fs/arm64_ilp32_binfmt_elf.c"
	;;
syscall)
	cp -iv "${SCRIPTS_TOP}/arch/arm64/kernel/sys32.c" \
		"${SCRIPTS_TOP}/arch/arm64/kernel/sys_ilp32.c"
	;;
signal)
	cp -iv "${SCRIPTS_TOP}/arch/arm64/kernel/signal.c" \
		"${SCRIPTS_TOP}/arch/arm64/kernel/signal_ilp32.c"
	;;
*)
	echo "${name}: ERROR: Unknown <file-type> '${file_type}'" >&2
	usage
	exit 1
	;;
esac

trap "on_exit 'Success.'" EXIT
exit 0
