module "upcloud_k8s" {
  source           = "./uks-instructions/terraform/cluster"
  basename         = var.basename
  store_kubeconfig = true
  zone             = var.zone
}

module "deployment" {
  source     = "./uks-instructions/terraform/deployment"
  cluster_id = module.upcloud_k8s.cluster_id
}

resource "random_id" "token" {
  byte_length = 26
}

output "api_token" {
  value = random_id.token.id
}
