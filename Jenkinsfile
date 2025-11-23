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
        timeout(time: 10, unit: 'MINUTES')
        skipDefaultCheckout()
    }
    
    stages {
        stage('Deploy & Cleanup') {
            steps {
                script {
                    echo "📦 Preparando entorno V18 (Port Cleanup)..."
                    sh 'rm -f *.yaml' 
                    
                    def cb = System.currentTimeMillis()
                    def url = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    
                    // Descargar kubectl si hace falta
                    if (!fileExists('kubectl')) {
                        sh "curl -L --retry 3 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }

                    echo "⬇️ Descargando manifiestos..."
                    sh "curl -L -o mysql-deployment.yaml \"${url}/mysql-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-deployment.yaml \"${url}/petclinic-deployment.yaml?t=${cb}\""
                    sh "curl -L -o vets-deployment.yaml \"${url}/vets-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-ingress.yaml \"${url}/petclinic-ingress.yaml?t=${cb}\""
                    
                    // [FIX V18] ELIMINAR EL SERVICIO ZOMBI QUE OCUPA EL PUERTO 30080
                    echo "🧹 Liberando puerto 30080 (Borrando servicios viejos)..."
                    // Borramos en 'jenkins' (el error probable) y en 'default' (por si acaso)
                    sh "./kubectl delete service petclinic-service -n jenkins --ignore-not-found=true"
                    sh "./kubectl delete service petclinic-service -n default --ignore-not-found=true"
                    
                    echo "🚀 Aplicando configuración..."
                    sh "./kubectl apply -f mysql-deployment.yaml -n default"
                    sh "./kubectl apply -f petclinic-deployment.yaml -n default"
                    sh "./kubectl apply -f vets-deployment.yaml -n default"
                    sh "./kubectl apply -f petclinic-ingress.yaml -n default"
                    
                    echo "💀 Forzando recreación de pods..."
                    sh "./kubectl delete pods -l app=petclinic -n default --wait=false"
                    
                    echo "✅ Verificando..."
                    sleep 10
                    sh "./kubectl get pods -l app=petclinic -n default"
                }
            }
        }
    }
    
    post {
        success { echo '✅ ÉXITO V18: Puerto liberado y pods recreados.' }
    }
}