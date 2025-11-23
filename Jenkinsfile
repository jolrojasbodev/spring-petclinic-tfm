pipeline {
    agent {
        kubernetes {
            // [V15 FINAL FORCE RESTART]
            // Single Container + Timeout + Force Rollout
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-deploy-single
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    imagePullPolicy: IfNotPresent
    tty: true
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
'''
        }
    }
    
    options {
        timeout(time: 20, unit: 'MINUTES')
        skipDefaultCheckout()
    }
    
    stages {
        stage('Setup & Deploy') {
            steps {
                script {
                    echo "📦 Preparando entorno (V15)..."
                    sh 'rm -f *.yaml' 
                    
                    // Cache Buster
                    def cb = System.currentTimeMillis()
                    def url = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    
                    echo "⬇️ Descargando manifiestos..."
                    sh "curl -L -o mysql-deployment.yaml \"${url}/mysql-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-deployment.yaml \"${url}/petclinic-deployment.yaml?t=${cb}\""
                    sh "curl -L -o vets-deployment.yaml \"${url}/vets-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-ingress.yaml \"${url}/petclinic-ingress.yaml?t=${cb}\""
                    
                    // Kubectl check
                    if (!fileExists('kubectl')) {
                        sh "curl -L --retry 3 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }
                    
                    echo "🚀 Aplicando cambios..."
                    sh "./kubectl apply -f mysql-deployment.yaml"
                    sh "./kubectl apply -f petclinic-deployment.yaml"
                    sh "./kubectl apply -f vets-deployment.yaml"
                    sh "./kubectl apply -f petclinic-ingress.yaml"
                    
                    echo "🔄 FORZANDO REINICIO DE PODS..."
                    // Este comando OBLIGA a crear pods nuevos, poniendo el contador AGE a 0m
                    sh "./kubectl rollout restart deployment/petclinic"
                    sh "./kubectl rollout restart deployment/vets-service"
                    
                    echo "✅ Esperando a que el rollout termine..."
                    // Esperamos a que el reinicio se complete antes de marcar éxito
                    sh "./kubectl rollout status deployment/petclinic --timeout=5m"
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ FASE 2 COMPLETADA: Pods reiniciados exitosamente.'
        }
    }
}
