## Deploying a MATLAB function on MATLAB Production Server

This document briefly explains the required resourcesfor deploying MATLAB functions using the MATLAB Production Server instance deployed using this reference architecture.

### Required reference architecture output resources: 

Once the reference architecture has completed deploying `MATLAB Production Server`, the following example `Terraform output` is made available:

```
Apply complete! Resources: 21 added, 0 changed, 0 destroyed.

Outputs:

mps-autodeploy-bucket = "mps-21a-deploy-ubuntu20-1629905006-autodeploy-bucket"

mps-config-bucket = "mps-21a-deploy-ubuntu20-1629905006-mps-config-bucket"

mps-http-endpoint = "http://34.107.196.133/api/health"

mps-script-bucket = "mps-21a-deploy-ubuntu20-1629905006-tempscript-bucket"

mps-worker-nodes = [
  "mps-21a-deploy-ubuntu20-1629905006-mps-node-0",
  "mps-21a-deploy-ubuntu20-1629905006-mps-node-1",
]

Deploy stage complete.

```

Some of the above outputs have significant role to play for using and maintaing the deployed server instance.

* The **mps-http-endpoint** refers to the MATLAB Production Server API for server health.

* The **mps-worker-nodes** is a list of hostnames of Google Cloud compute instances used for deployment. Each instance has been added to the backend service for the load balancer. 

* The **mps-config-bucket** is a Google Cloud Storage bucket created for convenient and automated upload for updated MATLAB Production Server configuration. This file should always be named as `main_config` and should be a valid MATLAB Production Server config. 

* The **mps-autodeploy-bucket** is a Google Cloud Storage bucket created for convenient and automated upload of compiled MATLAB functions. These compiled artifacts should have a `.ctf` extension. See MATLAB Compiler SDK documentation to learn about compiling MATLAB functions. The uploadede `.ctf` files automatically get deployed and do not need a server restart.

[//]: #  (Copyright 2021 The MathWorks, Inc.)