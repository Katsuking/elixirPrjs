#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source ${SCRIPT_DIR}/../../prod/.env.prod

curl -s "https://wger.de/api/v2/exercise/" \
  -H "Authorization: Token ${WGER_API_KEY}" | jq \
  > ${SCRIPT_DIR}/../output/exercises.json
