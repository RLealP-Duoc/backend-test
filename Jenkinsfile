pipeline {
    agent any

    environment {
        // Tus datos
        DOCKERHUB_USER   = 'rlealp'
        DOCKERHUB_REPO   = 'backend-test'
        GITHUB_OWNER     = 'RLealP-Duoc'

        // IDs de credenciales en Jenkins
        DOCKERHUB_CRED_ID = 'dockerhub-creds'
        GHCR_CRED_ID      = 'ghcr-creds'

        // Namespace usado en kubernetes.yaml
        K8S_NAMESPACE = 'rleal'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Instalar dependencias') {
            steps {
                sh 'npm install'
            }
        }

        stage('Testing') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build app') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Build Docker image') {
            steps {
                script {
                    def localImageTag = "${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                    sh "docker build -t ${localImageTag} ."
                }
            }
        }

        stage('Push Docker Hub') {
            steps {
                script {
                    def imageTagBuild  = "${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                    def imageTagLatest = "${DOCKERHUB_USER}/${DOCKERHUB_REPO}:latest"

                    sh "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${imageTagBuild}"
                    sh "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${imageTagLatest}"

                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CRED_ID,
                                                     usernameVariable: 'DOCKER_USER',
                                                     passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker push ''' + imageTagBuild + '''
                            docker push ''' + imageTagLatest + '''
                            docker logout
                        '''
                    }
                }
            }
        }

        stage('Push GitHub Packages (ghcr.io)') {
            steps {
                script {
                    def ghcrBase      = "ghcr.io/${GITHUB_OWNER}/${DOCKERHUB_REPO}"
                    def ghcrTagBuild  = "${ghcrBase}:${BUILD_NUMBER}"
                    def ghcrTagLatest = "${ghcrBase}:latest"

                    sh "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${ghcrTagBuild}"
                    sh "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${ghcrTagLatest}"

                    withCredentials([usernamePassword(credentialsId: GHCR_CRED_ID,
                                                     usernameVariable: 'GH_USER',
                                                     passwordVariable: 'GH_TOKEN')]) {
                        sh '''
                            echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin
                            docker push ''' + ghcrTagBuild + '''
                            docker push ''' + ghcrTagLatest + '''
                            docker logout ghcr.io
                        '''
                    }
                }
            }
        }

        stage('Deploy a Kubernetes') {
            steps {
                script {
                    sh "kubectl get namespace ${K8S_NAMESPACE} || kubectl create namespace ${K8S_NAMESPACE}"

                    sh "kubectl apply -f kubernetes.yaml"

                    def ghcrImageBuild = "ghcr.io/${GITHUB_OWNER}/${DOCKERHUB_REPO}:${BUILD_NUMBER}"

                    sh """
                        kubectl set image deployment/backend-test-deployment \
                          backend-test=${ghcrImageBuild} \
                          -n ${K8S_NAMESPACE}
                    """

                    sh "kubectl rollout status deployment/backend-test-deployment -n ${K8S_NAMESPACE}"
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finalizado (éxito o fallo)."
        }
        success {
            echo "Pipeline OK - Build ${BUILD_NUMBER}"
        }
        failure {
            echo "Pipeline falló - revisar logs."
        }
    }
}