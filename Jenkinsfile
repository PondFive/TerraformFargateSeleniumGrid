pipeline {
    agent any
    triggers {
        pollSCM 'H/10 * * * *'
    }
    stages {
        stage('Build') {
            steps {
                script {
                    docker.image('hashicorp/terraform:1.0.10').inside('--entrypoint ""') {
                        sh "terraform -chdir=terraform init -backend-config='key=selenium_grid_state' -input=false -reconfigure"
                        sh "terraform -chdir=terraform apply -var-file='terraform.tfvars' -refresh=true -auto-approve"
                    }
                }
            }
        }
    }
}
