pipeline {
    agent { label 'terraform-agent' }

    options {
        timestamps()
        ansiColor('xterm')
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION      = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check AWS identity') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform'
                ]]) {
                    sh '''
                      echo "Probando conexión con AWS en la región ${AWS_REGION}..."
                      aws sts get-caller-identity --region ${AWS_REGION}
                    '''
                }
            }
        }

        stage('Checkov') {
            steps {
                sh '''
                  echo "==== Ejecutando Checkov sobre carpeta terraform/ ===="
                  chmod +x ci/run-checkov.sh
                  ci/run-checkov.sh
                '''
            }
        }

        stage('Terraform Plan (dev)') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-terraform'
                ]]) {
                    sh '''
                      echo "==== Ejecutando Terraform plan para entorno dev ===="
                      chmod +x ci/terraform-plan.sh
                      ci/terraform-plan.sh dev
                    '''
                }
            }
        }

        // Para el apply en futuro.
        // stage('Terraform Apply (manual)') {
        //     when {
        //         beforeAgent true
        //         expression { return env.BRANCH_NAME == 'develop' }
        //     }
        //     steps {
        //         input message: '¿Aplicar cambios en infraestructura dev?'
        //         withCredentials([[
        //             $class: 'AmazonWebServicesCredentialsBinding',
        //             credentialsId: 'aws-terraform'
        //         ]]) {
        //             sh '''
        //               echo "==== Ejecutando Terraform apply para entorno dev ===="
        //               ci/terraform-plan.sh dev apply
        //             '''
        //         }
        //     }
        // }
    }

    post {
        always {
            echo "Pipeline completado (Checkout + Checkov + Terraform plan)."
        }
    }
}