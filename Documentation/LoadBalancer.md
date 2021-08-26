## Load Balanacer Overview

Google Cloud offers the following load balancing configurations to distribute traffic and workloads across many VMs:

Global external load balancing, including HTTP(S) Load Balancing, SSL Proxy Load Balancing, and TCP Proxy Load Balancing
Regional external Network Load Balancing
Regional Internal TCP/UDP Load Balancing
Read more about [Cloud Load Balancing](https://cloud.google.com/load-balancing/docs).

[Types of Cloud Load Balancing](https://cloud.google.com/load-balancing/docs/load-balancing-overview#types-of-cloud-load-balancing) offered by Google Cloud :

* Internal : Regional only.
* External : Both Regional & Global.

**Global versus regional load balancing:**

`Global load balancing` is useful when backends are distributed across multiple regions and you want to provide access by using a single anycast IP address.

`Regional load balancing` is sufficient when backends are in one region. The current Terraform configuration has a single backend, and hence regional in nature. The reference architecture can be extended to multiple backends by customizing [`loadbalancer`](../Software/Deploy/modules/loadbalancer/main.tf) config within the module `Software/Deploy/modules/loadbalancer`.

**External versus internal load balancing:**

`External load balancers` distribute traffic coming from the internet to your Google Cloud Virtual Private Cloud (VPC) network. Global load balancing requires that you use the Premium Tier of [Network Service Tiers](https://cloud.google.com/network-tiers/docs/overview). For regional load balancing, you can use Standard Tier. 

`Internal load balancers` distribute traffic to instances inside of Google Cloud.

In this reference architecture, the configuration uses `external load balancer` to allow client requests for APIs hosted by `MATLAB Production Server` backend service.

Visit [Google Cloud documentation on load balancing](https://cloud.google.com/load-balancing/docs/load-balancing-overview#external_versus_internal_load_balancing) to learn more.

Visit this [link](https://cloud.google.com/load-balancing/docs/choosing-load-balancer) to learn more about choosing a load balancer.

### HTTP(S) Load Balancer for MATLAB Production Server

The HTTP(S) load balancer has a Compute Engine backend for MATLAB Production Server with the following resources:

* A reserved external IP address
* A Managed instance group for backend
* A frontend forwarding rule:
  * A frontend port 80 for external HTTP traffic.
  * A frontend port 443 for external HTTPS traffic. (Optional)
* A URL map to relay frontend HTTP(S) traffic to backend service port.
* A backend health check `http(s)//:<baseurl>/api/health`.
* An SSL certificate for an HTTPS load balancing. (Optional)
  
See an example [architecture](https://cloud.google.com/load-balancing/images/https-forwarding-rule.svg). 

**Health checks:**

Each backend service specifies a health check for backend instances.

Health checks connect to backends on a configurable, periodic basis. Each connection attempt is called a probe. Google Cloud records the success or failure of each probe.
Based on a configurable number of sequential successful or failed probes, an overall health state is computed for each backend.

 For the health check probes, a firewall rule allowing traffic from the following source ranges should be created:
  * 130.211.0.0/22
  * 35.191.0.0/16

Learn more on health checks over [here](https://cloud.google.com/load-balancing/docs/health-check-concepts#method).

**Firewall:**

The backend instances must allow connections from the `load balancer Google Front End (GFE)` for all requests sent to your backends and the `health check probes`.

To allow this traffic, ingress firewall rules must allow traffic as follows:

* To the destination port for each backend service's health check. e.g. `9910 for production server workers`.

* For instance group backend named port. In this case the port is same as the above `health check` port. 

* For GCE_VM_IP_PORT NEG backends: To the port numbers of the endpoints.

**Firewall rules are implemented at the VM instance level, not on GFE proxies.** You cannot use Google Cloud firewall rules to prevent traffic from reaching the load balancer. You can use [Google Cloud Armor ](https://cloud.google.com/armor/docs)to achieve this. This reference architecture does not deploy Google Cloud Armor service. The currently deployment can be placed behind an existing configuration.

For more information about health check probes and why it's necessary to allow traffic from them, see [Probe IP ranges and firewall rules](https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges).


### How connections work in HTTP(S) Load Balancing:

Any incoming request to MATLAB Production Server would undergo the following sequence of events:

1. A client sends a content request to the external IPv4 address defined for HTTP(s) load balancer in the forwarding rule.
2. The load balancer checks whether the request can be served from cache. If so, the load balancer serves the requested content out of cache. If not, processing continues.
3. For an HTTPS load balancer, the forwarding rule directs the request to the target HTTPS proxy.
4. For an HTTP load balancer, the forwarding rule directs the request to the target HTTP proxy.
5. The target proxy uses the rule in the URL map to determine that the single backend service receives all requests.
6. The load balancer determines that the backend service has only one instance group and directs the request to a healthy and available virtual machine (VM) instance in that group.
7. The VM serves the content requested by the user.

### Enabling HTTPS in reference architecture

Google Cloud uses SSL certificates to provide privacy and security from a client to a load balancer. If you are using HTTPS-based load balancing, you must install one or more SSL certificates on the target HTTPS proxy.

Learn more about [Self managed and Google managed SSL certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates#certificate-types).

In this reference architecture, in order to enable `https` you will need to place the private key and certificate within the folder location `Software/Deploy/certificate`.

Read more on [creating self signed SSL certificates](https://cloud.google.com/load-balancing/docs/ssl-certificates/self-managed-certs#create-key-and-cert).

Terraform resource `google_compute_ssl_certificate` provides a mechanism to upload an SSL key and certificate to the load balancer to serve secure connections from the user.

**Note:**
the following arguments are not optional and have specific format requirements.

* certificate - (Required) The certificate should be in PEM format. The certificate chain must be no greater than 5 certs long. The chain must include at least one intermediate cert. Note: This property is sensitive and will not be displayed in the plan.

* private_key - (Required) The write-only private key should be in PEM format. Note: This property is sensitive and will not be displayed in the plan.
  
Here is an example configuration used within this reference architecture.
```
"google_compute_ssl_certificate" "default" {
  name        = "${var.tag}-ssl-certificates"
  private_key = file(var.privatekey_path)
  certificate = file(var.certificate_path)
}
```

[//]: #  (Copyright 2021 The MathWorks, Inc.)