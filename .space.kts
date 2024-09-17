import java.time.LocalDate

job("Build Pods API Image") {
    startOn {
        gitPush {
            anyBranchMatching {
                +"release-*"
                +"master"
                +"main"
            }
        }
    }

    // To check a condition, basically, you need a kotlinScript step
    host(displayName = "Setup Version") {
        kotlinScript { api ->
            // Get the current year and month
            val currentYear = (LocalDate.now().year % 100).toString().padStart(2, '0')
            val currentMonth = LocalDate.now().monthValue.toString()

            // Get the execution number from environment variables
            val currentExecution = System.getenv("JB_SPACE_EXECUTION_NUMBER")

            // Set the VERSION_NUMBER parameter
            api.parameters["VERSION_NUMBER"] = "$currentYear.$currentMonth.$currentExecution"
        }

        requirements {
            workerTags("windows-pool")
        }
    }

    container(displayName = "Setup Configurations", image = "amazoncorretto:17-alpine") {
        env["KUBE_CONFIG"] = Secrets("ethos-pods-api-microk8s-config")

        shellScript {
            content = """
                echo Get kubernetes config...
                pwd
                ls
                echo ${'$'}KUBE_CONFIG > microk8s-config
                ls
            """
        }

        requirements {
            workerTags("windows-pool")
        }
    }

    host("Build and push Pods API image") {
        dockerBuildPush {
            // by default, the step runs not only 'docker build' but also 'docker push'
            // to disable pushing, add the following line:
            // push = false

            // path to Docker context (by default, context is working dir)
            // context = "docker"
            // path to Dockerfile relative to the project root
            // if 'file' is not specified, Docker will look for it in 'context'/Dockerfile
            file = "ethos-pods-api/Dockerfile"
            // build-time variables
            // args["HTTP_PROXY"] = "http://10.20.30.2:1234"
            // image labels
            // labels["vendor"] = "mycompany"
            // to add a raw list of additional build arguments, use
            // extraArgsForBuildCommand = listOf("...")
            // to add a raw list of additional push arguments, use
            // extraArgsForPushCommand = listOf("...")
            // image tags
            tags {
                // use current job run number as a tag - '0.0.run_number'
                +"50gramx.registry.jetbrains.space/p/main/ethosindiacontainers/eapp-pods-api:{{ VERSION_NUMBER }}"
                +"50gramx.registry.jetbrains.space/p/main/ethosindiacontainers/eapp-pods-api:latest"
            }
        }

        requirements {
            workerTags("windows-pool")
        }
    }
}

job("Build PodsSSH Image") {
    startOn {
        gitPush {
            anyBranchMatching {
                +"release-*"
                +"master"
                +"main"
                +"features*"
            }
        }
    }

    // To check a condition, basically, you need a kotlinScript step
    host(displayName = "Setup Version") {
        kotlinScript { api ->
            // Get the current year and month
            val currentYear = (LocalDate.now().year % 100).toString().padStart(2, '0')
            val currentMonth = LocalDate.now().monthValue.toString()

            // Get the execution number from environment variables
            val currentExecution = System.getenv("JB_SPACE_EXECUTION_NUMBER")

            // Set the VERSION_NUMBER parameter
            api.parameters["VERSION_NUMBER"] = "$currentYear.$currentMonth.$currentExecution"
        }

        requirements {
            workerTags("windows-pool")
        }
    }


    host("Build and push Pods API image") {


        shellScript {
            content = """
                docker login -u khetana -p dckr_pat_4S0EcsM5lO5Z1gxDT-q5NUkKf4U
            """
        }

        dockerBuildPush {
            
            file = "Dockerfile.podssh"
            
            // image tags
            val dockerHubRepo = "docker.io/ethosindia/eapp-terraform-infrastructure-podssh"

            tags {
                // use current job run number as a tag - '0.0.run_number'
                +"$dockerHubRepo:{{ VERSION_NUMBER }}"
                +"$dockerHubRepo:latest"
            }
        }

        requirements {
            workerTags("windows-pool")
        }
    }
}