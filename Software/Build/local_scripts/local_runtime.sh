#!/bin/bash

# Version of runtime available as a key in the map variable for MCR_URL
RUNTIME_VERSION=$1

# Download link for runtime available as a value in the map variable for MCR_URL
RUNTIME_URL=$2

# GCS bucket hosting runtime installers for installation and image creation step
RUNTIME_BUCKET_NAME=$3

# Construct runtime file name uniformly for every version
RUNTIME_FILE=MATLAB_Runtime_${RUNTIME_VERSION}_glnxa64.zip


# Verify if Runtime is available locally

# Check if runtimes folder exists. Exit with status 1 if does not exist.
Runtime_dir=$(pwd)/runtimes

if [ -d $Runtime_dir ]; then
 echo "Directory ${Runtime_dir} exists."
  # Proceed to check if the runtime installer exists within the directory.

  # Download if local copy not available
  # Skip download if local copy available for the version
  
  FILENAME=$(pwd)/runtimes/${RUNTIME_FILE}
  echo $FILENAME
  
  if [[ ! -f $FILENAME ]]
  then
    wget ${RUNTIME_URL} -O runtimes/${RUNTIME_FILE}
    status_code=$?
    echo "$FILENAME downloaded to runtimes/."
  else
    echo "$FILENAME exists locally. Download not required."
    status_code=$?
  fi

  # Check if the above stage for checking if runtimes exist or needs to be downloaded has run without an error
  
  # Proceed to runtime upload if status_code is 0
  if [[ $status_code -eq 0 ]]; then
    
    # Upload the runtime installer to the GCS Runtime Bucket
    gsutil -o GSUtil:parallel_composite_upload_threshold=150M cp -r $FILENAME gs://$RUNTIME_BUCKET_NAME/
    
    # Check status for gsutil operation
    upload_status=$?
    
    # If upload is successful proceed
    if [[ $upload_status -eq 0 ]]; then
      echo -e "$FILENAME uploaded to $RUNTIME_BUCKET_NAME bucket."
    else
      echo -e "$FILENAME upload to $RUNTIME_BUCKET_NAME bucket failed with exit code ${upload_status}."
      exit $upload_status
    fi

  else
    echo "Either runtime file check or runtime download operation has failed. Check if the folder 'Build/runtimes' exist. Check if download links for runtime provided within 'Build/variable.tf' are valid."
    exit $status_code
  fi

else
  echo -e "${Runtime_dir} does not exist. Make sure it exists."
  exit 1
fi

# (c) 2021 MathWorks, Inc.
