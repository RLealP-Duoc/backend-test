pipeline {
    agent any

    environment {
        DOCKERHUB_USER    = 'rlealp'
        DOCKERHUB_REPO    = 'backend-test'
        GITHUB_OWNER      = 'RLealP-Duoc'  // Aquí puede ir con mayúsculas, la bajamos luego

        DOCKERHUB_CRED_ID = 'dockerhub-creds'
        GHCR_CRED_ID      = 'ghcr-creds'

        K8S_NAMESPACE     = 'rleal'
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
                    def localImageTag  = "${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                    def imageTagBuild  = "${DOCKERHUB_USER}/${DOCKERHUB_REPO}:${BUILD_NUMBER}"
                    def imageTagLatest = "${DOCKERHUB_USER}/${DOCKERHUB_REPO}:latest"

                    bat "docker tag ${localImageTag} ${imageTagBuild}"
                    bat "docker tag ${localImageTag} ${imageTagLatest}"

                    withCredentials([
                        usernamePassword(
                            credentialsId: DOCKERHUB_CRED_ID,
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        bat """
docker login -u %DOCKER_USER% -p %DOCKER_PASS%
docker push ${imageTagBuild}
docker push ${imageTagLatest}
docker logout
"""
                    }
                }
            }
        }

        stage('Push GitHub Packages (ghcr.io)') {
            steps {
                script {
                    def ownerLower = GITHUB_OWNER.toLowerCase()
                    def repoLower  = DOCKERHUB_REPO.toLowerCase()
                    def localImage = "${DOCKERHUB_REPO}:${BUILD_NUMBER}"

                    def ghcrBuild  = "ghcr.io/${ownerLower}/${repoLower}:${BUILD_NUMBER}"
                    def ghcrLatest = "ghcr.io/${ownerLower}/${repoLower}:latest"

                    bat "docker tag ${localImage} ${ghcrBuild}"
                    bat "docker tag ${localImage} ${ghcrLatest}"

                    withCredentials([
                        usernamePassword(
                            credentialsId: GHCR_CRED_ID,
                            usernameVariable: 'GH_USER',
                            passwordVariable: 'GH_TOKEN'
                        )
                    ]) {
                        bat """
docker login ghcr.io -u %GH_USER% -p %GH_TOKEN%
docker push ${ghcrBuild}
docker push ${ghcrLatest}
docker logout ghcr.io
"""
                    }
                }
            }
        }

        stage('Deploy a Kubernetes') {
            steps {
                script {
                    // Convertir aquí también a lowercase (este era el problema)
                    def ownerLower = GITHUB_OWNER.toLowerCase()
                    def repoLower  = DOCKERHUB_REPO.toLowerCase()

                    def ghcrImage = "ghcr.io/${ownerLower}/${repoLower}:${BUILD_NUMBER}"

                    // Aplicar manifiesto
                    bat "kubectl apply -f kubernetes.yaml"

                    // Este comando era el que quedaba con mayúsculas → corregido
                    bat "kubectl set image deployment/backend-test-deployment backend-test=${ghcrImage} -n ${K8S_NAMESPACE}"

                    // Esperar rollout
                    bat "kubectl rollout status deployment/backend-test-deployment -n ${K8S_NAMESPACE}"
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finalizado."
        }
        success {
            echo "Pipeline OK."
        }
        failure {
            echo "Pipeline falló."
        }
    }
}
