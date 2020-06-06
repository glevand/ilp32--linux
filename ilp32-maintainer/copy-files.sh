#!/usr/bin/env bash

usage() {
	local old_xtrace
	old_xtrace="$(shopt -po xtrace || :)"
	set +o xtrace
	echo "${script_name} - Copy ILP32 base files." >&2
	echo "Usage: ${script_name} [flags] <file-type>" >&2
	echo "Option flags:" >&2
	echo "  -h --help    - Show this help and exit." >&2
	echo "  -v --verbose - Verbose execution." >&2
	echo "  -d --diff    - Run diff check." >&2
	echo "  -f --force   - Overwrite files without prompting." >&2
	echo "Args:" >&2
	echo "  <file-type>  - File type {${file_types} all}." >&2
	echo "                 Default: '${file_type}'." >&2
	eval "${old_xtrace}"
}

process_opts() {
	local short_opts="hvdf"
	local long_opts="help,verbose,diff,force"

	local opts
	opts=$(getopt --options ${short_opts} --long ${long_opts} -n "${script_name}" -- "$@")

	eval set -- "${opts}"

	while true ; do
		case "${1}" in
		-h | --help)
			usage=1
			shift
			;;
		-v | --verbose)
			#verbose=1
			set -x
			shift
			;;
		-d | --diff)
			diff_check=1
			shift
			;;
		-f | --force)
			force=1
			shift
			;;
		--)
			file_type=${2}
			if [[ ${usage} || ${shell_check}  || ${diff_check} ]]; then
				break
			fi
			if ! shift 2; then
				echo "${script_name}: ERROR: Missing args: <file-type>" >&2
				usage
				exit 1
			fi
			if [[ -n "${1}" ]]; then
				echo "${script_name}: ERROR: Got extra args: '${*}'" >&2
				usage
				exit 1
			fi
			break
			;;
		*)
			echo "${script_name}: ERROR: Internal opts: '${*}'" >&2
			exit 1
			;;
		esac
	done
}

on_exit() {
	local result=${1}

	set +x
	echo "${script_name}: Done: ${result}" >&2
}

diff_check() {
	if git status | egrep '(modified:|Untracked files:)' > /dev/null; then
		git status
		git diff
		echo "${script_name}: INFO: Files modified."
	else
		echo "${script_name}: INFO: No Changes."
	fi
}

copy_files() {
	local type=${1}
	local no_force

	if [[ ! ${force} ]]; then
		no_force=1
	fi

	case "${type}" in
	binfmt)
		cp -v ${no_force:+-i} \
			"${SRC_TOP}/fs/compat_binfmt_elf.c" \
			"${SRC_TOP}/fs/binfmt_arm64_ilp32_elf.c"
		;;
	signal)
		cp -v ${no_force:+-i} \
			"${SRC_TOP}/arch/arm64/kernel/signal.c" \
			"${SRC_TOP}/arch/arm64/kernel/signal_ilp32.c"
		;;
	syscall)
		cp -v ${no_force:+-i} \
			"${SRC_TOP}/arch/arm64/kernel/sys32.c" \
			"${SRC_TOP}/arch/arm64/kernel/sys_ilp32.c"
		;;
	vdso)
		mkdir -p "${SRC_TOP}/arch/arm64/kernel/vdso_ilp32"

		cp -v ${no_force:+-i} \
			"${SRC_TOP}/arch/arm64/kernel/vdso/gen_vdso_offsets.sh" \
			"${SRC_TOP}/arch/arm64/kernel/vdso/Makefile" \
			"${SRC_TOP}/arch/arm64/kernel/vdso/sigreturn.S" \
			"${SRC_TOP}/arch/arm64/kernel/vdso/vdso.lds.S" \
			"${SRC_TOP}/arch/arm64/kernel/vdso/vdso.S" \
			"${SRC_TOP}/arch/arm64/kernel/vdso/vgettimeofday.c" \
			"${SRC_TOP}/arch/arm64/kernel/vdso32/note.c" \
			"${SRC_TOP}/arch/arm64/kernel/vdso_ilp32/"
		;;
	*)
		echo "${script_name}: ERROR: Unknown <file-type> '${type}'" >&2
		usage
		exit 1
		;;
	esac

	diff_check
}

#===============================================================================
# program start
#===============================================================================

export PS4='\[\033[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-"?"}): \[\033[0;37m\]'
script_name="${0##*/}"

SCRIPTS_TOP="${SCRIPTS_TOP:-$(cd "${0%/*}" && pwd)}"
SRC_TOP="${SRC_TOP:-$(cd "${SCRIPTS_TOP}/.." && pwd)}"

trap "on_exit 'failed.'" EXIT
set -e

file_types="syscall signal binfmt vdso"

process_opts "${@}"

if [[ ${usage} ]]; then
	usage
	trap - EXIT
	exit 0
fi

if [[ ${diff_check} ]]; then
	diff_check
	trap "on_exit 'Success'" EXIT
	exit 0
fi

if [[ "${file_type}" == "all" ]]; then
	for ft in ${file_types}; do
		copy_files "${ft}"
	done
else
	copy_files "${file_type}"
fi

trap "on_exit 'Success.'" EXIT
exit 0
