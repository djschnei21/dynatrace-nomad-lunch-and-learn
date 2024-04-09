terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "~> 3.18.0"
    }

    nomad = {
      source = "hashicorp/nomad"
      version = "2.0.0-beta.1"
    }
  }
}

variable "tfc_organization" {
  default = ""
  type = string
}

data "terraform_remote_state" "nomad_cluster" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "5_nomad-cluster"
    }
  }
}

provider "vault" {}

data "vault_kv_secret_v2" "bootstrap" {
  mount = data.terraform_remote_state.nomad_cluster.outputs.bootstrap_kv
  name  = "nomad_bootstrap/SecretID"
}

provider "nomad" {
  address = data.terraform_remote_state.nomad_cluster.outputs.nomad_public_endpoint
  secret_id = data.vault_kv_secret_v2.bootstrap.data["SecretID"]
}

resource "nomad_job" "frontend" {
  jobspec = <<EOT
job "tomcat_hello_world" {
    datacenters = ["dc1"]
    type = "service"
    node_pool = "x86"

    group "hello_world_group" {
        network {
            port "http" {
                static = 8080
            }
        }
        
        service {
            name = "tomcat-1"
            port = "http"
            address = "$${attr.unique.platform.aws.public-ipv4}"

            check {
                name     = "http-check"
                type     = "http"
                path     = "/"
                interval = "10s"
                timeout  = "2s"
                port     = "http"
                method   = "GET"
            }
        }

        task "deploy_tomcat" {
            driver = "exec"

            artifact {
                source = "https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.20/bin/apache-tomcat-10.1.20.tar.gz"
                options {
                    archive = false # go-getter would extract this owned by root, we need nobody
                }
            }

            config {
                command = "/bin/sh"
                args = ["-c", "cd local/ && tar xzf apache-tomcat-10.1.20.tar.gz && cd apache-tomcat-10.1.20/bin && ./catalina.sh run"]
            }

            resources {
                cpu    = 500
                memory = 256
            }
        }
    }
}
EOT
}