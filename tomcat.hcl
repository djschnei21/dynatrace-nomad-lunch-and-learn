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
            driver = "raw_exec"

            artifact {
                source = "https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.20/bin/apache-tomcat-10.1.20.tar.gz"
                options {
                    archive = false # go-getter would extract this owned by root, we need nobody
                }
            }

            // env {
            //     DT_HOME = "/opt/dynatrace/oneagent"
            //     LD_PRELOAD_64 = "/opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so"
            // }

            config {
                command = "/bin/sh"
                args = ["-c", "cd local/ && tar xzf apache-tomcat-10.1.20.tar.gz && . /opt/dynatrace/oneagent/dynatrace-java-env.sh 64 && ./apache-tomcat-10.1.20/bin/catalina.sh run"]
            }

            resources {
                cpu    = 500
                memory = 256
            }
        }
    }
}