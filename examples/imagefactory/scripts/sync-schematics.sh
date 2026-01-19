#!/bin/ash
set -eo pipefail

trap "exit 0" SIGINT SIGTERM

: ${IMAGE_FACTORY_URL:?}
: ${REGISTRY_URL:?}
: ${TALOS_VERSION:?}
: ${ARCH:?}
: ${VALIDATE:?}
: ${SLEEP_TIME:?}

apk add crane yq

RESULTS_FILE="${RESULTS_FILE:-/tmp/results}"
while true; do
  echo '' > "${RESULTS_FILE}"
  for SCHEMATIC in /schematics/*.yaml ; do
    # this triggers image generation based on the schema provided
    # docs: https://github.com/siderolabs/image-factory?tab=readme-ov-file#post-schematics
    echo "apply ${SCHEMATIC}"
    RESPONSE_FILE=/tmp/wget-response.json
    wget \
      --header 'Content-Type: application/yaml' \
      -O "${RESPONSE_FILE}" \
      --post-file=${SCHEMATIC} \
      ${IMAGE_FACTORY_URL}/schematics \

    # parse the image ID from the response
    SCHEMA_ID=$(yq .id < "${RESPONSE_FILE}")
    if test -z "${SCHEMA_ID}" ; then
      echo 'SCHEMA_ID was empty'
      exit 1
    fi
    TMP_FILE="/tmp/${SCHEMA_ID}.tar"
    rm "${RESPONSE_FILE}"

    # docs: https://github.com/siderolabs/image-factory?tab=readme-ov-file#get-imageschematicversionpath
    echo 'download container'
    wget \
      -O ${TMP_FILE} \
      ${IMAGE_FACTORY_URL}/image/${SCHEMA_ID}/${TALOS_VERSION}/installer-${ARCH}.tar

    # optional: this calls `crane validate <image>`, validating the generated image is well formed
    # docs: https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane_validate.md
    if [ "${VALIDATE}" == 'true' ] ; then
      echo 'validate container'
      crane validate --tarball ${TMP_FILE}
    fi

    echo 'publish container'
    crane push \
      --insecure \
      ${TMP_FILE} \
      ${REGISTRY_URL}/installer/${SCHEMA_ID}:${TALOS_VERSION}

    rm -v ${TMP_FILE}
    echo "${SCHEMATIC} ${SCHEMA_ID}" >> "${RESULTS_FILE}"
  done

  # this prints the image IDs resulting from each schema,
  # which can then be handed out to clients.
  echo "--- results ---"
  cat "${RESULTS_FILE}"
  echo "---------------"

  echo "all done, sleep ${SLEEP_TIME} sec."
  sleep ${SLEEP_TIME} &
  wait $!
done
