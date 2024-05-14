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

if mayhem --verbosity debug validate . -f $1; then
  echo "Valid"
  exit 0
else
  echo "Invalid. Please check Mayhemfile contents."
  exit 1
fi
