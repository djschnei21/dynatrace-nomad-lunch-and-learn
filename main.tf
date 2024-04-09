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

resource "nomad_job" "tomcat" {
  jobspec = <<EOT
job "tomcat" {
    datacenters = ["dc1"]
    type = "service"
    node_pool = "x86"

    group "tomcat-group" {
        network {
            port "http" {
                static = 8080
            }
        }
        
        service {
            name = "tomcat-webserver"
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

        task "tomcat-task" {
            driver = "exec"

            artifact {
                source = "https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.20/bin/apache-tomcat-10.1.20.tar.gz"
                options {
                    archive = false # go-getter would extract this owned by root, we need nobody
                }
            }

            config {
                command = "/bin/sh"
                args = ["-c", "cd local/ && tar xzf apache-tomcat-10.1.20.tar.gz && ./apache-tomcat-10.1.20/bin/catalina.sh run"]
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

resource "nomad_job" "simple-java" {
  jobspec = <<EOT
job "simple-java" {
  datacenters = ["dc1"]
  node_pool = "x86"

  group "webserver-group" {
    count = 1
    network {
      port "http" {
        static = 80
      }
    }
    
    service {
      name = "java-webserver"
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


    task "webserver-task" {
      driver = "java"
      artifact {
        source      = "http://www.jibble.org/files/SimpleWebServer.jar"
        destination = "local/"
      }
      config {
        jar_path = "local/SimpleWebServer.jar"
      }

    }
  }
}
EOT
}