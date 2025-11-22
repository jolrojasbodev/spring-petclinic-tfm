pipeline {
    agent {
        kubernetes {
            // YAML puro para control total sobre recursos y comandos del agente
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  containers:
  - name: maven
    image: maven:3.8.5-openjdk-17
    command: ["cat"]
    tty: true
    stdin: true
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
        ephemeral-storage: "1Gi"
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
    stdin: true
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
'''
        }
    }
    
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/jolrojasbodev/spring-petclinic-tfm.git'
            }
        }
        
        stage('Build & Test') {
            steps {
                container('maven') {
                    // [MODIFICACIÓN V1] Saltamos la compilación para probar rápido la conexión a K8s
                    echo "⏩ SKIPPING BUILD: Enfocando prueba en despliegue Kubernetes..."
                    // sh 'chmod +x mvnw'
                    // sh './mvnw clean package -DskipTests'
                }
            }
        }
        
        stage('Build Image (Simulation)') {
            steps {
                script {
                    echo "⚠️ SKIPPING DOCKER BUILD: Entorno Air-gapped/Local."
                }
            }
        }
        
        stage('Deploy to K3s') {
            steps {
                container('kubectl') {
                    echo "🚀 Iniciando prueba de despliegue en K3s..."
                    
                    // 1. Verificamos identidad y conexión
                    sh 'kubectl get nodes'
                    sh 'kubectl cluster-info'
                    
                    // 2. Aplicamos manifiestos (La prueba de fuego)
                    sh 'kubectl apply -f k8s-manifests/mysql-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/vets-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-ingress.yaml'
                    
                    // 3. Forzamos reinicio
                    sh 'kubectl rollout restart deployment/petclinic'
                    sh 'kubectl rollout restart deployment/vets-service'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ PRUEBA EXITOSA: El agente Kubernetes funciona y ha desplegado los manifiestos.'
        }
        failure {
            echo '❌ FALLO: El agente o la conexión a K3s siguen fallando.'
        }
    }
}