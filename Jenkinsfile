pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        // Jenkins secret text credential IDs (must exist in Jenkins Credentials store)
        DOCKERHUB_USERNAME = credentials('DOCKERHUB_USERNAME')
        DOCKERHUB_TOKEN    = credentials('DOCKERHUB_TOKEN')
        AWS_ACCESS_KEY_ID  = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')

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
                sh '''
                    set -eu
                    docker build -t "${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${BUILD_NUMBER}" ./app
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    set -eu
                    echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
                    docker push "${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${BUILD_NUMBER}"
                    docker tag "${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${BUILD_NUMBER}" "${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
                    docker push "${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    set -eu
                    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"

                    aws eks update-kubeconfig --region "${AWS_DEFAULT_REGION}" --name "${EKS_CLUSTER_NAME}"

                    kubectl apply -f k8s/
                    kubectl set image deployment/fastapi-deployment fastapi-container=${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${BUILD_NUMBER}
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

    post {
        always {
            sh 'docker logout || true'
        }
    }
}
