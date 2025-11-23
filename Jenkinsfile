pipeline {
    agent {
        kubernetes {
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
                    echo "📦 Preparando entorno (V13 Anti-Cache)..."
                    sh 'rm -f *.yaml' 
                    
                    // Timestamp para romper caché
                    def cb = System.currentTimeMillis()
                    def url = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    
                    echo "⬇️ Descargando manifiestos FRESCOS..."
                    // Usamos ?t= para obligar a GitHub a darnos lo nuevo
                    sh "curl -L -o mysql-deployment.yaml \"${url}/mysql-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-deployment.yaml \"${url}/petclinic-deployment.yaml?t=${cb}\""
                    sh "curl -L -o vets-deployment.yaml \"${url}/vets-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-ingress.yaml \"${url}/petclinic-ingress.yaml?t=${cb}\""
                    
                    // Depuración: Mostrar qué bajamos realmente
                    sh "grep 'replicas:' petclinic-deployment.yaml"

                    // Kubectl
                    if (!fileExists('kubectl')) {
                        sh "curl -L --retry 3 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }
                    
                    echo "🚀 Desplegando..."
                    sh "./kubectl apply -f mysql-deployment.yaml"
                    sh "./kubectl apply -f petclinic-deployment.yaml"
                    sh "./kubectl apply -f vets-deployment.yaml"
                    sh "./kubectl apply -f petclinic-ingress.yaml"
                    
                    sh "./kubectl rollout restart deployment/petclinic"
                }
            }
        }
    }
    
    post {
        success { echo '✅ ÉXITO V13' }
    }
}
