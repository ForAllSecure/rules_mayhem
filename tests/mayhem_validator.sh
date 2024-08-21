#!/bin/bash

set -ex

YQ_BIN="$1"
MAYHEM_BIN="$2"
INPUT_FILE="$3"


if [ -z "$MAYHEM_URL" ]; then
  echo "MAYHEM_URL is not set. Assuming default..."
  MAYHEM_URL="app.mayhem.security"
fi

# TODO: Local only validation is not yet supported; when this is supported, we'll use the commented line instead 
# if "$MAYHEM_BIN" --verbosity debug validate . -f "$INPUT_FILE"; then
if "$YQ_BIN" eval "$INPUT_FILE" > /dev/null; then
  echo "Valid"
  exit 0
else
  echo "Invalid. Please check Mayhemfile contents."
  exit 1
fi
