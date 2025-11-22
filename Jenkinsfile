pipeline {
    agent {
        kubernetes {
            // [V12 FINAL]
            // Estrategia Single Container + Timeout extendido para redes lentas.
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
        // [FIX V12] Aumentamos a 20 minutos para dar tiempo a la descarga lenta de kubectl
        timeout(time: 20, unit: 'MINUTES')
        skipDefaultCheckout()
    }
    
    stages {
        stage('Setup & Deploy') {
            steps {
                script {
                    echo "📦 Preparando entorno..."
                    
                    // Limpiamos solo archivos YAML viejos, pero intentamos conservar kubectl si existe
                    sh 'rm -f *.yaml' 
                    
                    // 1. Descargar Manifiestos
                    def baseUrl = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    sh "curl -O ${baseUrl}/mysql-deployment.yaml"
                    sh "curl -O ${baseUrl}/petclinic-deployment.yaml"
                    sh "curl -O ${baseUrl}/vets-deployment.yaml"
                    sh "curl -O ${baseUrl}/petclinic-ingress.yaml"
                    
                    // 2. Descargar binario de Kubectl (con caché)
                    if (fileExists('kubectl')) {
                        echo "✅ kubectl ya existe, saltando descarga."
                    } else {
                        echo "⬇️ Descargando kubectl (47MB)... (Paciencia, red lenta)"
                        // Usamos curl con reintentos y verbose para ver progreso
                        sh "curl -L --retry 3 --retry-delay 5 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }
                    
                    // 3. Desplegar
                    echo "🚀 Desplegando..."
                    sh "./kubectl get nodes"
                    
                    sh "./kubectl apply -f mysql-deployment.yaml"
                    sh "./kubectl apply -f petclinic-deployment.yaml"
                    sh "./kubectl apply -f vets-deployment.yaml"
                    sh "./kubectl apply -f petclinic-ingress.yaml"
                    
                    // 4. Reiniciar
                    sh "./kubectl rollout restart deployment/petclinic"
                    sh "./kubectl rollout restart deployment/vets-service"
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ FASE 2 COMPLETADA: Despliegue Exitoso.'
        }
    }
}
