#!/usr/bin/env bash

usage() {
	local old_xtrace
	old_xtrace="$(shopt -po xtrace || :)"
	set +o xtrace
	echo "${script_name} - Generate a Linux ILP32 kernel patch set." >&2
	echo "Usage: ${script_name} [flags]" >&2
	echo "Option flags:" >&2
	echo "  -h --help    - Show this help and exit." >&2
	echo "  -v --verbose - Verbose execution." >&2
	echo "  -o --out-dir - Output directory. Default: '${out_dir}'." >&2
	echo "  -f --force   - Overwrite existing files." >&2
	echo "  --ver     - Kernel version. Ex: 5.0. Default: '${ver}'." >&2
	echo "  --src-dir - Kernel source directory. Default: '${SRC_TOP}'." >&2
	echo "  --remote  - Git 'remote' of branch. Default: '${remote}'." >&2
	eval "${old_xtrace}"
}

process_opts() {
	local short_opts="chvo:f"
	local long_opts="check,help,verbose,out-dir:,force,ver:,src-dir:,remote:"

	local opts
	opts=$(getopt --options ${short_opts} --long ${long_opts} -n "${script_name}" -- "$@")

	eval set -- "${opts}"

	while true ; do
		#echo "${FUNCNAME[0]}: @${1}@ @${2}@"
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
		-o | --out-dir)
			out_dir="${2}"
			shift 2
			;;
		-f | --force)
			force=1
			shift
			;;
		--ver)
			ver="${2}"
			shift 2
			;;
		--src-dir)
			SRC_TOP="${2}"
			shift 2
			;;
		--remote)
			remote="${2}"
			shift 2
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

#===============================================================================
# program start
#===============================================================================

export PS4='\[\e[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-"?"}):\[\e[0m\] '
script_name="${0##*/}"

SCRIPTS_TOP="${SCRIPTS_TOP:-$(cd "${0%/*}" && pwd)}"
SRC_TOP="${SRC_TOP:-$(cd "${SCRIPTS_TOP}/.." && pwd)}"
PATCHES_TOP="${PATCHES_TOP:-$(cd "${SRC_TOP}/../ilp32--patches" && pwd)}"

trap "on_exit 'failed.'" EXIT
set -e

process_opts "${@}"

out_dir="${out_dir:-${PATCHES_TOP}/ilp32-v${ver}-patches}"
#remote=${remote:-"origin"}

if [[ ${usage} ]]; then
	usage
	trap - EXIT
	exit 0
fi

check_opt 'ver' "${ver}"
check_opt 'src-dir' "${SRC_TOP}"
check_directory "${SRC_TOP}" "" "usage"

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

ver_base="${ver%-*}"
ver_post="${ver##${ver_base}}"

if [[ ${ver_post} == "-refactor" || ${ver_post} == "-legacy" ]]; then
	range="v${ver_base}..${remote}ilp32-${ver_base}.y${ver_post}"
else
	range="v${ver}..${remote}ilp32-${ver_base}.y"
fi

git -C "${SRC_TOP}" format-patch -o "${out_dir}/" "${range}"
git -C "${SRC_TOP}" diff --stat --patch "${range}" > "${out_dir}/ilp32-v${ver}.diff"

trap "on_exit 'Success.'" EXIT
exit 0
