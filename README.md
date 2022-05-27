# Terraform, Fly.io, DNSimple

The [Fly.io Terraform Provider](https://registry.terraform.io/providers/fly-apps/fly) allows orchestration of Fly.io platform resources with other services like DNSimple, AWS, etc.

This example demonstrates how to orchestrate the creation of a fully-functional Fly application with TLS certificates, a custom domain  and a public IP address. The VMs running this app are controlled using the low-level [Fly.io Machines API](https://fly.io/docs/reference/machines/). The appropriate DNS entries are added to handle TLS certificate validation and pointing the custom domain to Fly.io.

VMs are deployed in three separate regions. Each region's VM will accept requests from the users closest to them.

## Usage

Install Terraform, then copy `credentials.tfvars.example` to `credentials.tfvars` and fill it in with credentials.

Then run:

```
terraform init
terraform apply -var-file=credentials.tfvars
```
