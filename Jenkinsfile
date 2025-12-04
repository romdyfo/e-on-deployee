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
                
                withCredentials([file(credentialsId: env.CREDENTIALS_ID, variable: 'GCP_KEY')]) {
                    sh """
                        gcloud auth activate-service-account --key-file=\${GCP_KEY}
                        gcloud config set project ${env.PROJECT_ID}
                        gcloud container clusters get-credentials ${env.CLUSTER_NAME} \
                            --zone ${env.LOCATION} \
                            --project ${env.PROJECT_ID}
                        
                        # k8s 파일 배포
                        kubectl apply -f k8s/
                        
                        # 배포 확인 (MySQL -> Backend -> Frontend 순서)
                        kubectl rollout status deployment/mysql -n default
                        kubectl rollout status deployment/backend -n default
                        kubectl rollout status deployment/frontend -n default
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
