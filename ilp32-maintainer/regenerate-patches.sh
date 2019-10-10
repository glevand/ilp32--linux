#!/usr/bin/env bash

on_exit() {
	local result=${1}

	set +x
	echo "${script_name}: Done: ${result}" >&2
}

#===============================================================================

export PS4='\[\033[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-"?"}): \[\033[0;37m\]'
script_name="${0##*/}"

SCRIPTS_TOP="${SCRIPTS_TOP:-$(cd "${0%/*}" && pwd)}"
SRC_TOP="${SRC_TOP:-$(cd "${SCRIPTS_TOP}/.." && pwd)}"
PATCHES_TOP="${PATCHES_TOP:-$(cd "${SRC_TOP}/../ilp32--patches" && pwd)}"

trap "on_exit 'failed.'" EXIT
set -e

versions="
	4.12
	4.13
	4.14
	4.15
	4.16
	4.17
	4.18
	4.19
	4.20
	5.0
	5.1
	5.1-refactor
	5.2-legacy
	5.2
	5.3
	5.4
	5.5
	5.6
"

if [[ ${1} ]]; then
	echo "${script_name}: Unknown arg: '${1}'" >&2
	exit 1
fi

for v in ${versions}; do
	echo "${script_name} ===> ${v}"
	rm -rf "${PATCHES_TOP}/ilp32-${v}-patches"

	"${SCRIPTS_TOP}"/make-patches.sh --ver="${v}" --remote="origin" \
		-o "${PATCHES_TOP}/ilp32-${v}-patches" -v

	# git -C "${PATCHES_TOP}" add ilp32-${v}-patches
	# git -C "${PATCHES_TOP}" commit -m "fu: ${v}"
done

trap "on_exit 'Success.'" EXIT
exit 0
