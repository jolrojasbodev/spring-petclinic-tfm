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
                    echo "📦 Preparando entorno V20 (Full Cleanup)..."
                    sh 'rm -f *.yaml' 
                    
                    def cb = System.currentTimeMillis()
                    def url = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    
                    echo "⬇️ Descargando manifiestos..."
                    sh "curl -L -o mysql-deployment.yaml \"${url}/mysql-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-deployment.yaml \"${url}/petclinic-deployment.yaml?t=${cb}\""
                    sh "curl -L -o vets-deployment.yaml \"${url}/vets-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-ingress.yaml \"${url}/petclinic-ingress.yaml?t=${cb}\""
                    
                    if (!fileExists('kubectl')) {
                        sh "curl -L --retry 3 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }
                    
                    // 1. LIMPIEZA PREVIA (Servicios zombis)
                    echo "🧹 Limpiando servicios zombis..."
                    sh "./kubectl delete service petclinic-service vets-service mysql-db -n jenkins --ignore-not-found=true"
                    sh "./kubectl delete deployment petclinic vets-service mysql-db -n jenkins --ignore-not-found=true"

                    // 2. DESPLIEGUE EN DEFAULT
                    echo "🚀 Aplicando cambios en namespace DEFAULT..."
                    sh "./kubectl apply -f mysql-deployment.yaml -n default"
                    sh "./kubectl apply -f petclinic-deployment.yaml -n default" 
                    sh "./kubectl apply -f vets-deployment.yaml -n default"
                    sh "./kubectl apply -f petclinic-ingress.yaml -n default"
                    
                    // 3. REINICIO FORZADO (Para Petclinic Y Vets)
                    echo "💀 Reiniciando TODOS los servicios..."
                    sh "./kubectl delete pods -l app=petclinic -n default --wait=false"
                    sh "./kubectl delete pods -l app=vets-service -n default --wait=false"
                    
                    echo "✅ Verificando pods en DEFAULT..."
                    sleep 10
                    sh "./kubectl get pods -n default"
                }
            }
        }
    }
    
    post {
        success { echo '✅ ÉXITO V20: Entorno limpio y actualizado.' }
    }
}
