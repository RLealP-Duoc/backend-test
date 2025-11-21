pipeline {
    agent any

    environment {
        DOCKERHUB_USER   = 'rlealp'
        DOCKERHUB_REPO   = 'backend-test'
        GITHUB_OWNER     = 'RLealP-Duoc'

        DOCKERHUB_CRED_ID = 'dockerhub-creds'
        GHCR_CRED_ID      = 'ghcr-creds'

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
                bat 'npm install'
            }
        }

        stage('Testing') {
            steps {
                // si los tests molestan mucho, luego podemos comentar esta línea
                bat 'npm test'
            }
        }

        stage('Build app') {
            steps {
                bat 'npm run build'
            }
        }

        stage('Build Docker image') {
            steps {
                script {
                    def localImageTag = "${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                    bat "docker build -t ${localImageTag} ."
                }
            }
        }

        stage('Push Docker Hub') {
            steps {
                script {
                    def imageTagBuild  = "${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                    def imageTagLatest = "${DOCKERHUB_USER}/${DOCKERHUB_REPO}:latest"

                    bat "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${imageTagBuild}"
                    bat "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${imageTagLatest}"

                    withCredentials([
                        usernamePassword(
                            credentialsId: DOCKERHUB_CRED_ID,
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        bat '''
docker login -u %DOCKER_USER% -p %DOCKER_PASS%
docker push %DOCKERHUB_USER%/%DOCKERHUB_REPO%:%BUILD_NUMBER%
docker push %DOCKERHUB_USER%/%DOCKERHUB_REPO%:latest
docker logout
'''
                    }
                }
            }
        }

        stage('Push GitHub Packages (ghcr.io)') {
            steps {
                script {
                    def ownerLower = GITHUB_OWNER.toLowerCase()
                    def repoLower = DOCKERHUB_REPO.toLowerCase()

                    def ghcrBase      = "ghcr.io/${ownerLower}/${repoLower}"
                    def ghcrTagBuild  = "${ghcrBase}:${BUILD_NUMBER}"
                    def ghcrTagLatest = "${ghcrBase}:latest"

                    bat "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${ghcrTagBuild}"
                    bat "docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${ghcrTagLatest}"

                    withCredentials([
                        usernamePassword(
                            credentialsId: GHCR_CRED_ID,
                            usernameVariable: 'GH_USER',
                            passwordVariable: 'GH_TOKEN'
                        )
                    ]) {
                        bat """
        docker login ghcr.io -u %GH_USER% -p %GH_TOKEN%
        docker push ${ghcrTagBuild}
        docker push ${ghcrTagLatest}
        docker logout ghcr.io
        """
                    }
                }
            }
        }


        stage('Deploy a Kubernetes') {
            steps {
                script {
                    bat "kubectl apply -f kubernetes.yaml"

                    def ghcrImageBuild = "ghcr.io/${GITHUB_OWNER}/${DOCKERHUB_REPO}:${BUILD_NUMBER}"

                    bat """
kubectl set image deployment/backend-test-deployment backend-test=${ghcrImageBuild} -n ${K8S_NAMESPACE}
"""
                    bat "kubectl rollout status deployment/backend-test-deployment -n ${K8S_NAMESPACE}"
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
