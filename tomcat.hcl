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

            env {
                JAVA_OPTS = "-agentpath:/opt/dynatrace/oneagent/agent/bin/1.287.136.20240403-173459/linux-x86-64/liboneagentloader.so=loglevelcon=none,datastorage=/var/lib/dynatrace/oneagent/datastorage,logdir=/var/log/dynatrace/oneagent"
            }

            config {
                command = "/bin/sh"
                args = ["-c", "cd local/ && tar xzf apache-tomcat-10.1.20.tar.gz && ./apache-tomcat-10.1.20/bin/catalina.sh run"]
                ipc_mode = "host"
                pid_mode = "host"
            }

            resources {
                cpu    = 500
                memory = 256
            }
        }
    }
}