#!/bin/bash

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=- BASH CONFIGURATION =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Unofficial bash strict mode:
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= PATHS =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

SPLIT_DIR='messages-split'

OUTPUT_DIR='messages-organized'
UNSIGNED_DIR="${OUTPUT_DIR}/unsigned"
UNVERIFIED_DIR="${OUTPUT_DIR}/signed/unverified"
VERIFIED_DIR="${OUTPUT_DIR}/signed/verified"

INPUT_PATH="${1:-}"
if [[ -z "${INPUT_PATH}" ]]; then
  echo "Usage: ${0} input_file"
  exit 1
fi

ZIP_PATH="${OUTPUT_DIR}.zip"

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=- INITIALIZATION =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Clean out our output.
if [[ -e "${SPLIT_DIR}" ]]; then
  rm -rf "${SPLIT_DIR}"
fi
if [[ -e "${OUTPUT_DIR}" ]]; then
  rm -rf "${OUTPUT_DIR}"
fi
if [[ -e "${ZIP_PATH}" ]]; then
  rm -rf "${ZIP_PATH}"
fi

# Split the input file into individual message files.
mkdir -p "${SPLIT_DIR}"
message_count=$( git mailsplit "-o${SPLIT_DIR}" "${INPUT_PATH}" )
echo "${message_count} messages found"

# Create our output directories.
mkdir -p \
  "${UNSIGNED_DIR}" \
  "${UNVERIFIED_DIR}" \
  "${VERIFIED_DIR}"

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-= DKIM VERIFICATION =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

input_message_names=$( ls -1 "${SPLIT_DIR}" )
for input_message_name in ${input_message_names}; do
  input_message_path="${SPLIT_DIR}/${input_message_name}"

  # Check whether there's a signature at all.
  set +e
  sig_header=$(
    grep \
      --extended-regexp \
      --max-count 1 \
      '^DKIM-Signature: ' \
      "${input_message_path}"
  )
  sig_header_exit=$?  # 0 means there were matching lines
  set -e

  # If signed:
  if [[ "${sig_header_exit}" -eq 0 ]]; then
    # Attempt to verify the signature.
    set +e
    verification_result=$(dkimverify < "${input_message_path}")
    verification_result_exit=$?  # 0 means verification succeeded
    set -e

    # If verification succeeds:
    if [[ "${verification_result_exit}" -eq 0 ]]; then
      echo "${input_message_path} is signed and verified"
      cp "${input_message_path}" "${VERIFIED_DIR}/${input_message_name}.eml"
    # If verification fails:
    else
      echo "${input_message_path} is signed, but verification failed"
      cp "${input_message_path}" "${UNVERIFIED_DIR}/${input_message_name}.eml"
    fi
  # If unsigned:
  else
    echo "${input_message_path} is unsigned"
    cp "${input_message_path}" "${UNSIGNED_DIR}/${input_message_name}.eml"
  fi
done

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-= ZIP CREATION -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

zip --recurse-paths -9 "${ZIP_PATH}" "${OUTPUT_DIR}" > /dev/null
echo "Output file created at ${ZIP_PATH}"
