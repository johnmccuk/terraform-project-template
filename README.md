# terraform-project-template

A base template for building Terraform projects based on terraform best practices

## Setting up State storage

After you set `config/backend-dev.conf` and `config/dev.tfvars` properly (for each environment). You can easily run terraform as below:

```
env=dev
terraform get -update=true
terraform init -reconfigure -backend-config=config/backend-${env}.conf
terraform plan -var-file=config/${env}.tfvars
terraform apply -var-file=config/${env}.tfvars
```

If you encountered any unexpected issues, delete the cache folder, and try again.

`rm -rf .terraform`
