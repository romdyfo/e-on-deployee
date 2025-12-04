pipeline {
    agent any

    environment {
        PROJECT_ID    = 'open-source-gcp'
        CLUSTER_NAME  = 'eon-cluster'
        LOCATION      = 'asia-northeast3-a'
        CREDENTIALS_ID = 'gcp-sa-key'

        // 도커 허브 이미지 이름 기본 값
        BE_IMAGE_NAME = "e-on-backend"
        FE_IMAGE_NAME = "e-on-frontend"
    }

    stages {

        stage('Check Files After Checkout') {
            steps {
                sh 'echo "📂 Workspace contents:"'
                sh 'ls -R .'
            }
        }
        stage('Debug Workspace') {
            steps {
                sh 'pwd'
                sh 'ls -al'
            }
        }

        stage('Checkout') {
            steps {
                echo "➡️ Checking out Repository..."
                // Jenkins에 등록된 GitHub Credential 사용
                git(
                    branch: 'main',
                    url: 'https://github.com/romdyfo/e-on-deployee.git',
                    credentialsId: 'github-token',
                    changelog: false,
                    poll: false
                )
            }
        }

        stage('Load Secrets') {
            steps {
                echo "🔐 Loading DockerHub & Vite Secrets..."

                withCredentials([
                    string(credentialsId: 'dockerhub-id-text', variable: 'DOCKERHUB_ID'),
                    string(credentialsId: 'vite-api-url', variable: 'VITE_URL')
                ]) {
                    // withEnv 없이 environment 변수 적용
                    script {
                        env.DOCKERHUB_ID_TEXT = DOCKERHUB_ID
                        env.VITE_API_URL      = VITE_URL
                    }
                }
            }
        }

        stage('Build Backend') {
            steps {
                echo "🐳 Building Backend Image..."
                sh """
                    docker build \
                        -t ${env.DOCKERHUB_ID_TEXT}/${env.BE_IMAGE_NAME}:latest \
                        -f backend/Dockerfile backend
                """
            }
        }

        stage('Build Frontend') {
            steps {
                echo "🌐 Building Frontend Image..."
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
                echo "📤 Pushing images to DockerHub..."

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
            when {
                branch 'main'
            }
            steps {
                echo "🚀 Deploying to GKE..."

                step([$class: 'KubernetesEngineBuilder',
                    projectId: env.PROJECT_ID,
                    clusterName: env.CLUSTER_NAME,
                    location: env.LOCATION,
                    manifestPattern: [
                        'k8s/backend-deployment.yaml',
                        'k8s/frontend-deployment.yaml',
                        'k8s/mysql-deployment.yaml'
                    ],
                    credentialsId: env.CREDENTIALS_ID,
                    verifyDeployments: true
                ])
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning workspace..."
            cleanWs()
        }
    }
}
