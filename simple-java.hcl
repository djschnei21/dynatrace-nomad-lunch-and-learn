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
      env {
        DT_HOME = "/opt/dynatrace/oneagent"
        LD_PRELOAD_64 = "/opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so"
      }
      config {
        jar_path = "local/SimpleWebServer.jar"
      }
    }
  }
}