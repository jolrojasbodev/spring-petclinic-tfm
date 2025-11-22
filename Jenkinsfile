pipeline {
    agent {
        kubernetes {
            // [V7 FINAL LITE]
            // Recuperamos el contenedor 'kubectl' para poder desplegar.
            // Mantenemos recursos bajos.
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
    }
    
    stages {
        stage('Checkout (Rápido)') {
            steps {
                cleanWs()
                // Descarga solo el último commit (KBs en vez de MBs)
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: 'main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/jolrojasbodev/spring-petclinic-tfm.git',
                        credentialsId: 'github-credentials'
                    ]],
                    extensions: [[$class: 'CloneOption', depth: 1, shallow: true, noTags: true, reference: '']]
                ])
            }
        }
        
        stage('Deploy to K3s') {
            steps {
                container('kubectl') {
                    echo "🚀 Desplegando PetClinic en K3s..."
                    
                    // Verificamos nodos
                    sh 'kubectl get nodes'
                    
                    // Aplicamos configuración
                    sh 'kubectl apply -f k8s-manifests/mysql-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/vets-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-ingress.yaml'
                    
                    // Reiniciamos pods para asegurar que tomen la config
                    sh 'kubectl rollout restart deployment/petclinic'
                    sh 'kubectl rollout restart deployment/vets-service'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ FASE 2 COMPLETADA: CI/CD Funcional.'
        }
    }
}
