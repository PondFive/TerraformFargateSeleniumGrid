pipeline {

    agent any

    stages {

        stage('Build') {
            steps {
                script {
                    docker.image('hashicorp/terraform:1.0.8').inside('--entrypoint ""') {
                        sh "terraform -chdir=terraform init -backend-config='key=selenium_grid_state' -input=false -reconfigure"
                        sh "terraform -chdir=terraform apply -var-file='terraform.tfvars' -refresh=true -auto-approve"
                    }
                }
            }

        }

    }
}
