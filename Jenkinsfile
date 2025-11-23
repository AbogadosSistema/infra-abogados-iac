pipeline {
    agent { label 'terraform-agent' }

    environment {
        AWS_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check AWS identity') {
            steps {
                // Vinculamos la credencial aws-terraform a variables de entorno
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
    }
}
