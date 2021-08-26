#!/bin/bash

# This script is invoked if `enable_https=true`
#
# This script validates the location of the private key and the ssl certificate provided by user.
#
# This script is called within `main.tf` of the module `loadbalancer` only in the Deploy stage.
#
# Only if the key and certificate locations are valid, the `google_compute_ssl_certificate` resource will be generated.
#
# If the above check fails the deployment will automatically fail.
#
# Usage:
#
# ./Deploy/local_scripts/check_ssl_certificates "./Deploy/certificate/private.key" "./Deploy/certificate/certificate.pem"

private_key_path=$1
certificate_path=$2
exit_code=0

# Extract file extensions for key and certificate.
# .key and .pem expected by Google Cloud
private_key=$(basename ${private_key_path})
certificate=$(basename ${certificate_path})


# Verify if Private Key & Certificate paths exist
GREEN='\033[0;32m'
RED='\033[0;31m'

echo -e "\e[1mValidating paths for private key and certificate\e[0m"
printf "\n\n"

if [[ ! -f $private_key_path ]]
then
  echo -e "${RED}\e[1mPrivate key cannot be found at: $private_key_path\e[0m"
  echo "Please provide a valid private key or check the path provided."
  echo -e "If you do not have a valid private_key or certificate, you will need to \e[1mswitch current configuration for 'enable_https' from true to false\e[0m. This is not a recommended practice."
  printf "\n"
  exit_code=1
else
  echo -e "${GREEN}\e[1mLocal path to the Private key has been validated.\e[0m"
  echo -e "Checking for a valid extension."
  printf "\n"
  if [ "${private_key: -4}" == ".key" ]; then
    echo -e "${GREEN}\e[1mPrivate Key extension is valid.\e[0m"
  else
    echo -e "${RED}\e[1mInvalid private key extension. Expected .key format.\e[0m"
    exit_code=1
  fi
  printf "\n"
fi

if [[ ! -f $certificate_path ]]
then
  echo -e "${RED}\e[1mCertificate provided as input cannot be found at: $certificate_path\e[0m"
  echo "Please provide a valid private key or check the path provided."
  echo -e "If you do not have a valid private_key or certificate, you will need to \e[1mswitch current configuration for 'enable_https' from true to false\e[0m. This is not a recommended practice."
  printf "\n"
  exit_code=1
else
  echo -e "${GREEN}\e[1mLocal path to the Certificate has been validated.\e[0m"
  echo -e "Checking for a valid extension."
  printf "\n"
  if [ "${certificate: -4}" == ".pem" ]; then
    echo -e "${GREEN}\e[1mCertificate extension is valid.\e[0m"
  else
    echo -e "${RED}\e[1mInvalid certificate extension. Expected .pem format.\e[0m"
    exit_code=1
  fi
  printf "\n"
fi

exit $exit_code


# (c) 2021 MathWorks, Inc.