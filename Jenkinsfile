// Jenkinsfile (선언형으로 만듦)

pipeline { 
    agent any

    environment {
		    PROJECT_ID = 'open-source-gcp' //본인 프로젝트 아이디
		    CLUSTER_NAME = 'eon-cluster' //본인 클러스터 이름
		    LOCATION = 'asia-northeast3-a'  //본인 클러스터 지역
		    CREDENTIALS_ID = 'gcp-sa-key'//젠킨스 크레덴셜로 등록할 아이디
		    
		    // --도커 허브 & 프론트엔드 설정--
        DOCKERHUB_ID_TEXT = credentials('dockerhub-id-text') //도커아이디
        VITE_API_URL = credentials('vite-api-url') //프론트엔드 API 주소

        // --- 불러온 변수를 사용해 이미지 이름 조합하기 ---
        BE_IMAGE_NAME = "${DOCKERHUB_ID_TEXT}/e-on-backend"
        FE_IMAGE_NAME = "${DOCKERHUB_ID_TEXT}/e-on-frontend"
    }

    stages {
        stage('Checkout') { //깃클론 효
            steps {
                git branch: 'main', url: 'https://github.com/romdyfo/e-on-deployee.git'
            }
        }

        //병렬 제거하고 순차적으로 실행
        stage('Build Backend') {
            steps {
                // 백엔드 Dockerfile로 이미지 빌드
                sh "docker build -t ${BE_IMAGE_NAME}:latest -f backend/Dockerfile ./backend"
            }
        }
        stage('Build Frontend') {
            steps {
                // 프론트엔드 Dockerfile로 이미지 빌드 (build-arg로 API 주소 주입)
                sh "docker build --build-arg VITE_API_URL=${VITE_API_URL} -t ${FE_IMAGE_NAME}:latest -f frontend/Dockerfile ./frontend"
            }
        }

        stage('Push Images to Docker Hub') {
            steps {
                // 사용자가 젠킨스에서 'dockerhub-id'로 생성한 Username/Password Credential 사용
                withCredentials([usernamePassword(credentialsId: 'dockerhub-id', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh "echo ${PASS} | docker login -u ${USER} --password-stdin"
                    sh "docker push ${BE_IMAGE_NAME}:latest"
                    sh "docker push ${FE_IMAGE_NAME}:latest"
                    sh "docker logout" // post 블록 대신 여기서 정리
                }
            }
        }

        stage('Deploy to GKE') {
            when{
                branch 'main'
            }
            steps {
                // 교수님 강의자료에 나온 'KubernetesEngineBuilder' 플러그인 사용
                step([$class: 'KubernetesEngineBuilder',
                    projectId: env.PROJECT_ID,       
                    clusterName: env.CLUSTER_NAME,                   
                    location: env.LOCATION,
                    manifestPattern: 'k8s/*.yaml',          
                    credentialsId: env.CREDENTIALS_ID,           
                    verifyDeployments: true])
            }
        }
    }
        
    post { // 파이프라인이 끝나면 항상 실행
        always {
            echo 'Cleaning up Jenkins workspace...'
            // sh 명령어는 각 stage에서 처리했으므로 여기서는 작업 공간만 정리
            cleanWs()
        }
    }
}