pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-deploy-agent
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
'''
        }
    }
    
    options {
        timeout(time: 5, unit: 'MINUTES')
        skipDefaultCheckout() // Importante: No dejar que Jenkins toque Git
    }
    
    stages {
        stage('Descargar Manifiestos') {
            steps {
                cleanWs()
                script {
                    // En lugar de clonar todo el repo, bajamos solo lo que necesitamos.
                    // Usamos el contenedor JNLP que tiene herramientas de red.
                    echo "📥 Descargando manifiestos RAW desde GitHub..."
                    
                    // Base URL del repo (rama main)
                    def baseUrl = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    
                    // Descarga manual de los 4 archivos
                    sh "curl -O ${baseUrl}/mysql-deployment.yaml"
                    sh "curl -O ${baseUrl}/petclinic-deployment.yaml"
                    sh "curl -O ${baseUrl}/vets-deployment.yaml"
                    sh "curl -O ${baseUrl}/petclinic-ingress.yaml"
                    
                    sh "ls -la *.yaml" // Verificar que bajaron
                }
            }
        }
        
        stage('Deploy to K3s') {
            steps {
                container('kubectl') {
                    echo "🚀 Desplegando PetClinic en K3s..."
                    
                    // Como no usamos 'checkout', Jenkins NO intentará ejecutar git aquí.
                    // Los archivos .yaml están en el workspace compartido.
                    
                    sh 'kubectl apply -f mysql-deployment.yaml'
                    sh 'kubectl apply -f petclinic-deployment.yaml'
                    sh 'kubectl apply -f vets-deployment.yaml'
                    sh 'kubectl apply -f petclinic-ingress.yaml'
                    
                    // Reinicio
                    sh 'kubectl rollout restart deployment/petclinic'
                    sh 'kubectl rollout restart deployment/vets-service'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ FASE 2 COMPLETADA: CI/CD Funcional (Modo No-Git).'
        }
    }
}
