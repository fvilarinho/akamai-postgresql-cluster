## Akamai PostgreSQL Cluster

### Introduction
This project has the intention to demonstrate the how to deploy a PostgreSQL cluster in Akamai Cloud Computing.

### Requirements
- [terraform 1.5.x](https://terraform.io)
- [kubectl 1.31.x](https://kubernetes.io/docs/reference/kubectl/kubectl)
- [linode-cli 5.52.x](https://www.linode.com/products/cli)
- [jq 1.7.x](https://jqlang.github.io/jq)
- [Akamai Cloud Computing account](https://cloud.linode.com)
- `Any Linux Distribution` or
- `Windows 10 or later` or
- `MacOS Catalina or later`

It automates (using **Terraform**) the provisioning of the following resources in Akamai Cloud Computing (former Linode) 
environment:
- **Domains (Authoritative DNS Server)**: Please check the file `iac/dns.tf` for more details.
- **Cloud Firewall**: Please check the file `iac/firewall.tf` for more details.
- **Node Balancers**: Please check the file `etc/manifest.yaml` for more details.
- **LKE (Linode Kubernetes Engine)**: Please check the file `iac/lke.tf` for more details. 
- **Object Storage**: Please check the file `iac/object-storage.tf` for more details.
- **Block Storage**: Please check the file `etc/manifest.yaml` for more details.
- **[PostgreSQL](https://cloudnative-pg.io)**: Please check the file `etc/manifest.yaml` for more details.

All Terraform files use `variables` that are stored in the `iac/variables.tf`.

Please check this [link](https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables) to know how to customize the variables.

### To deploy it in Akamai Cloud Computing

Just execute the command `deploy.sh` in your project directory. To undeploy, just execute the command `undeploy.sh` in 
your project directory.

### Documentation

Follow the documentation below to know more about Akamai:
- [Akamai Techdocs](https://techdocs.akamai.com)

### Important notes
- **DON'T EXPOSE OR COMMIT ANY SENSITIVE DATA, SUCH AS CREDENTIALS, IN THE PROJECT.**

### Contact
**LinkedIn:**
- https://www.linkedin.com/in/fvilarinho

**e-Mail:**
- fvilarin@akamai.com
- fvilarinho@gmail.com
- fvilarinho@outlook.com
- me@vila.net.br

and that's all! Have fun!