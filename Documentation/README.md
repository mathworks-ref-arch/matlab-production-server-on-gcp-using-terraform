## Setting up *MATLAB Production Server&reg; on Google Cloud Platform&trade; using Terraform&reg;*

### About MATLAB Production Server:

MATLAB Production Server lets you incorporate custom analytics into web, database, and production enterprise applications running on dedicated servers or in the cloud. You can create algorithms in MATLAB®, package them using MATLAB Compiler SDK&reg;, and then deploy them to MATLAB Production Server without recoding or creating custom infrastructure. Users can then access the latest version of your analytics automatically.

MATLAB Production Server manages multiple [MATLAB Runtime&reg;](https://www.mathworks.com/products/compiler/matlab-runtime.html) versions simultaneously. As a result, algorithms developed in different versions of MATLAB can be incorporated into your application. The server runs on multiprocessor and multicore computers, providing low-latency processing of concurrent work requests. You can deploy the server on additional computing nodes to scale capacity and provide redundancy. See more details [here](https://www.mathworks.com/products/matlab-production-server.html).

This reference architecture helps in automating the process of **setting up MATLAB Production Server on Google cloud Platform usins sample Terraform configuration.**

### About Terraform and Google Platform Provider:

[Terraform](https://www.terraform.io/intro/index.html) is an infrastructure as code (IaC) tool that allows you to build, change, and version infrastructure safely and efficiently. This includes low-level components such as compute instances, storage, and networking, as well as high-level components such as DNS entries, SaaS features, etc. Terraform can manage both existing service providers and custom in-house solutions.

Terraform [Google Cloud Platform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs) is used to configure your Google Cloud Platform infrastructure with Terraform config files. See the [provider reference](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference) for more details on authentication or otherwise configuring the provider. 

The Google provider is jointly maintained by:

* The [Terraform Team](https://cloud.google.com/docs/terraform) at Google
* The Terraform team at [HashiCorp](https://www.hashicorp.com/?_ga=2.206188627.1519458328.1628777034-999678800.1614365084)

For more details on Releases, Feature and Bug Requests, please visit this [page](https://registry.terraform.io/providers/hashicorp/google/latest/docs).

These documents are an introductory guide to using the **reference architecture**:

### Contents:

* [Installation](Installation.md)
* [Authentication](Authentication.md)
* [Getting Started Example](Example.md)
* [Deploying a MATLAB function on MATLAB Production Server](DeployFunction.md)
* [Logging](Logging.md)
* [Network Overview](Network.md)
* [Load Balancer Overview](LoadBalancer.md)
* [References](References.md)

[//]: #  (Copyright 2021 The MathWorks, Inc.)