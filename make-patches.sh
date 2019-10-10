#!/usr/bin/env bash

usage() {
	local old_xtrace
	old_xtrace="$(shopt -po xtrace || :)"
	set +o xtrace
	echo "${script_name} - Generate a Linux ILP32 kernel patch set." >&2
	echo "Usage: ${script_name} [flags]" >&2
	echo "Option flags:" >&2
	echo "  -c --check   - Run shellcheck." >&2
	echo "  -h --help    - Show this help and exit." >&2
	echo "  -v --verbose - Verbose execution." >&2
	echo "  -r --ver     - Kernel version. Default: '${ver}'." >&2
	echo "  -s --src-dir - Kernel source directory. Default: ${src_dir}." >&2
	echo "  -s --remote  - 'remote' of branch. Default: ${remote}." >&2
	echo "  -o --out-dir - Output directory. Default: '${out_dir}'." >&2
	echo "  -f --force   - Overwrite existing files." >&2
	eval "${old_xtrace}"
}

process_opts() {
	local short_opts="chvr:s:o:f"
	local long_opts="check,help,verbose,ver:,src-dir:,remote:,out-dir:,force"

	local opts
	opts=$(getopt --options ${short_opts} --long ${long_opts} -n "${script_name}" -- "$@")

	eval set -- "${opts}"

	while true ; do
		case "${1}" in
		-c | --check)
			check=1
			shift
			;;
		-h | --help)
			usage=1
			shift
			;;
		-v | --verbose)
			#verbose=1
			set -x
			shift
			;;
		--ver)
			ver="${2}"
			shift 2
			;;
		--src-dir)
			src_dir="${2}"
			shift 2
			;;
		--remote)
			remote="${2}"
			shift 2
			;;
		--out-dir)
			out_dir="${2}"
			shift 2
			;;
		-f | --force)
			force=1
			shift
			;;
		--)
			shift
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

check_directory() {
	local src="${1}"
	local msg="${2}"
	local usage="${3}"

	if [[ ! -d "${src}" ]]; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Directory not found${msg}: '${src}'" >&2
		[[ -z "${usage}" ]] || usage
		exit 1
	fi
}

check_opt() {
	option=${1}
	shift
	value=${*}

	if [[ ! ${value} ]]; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Must provide --${option} option." >&2
		usage
		exit 1
	fi
}

run_shellcheck() {
	local file=${1}

	shellcheck=${shellcheck:-"shellcheck"}

	if ! test -x "$(command -v "${shellcheck}")"; then
		echo "${script_name}: ERROR: Please install '${shellcheck}'." >&2
		exit 1
	fi

	${shellcheck} "${file}"
}

#===============================================================================
# program start
#===============================================================================

export PS4='\[\033[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-"?"}): \[\033[0;37m\]'
script_name="${0##*/}"

SCRIPTS_TOP=${SCRIPTS_TOP:-"$(cd "${0%/*}" && pwd)"}

trap "on_exit 'failed.'" EXIT
set -e

process_opts "${@}"

ver=${ver:-'5.0'}
src_dir=${src_dir:-"$(pwd)"}
#remote=${remote:-"origin/"}
out_dir=${out_dir:-"$(pwd)/ilp32-${ver}-patches"}

if [[ ${usage} ]]; then
	usage
	trap - EXIT
	exit 0
fi

if [[ ${check} ]]; then
	run_shellcheck "${0}"
	trap "on_exit 'Success'" EXIT
	exit 0
fi

check_opt 'ver' "${ver}"

check_opt 'src-dir' "${src_dir}"
check_directory "${src_dir}" "" "usage"

if [[ ${remote} && ${remote: -1} != "/" ]]; then
	remote+="/"
fi

if [[ -d ${out_dir} ]]; then
	if [[ ! ${force} ]]; then
		echo "${script_name}: ERROR: '${out_dir}' exists.  Use --force to overwrite." >&2
		exit 1
	fi
	rm -rf "${out_dir}"
fi

mkdir -p "${out_dir}"

git -C "${src_dir}" format-patch -o "${out_dir}/" "v${ver}..${remote}ilp32-${ver}.y"
git -C "${src_dir}" diff "v${ver}..${remote}ilp32-${ver}.y" > "${out_dir}/ilp32-${ver}.diff"

trap "on_exit 'Success.'" EXIT
exit 0
