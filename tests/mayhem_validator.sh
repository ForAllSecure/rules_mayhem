#!/bin/bash

set -ex

if [ -z "$MAYHEM_URL" ]; then
  echo "MAYHEM_URL is not set. Assuming default..."
  MAYHEM_URL="app.mayhem.security"
fi

if ! command -v mayhem &> /dev/null
then
    echo "WARNING: Mayhem CLI could not be found. Downloading Mayhem CLI first."
    curl --fail -L https://$MAYHEM_URL/cli/Linux/install.sh | sh
    echo "Mayhem CLI installed successfully."
fi

if ! command -v yq &> /dev/null
then
    echo "WARNING: yq not found. Downloading manually first."
    curl --fail -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/bin/yq
    chmod +x /usr/bin/yq
    echo "yq installed successfully."
fi


# if mayhem --verbosity debug validate . -f $1; then
if yq eval $1 > /dev/null; then
  echo "Valid"
  exit 0
else
  echo "Invalid. Please check Mayhemfile contents."
  exit 1
fi
