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
      driver = "raw_exec"

      artifact {
        source      = "http://www.jibble.org/files/SimpleWebServer.jar"
        destination = "local/"
      }

      config {
        command = "/bin/sh"
        args = ["-c", "java -jar local/SimpleWebServer.jar"]
      }
    }
  }
}