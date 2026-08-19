# Quickstart

1. run `./bootstrap.sh`
2. initialize provider scope (1:N) with `node src/cli/main.js init --providers azure[,aws,gcp]`
3. start an execution with SSO context using the saved provider scope
4. compare baseline and generate DSC
5. validate Terraform in advisory mode
