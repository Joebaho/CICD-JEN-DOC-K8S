pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        // Jenkins credentials: Username with password
        // username = Docker Hub username, password = Docker Hub token/password
        DOCKERHUB_CREDS = credentials('dockerhub')

        // Jenkins credentials: Username with password
        // username = AWS_ACCESS_KEY_ID, password = AWS_SECRET_ACCESS_KEY
        AWS_CREDS = credentials('aws-creds')

        AWS_DEFAULT_REGION = 'us-west-2'
        EKS_CLUSTER_NAME   = 'automated-demo-cluster'
        IMAGE_NAME         = 'fastapi-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tooling') {
            steps {
                sh '''
                    docker --version
                    aws --version
                    kubectl version --client
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${BUILD_NUMBER}", './app')
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
                        docker.image("${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${BUILD_NUMBER}").push()
                        docker.image("${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${BUILD_NUMBER}").push('latest')
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    export AWS_ACCESS_KEY_ID="${AWS_CREDS_USR}"
                    export AWS_SECRET_ACCESS_KEY="${AWS_CREDS_PSW}"
                    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"

                    aws eks update-kubeconfig --region "${AWS_DEFAULT_REGION}" --name "${EKS_CLUSTER_NAME}"

                    kubectl apply -f k8s/
                    kubectl set image deployment/fastapi-deployment fastapi-container=${DOCKERHUB_CREDS_USR}/${IMAGE_NAME}:${BUILD_NUMBER}
                    kubectl rollout status deployment/fastapi-deployment --timeout=180s
                '''
            }
        }

        stage('Show Service Endpoint') {
            steps {
                sh 'kubectl get svc fastapi-service -o wide'
            }
        }
    }
}
