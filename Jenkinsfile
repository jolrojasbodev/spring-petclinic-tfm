pipeline {
    agent {
        kubernetes {
            // [V11 SINGLE CONTAINER]
            // Usamos SOLO el agente JNLP. No definimos contenedores extra.
            // Esto evita que Jenkins intente sincronizar Git donde no debe.
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
        timeout(time: 5, unit: 'MINUTES')
        skipDefaultCheckout()
    }
    
    stages {
        stage('Setup & Deploy') {
            steps {
                cleanWs()
                script {
                    echo "📦 Preparando entorno en contenedor JNLP..."
                    
                    // 1. Descargar Manifiestos (Igual que V10)
                    def baseUrl = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    sh "curl -O ${baseUrl}/mysql-deployment.yaml"
                    sh "curl -O ${baseUrl}/petclinic-deployment.yaml"
                    sh "curl -O ${baseUrl}/vets-deployment.yaml"
                    sh "curl -O ${baseUrl}/petclinic-ingress.yaml"
                    
                    // 2. Descargar binario de Kubectl (Ya que no tenemos el contenedor aparte)
                    echo "🔧 Bajando kubectl..."
                    sh "curl -LO https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                    sh "chmod +x kubectl"
                    
                    // 3. Desplegar usando el binario local (./kubectl)
                    echo "🚀 Desplegando..."
                    sh "./kubectl get nodes" // Verificar conexión
                    
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
            echo '✅ FASE 2 COMPLETADA: Despliegue Exitoso (V11).'
        }
    }
}
