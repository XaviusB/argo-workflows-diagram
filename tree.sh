#!/usr/bin/env bash

set -euo pipefail

function log() {
  local level=${1?}
  shift
  local code
  local line
  code=''
  line="[$(date '+%F %T')] $level: $*"
  if [ -t 2 ]; then
    case "$level" in
    INFO) code=36 ;;
    DEBUG) code=35 ;;
    WARN) code=33 ;;
    ERROR) code=31 ;;
    *) code=37 ;;
    esac
    echo -e "\e[${code}m${line} \e[94m(${FUNCNAME[1]})\e[0m"
  else
    echo "$line"
  fi >&2
}

get_full_path() {
  local file_path
  local "${@}"
  file_path="${file_path:?Missing file path}"
  local absolute_path=""

  # Check if the file path is already an absolute path
  if [[ "$file_path" == /* ]]; then
    absolute_path="$file_path"
  else
    # Convert the relative path to an absolute path
    absolute_path="$(cd "$(dirname "$file_path")" && pwd)/$(basename "$file_path")"
  fi

  echo "$absolute_path"
}

build_docker_image() {
  local image_name
  local dockerfile_path
  local "${@}"
  image_name="${image_name:?Missing image name}"
  dockerfile_path="${dockerfile_path:?Missing dockerfile path}"

  # The output of the docker build command is too verbose, so we redirect it to /dev/null
  docker build -t "${image_name}" "${dockerfile_path}" > /dev/null 2>&1
  error_code="${?}"
  if [[ $error_code -ne 0 ]]; then
    log ERROR "Failed to build docker image ${image_name}"
    exit 1
  fi
}

change_file_extension() {
    local file_path
    local new_extension
    local "${@}"
    file_path="${file_path:?Missing file path}"
    new_extension="${new_extension:?Missing new extension}"

    local base_name="${file_path%.*}"
    local new_file_name="$base_name$new_extension"
    echo "${new_file_name}"
}

main() {
  local input_file
  local "${@}"
  input_file="${input_file:?Missing input file}"

  build_docker_image \
    image_name="tree:local" \
    dockerfile_path="$(dirname "${BASH_SOURCE[0]}")"

  full_path=$(get_full_path file_path="${input_file}")

  filename=$(basename -- "$full_path")
  directory=$(dirname "$full_path")
  log INFO "processing ${full_path}"
  docker run --rm -it -v "${directory}:/data" tree:local --input-file="/data/${filename}"

  error_code="${?}"
  if [[ $error_code -eq 0 ]]; then
    png=$(change_file_extension file_path="${full_path}" new_extension=".png")
    drawio=$(change_file_extension file_path="${full_path}" new_extension=".drawio")
    log WARN "Diagram here: ${png}"
    log WARN "Drawio here: ${drawio}"
  else
    log ERROR "Failed to create diagram"
  fi
  exit ${error_code}
}

main "${@}"
