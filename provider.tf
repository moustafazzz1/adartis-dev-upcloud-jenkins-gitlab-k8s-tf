terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = ">= 2.11.0"
    }
  }
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# UpCloud referral to get $25 credits: https://upcloud.com/signup/?promo=Y2RZ4S
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
# Git repo with code: https://github.com/tappoz/scripting-utilities/upcloud-vm
#
# UpCloud subaccount environment variables:
# ```bash
# export UPCLOUD_USERNAME="***username***"
# export UPCLOUD_PASSWORD="***password***"
# ```
# Command to generate a password: `makepasswd  --chars=100`
# export UPCLOUD_USERNAME="shah1680"
# export UPCLOUD_PASSWORD="i9p0o"
provider "upcloud" {}


provider "kubernetes" {
  config_path = "./uks-instructions/terraform/cluster/kubeconfig.yml"
}

provider "helm" {
  kubernetes {
    config_path = "./uks-instructions/terraform/cluster/kubeconfig.yml"
  }
}