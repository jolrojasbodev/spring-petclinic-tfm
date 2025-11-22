pipeline {
    agent {
        kubernetes {
            // YAML puro para control total
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  containers:
  # [FIX V2] Definimos explícitamente el agente JNLP para usar la imagen local
  - name: jnlp
    image: jenkins/inbound-agent:latest
    imagePullPolicy: IfNotPresent
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
  
  - name: maven
    image: maven:3.8.5-openjdk-17
    command: ["cat"]
    tty: true
    stdin: true
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        memory: "512Mi" 
        cpu: "500m"
        ephemeral-storage: "1Gi"
      limits:
        memory: "1Gi"
        cpu: "1000m"
        ephemeral-storage: "2Gi"
        
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
    stdin: true
    imagePullPolicy: IfNotPresent
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
                    echo "⏩ SKIPPING BUILD: Enfocando prueba en despliegue Kubernetes..."
                    // sh 'chmod +x mvnw'
                    // sh './mvnw clean package -DskipTests'
                }
            }
        }
        
        stage('Deploy to K3s') {
            steps {
                container('kubectl') {
                    echo "🚀 Iniciando prueba de despliegue en K3s..."
                    
                    sh 'kubectl get nodes'
                    
                    // Aplicamos manifiestos
                    sh 'kubectl apply -f k8s-manifests/mysql-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/vets-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-ingress.yaml'
                    
                    // Forzamos reinicio
                    sh 'kubectl rollout restart deployment/petclinic'
                    sh 'kubectl rollout restart deployment/vets-service'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ PRUEBA EXITOSA: El agente Kubernetes (JNLP + Kubectl) funciona correctamente.'
        }
        failure {
            echo '❌ FALLO: Revisa si la imagen jenkins/inbound-agent:latest está cargada en K3s.'
        }
    }
}