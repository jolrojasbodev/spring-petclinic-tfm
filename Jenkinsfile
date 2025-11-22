pipeline {
    agent {
        kubernetes {
            // [FIX V3] Recursos MINIMALISTAS para evitar OOM (Out Of Memory) en la VM de 4GB
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    imagePullPolicy: IfNotPresent
    tty: true
    resources:
      requests:
        memory: "128Mi" 
        cpu: "100m"
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
        # [CRÍTICO] Bajamos esto al mínimo porque solo vamos a hacer "echo"
        # En producción real necesitaremos más, pero para validar conectividad esto basta.
        memory: "64Mi" 
        cpu: "50m"
      limits:
        memory: "256Mi"
        
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
    stdin: true
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "128Mi"
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
                    echo "⏩ SKIPPING BUILD: Modo Ahorro de Energía (Low Memory Check)"
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
                    
                    // Reinicio
                    sh 'kubectl rollout restart deployment/petclinic'
                    sh 'kubectl rollout restart deployment/vets-service'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ PRUEBA EXITOSA: Pipeline V3 completado sin matar la VM.'
        }
        failure {
            echo '❌ FALLO: Revisa logs. Si Jenkins se reinició de nuevo, necesitas más SWAP o cerrar apps en el host.'
        }
    }
}