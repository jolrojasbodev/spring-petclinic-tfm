pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8.5-openjdk-17
    command:
    - cat
    tty: true
    stdin: true
    resources:
      requests:
        memory: "2Gi"
        ephemeral-storage: "2Gi"
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
    stdin: true
'''
        }
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/jolrojasbodev/spring-petclinic-tfm.git' 
            }
        }
        
        stage('Build & Test') {
            steps {
                container('maven') {
                    sh './mvnw clean package -DskipTests'
                }
            }
        }
        
        stage('Deploy to Dev') {
            steps {
                container('kubectl') {
                    // Aplicamos los manifiestos
                    sh 'kubectl apply -f k8s-manifests/petclinic-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/vets-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-ingress.yaml'
                }
            }
        }
    }
}