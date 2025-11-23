pipeline {
    agent {
        kubernetes {
            // [V13 FINAL ANTI-CACHE]
            // Misma estrategia Single Container, pero forzando descarga fresca de GitHub.
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
                    echo "📦 Preparando entorno..."
                    sh 'rm -f *.yaml' 
                    
                    // Generamos un timestamp para romper la caché de GitHub
                    def cacheBuster = System.currentTimeMillis()
                    def baseUrl = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    
                    echo "⬇️ Descargando manifiestos FRESCOS (Bypass Cache)..."
                    // Usamos -o para guardar con nombre fijo, pero añadimos ?t=... a la URL
                    sh "curl -L -o mysql-deployment.yaml \"${baseUrl}/mysql-deployment.yaml?t=${cacheBuster}\""
                    sh "curl -L -o petclinic-deployment.yaml \"${baseUrl}/petclinic-deployment.yaml?t=${cacheBuster}\""
                    sh "curl -L -o vets-deployment.yaml \"${baseUrl}/vets-deployment.yaml?t=${cacheBuster}\""
                    sh "curl -L -o petclinic-ingress.yaml \"${baseUrl}/petclinic-ingress.yaml?t=${cacheBuster}\""
                    
                    // Imprimimos para verificar que bajó lo correcto (Depuración)
                    sh "grep 'replicas:' petclinic-deployment.yaml"

                    // Descarga de Kubectl (con caché local si existe)
                    if (fileExists('kubectl')) {
                        echo "✅ kubectl ya existe."
                    } else {
                        echo "⬇️ Descargando kubectl..."
                        sh "curl -L --retry 3 --retry-delay 5 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }
                    
                    echo "🚀 Desplegando..."
                    sh "./kubectl apply -f mysql-deployment.yaml"
                    sh "./kubectl apply -f petclinic-deployment.yaml"
                    sh "./kubectl apply -f vets-deployment.yaml"
                    sh "./kubectl apply -f petclinic-ingress.yaml"
                    
                    // Reinicio forzado para que se note el cambio
                    sh "./kubectl rollout restart deployment/petclinic"
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ FASE 2 COMPLETADA: Despliegue actualizado.'
        }
    }
}
