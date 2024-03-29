#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# Copyright You-Sheng Yang and others
# SPDX-License-Identifier: Apache-2.0

set -eu -o pipefail

docker_run_args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --) shift; break;;
    *) docker_run_args+=("$1"); shift;;
  esac
done

[ $# -ge 1 ] || { echo "Insufficient argument." >&2; exit 1; }
image="$1"; shift

INPUT_DOCKER_ARGS="${INPUT_DOCKER_ARGS:-}"
INPUT_INCLUDE_ENV_MATCH="${INPUT_INCLUDE_ENV_MATCH:-}"
INPUT_IMAGE_CMDS="${INPUT_IMAGE_CMDS:-}"

while IFS='=' read -r -d '' name value; do
  case "${name}" in
  ACTIONS_*|CI|GITHUB_*|INPUT_*)
    docker_run_args+=("--env" "${name}=${value}")
    ;;
  *)
    if [ -n "${INPUT_INCLUDE_ENV_MATCH}" ] \
        && [[ "${name}" =~ ${INPUT_INCLUDE_ENV_MATCH} ]]; then
      docker_run_args+=("--env" "${name}=${value}")
    fi
    ;;
  esac
done < <(env -0)

while read -r bind; do
  [ -n "${bind}" ] && docker_run_args+=("--volume" "${bind}")
done < <(docker inspect "${HOSTNAME}" --format='{{ range .HostConfig.Binds }}{{printf "%s\n" .}}{{end}}')

echo "::group::docker run arguments"
echo "${docker_run_args[@]}"
echo "::endgroup::"

echo "::group::image commands"
echo "${*} ${INPUT_IMAGE_CMDS}"
echo "::endgroup::"

# shellcheck disable=SC2086
exec docker run "${docker_run_args[@]}" ${INPUT_DOCKER_ARGS} \
    "${image}" \
    "$@" ${INPUT_IMAGE_CMDS}
