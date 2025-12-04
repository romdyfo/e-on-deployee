pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    environment {
        PROJECT_ID    = 'open-source-gcp'
        CLUSTER_NAME  = 'eon-cluster'
        LOCATION      = 'asia-northeast3-a'
        CREDENTIALS_ID = 'gcp-sa-key'

        BE_IMAGE_NAME = "e-on-backend"
        FE_IMAGE_NAME = "e-on-frontend"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "➡️ Checking out Repository..."
                git(
                    branch: 'main',
                    url: 'https://github.com/romdyfo/e-on-deployee.git',
                    credentialsId: 'github-token',
                    changelog: false,
                    poll: false
                )
            }
        }

        stage('Debug Workspace') {
            steps {
                sh 'echo "📂 Workspace:"'
                sh 'pwd'
                sh 'ls -R .'
            }
        }

        stage('Load Secrets') {
            steps {
                withCredentials([
                    string(credentialsId: 'dockerhub-id-text', variable: 'DOCKERHUB_ID'),
                    string(credentialsId: 'vite-api-url', variable: 'VITE_URL')
                ]) {
                    script {
                        env.DOCKERHUB_ID_TEXT = DOCKERHUB_ID
                        env.VITE_API_URL      = VITE_URL
                    }
                }
            }
        }

        stage('Build Backend') {
            steps {
                sh """
                    docker build \
                        -t ${env.DOCKERHUB_ID_TEXT}/${env.BE_IMAGE_NAME}:latest \
                        -f backend/Dockerfile backend
                """
            }
        }

        stage('Build Frontend') {
            steps {
                sh """
                    docker build \
                        --build-arg VITE_API_URL=${env.VITE_API_URL} \
                        -t ${env.DOCKERHUB_ID_TEXT}/${env.FE_IMAGE_NAME}:latest \
                        -f frontend/Dockerfile frontend
                """
            }
        }

        stage('Push Images to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-id',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${env.DOCKERHUB_ID_TEXT}/${env.BE_IMAGE_NAME}:latest"
                    sh "docker push ${env.DOCKERHUB_ID_TEXT}/${env.FE_IMAGE_NAME}:latest"
                    sh "docker logout"
                }
            }
        }

        stage('Deploy to GKE') {
            when { branch 'main' }
            steps {
                echo "🚀 Deploying to GKE..."
                step([$class: 'KubernetesEngineBuilder',
                    projectId: env.PROJECT_ID,
                    clusterName: env.CLUSTER_NAME,
                    location: env.LOCATION,
                    manifestPattern: 'k8s/*.yaml',
                    credentialsId: env.CREDENTIALS_ID,
                    verifyDeployments: true
                ])
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
