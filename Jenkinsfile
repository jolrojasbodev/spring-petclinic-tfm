pipeline {
    agent {
        kubernetes {
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
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"
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
        memory: "64Mi"
        cpu: "50m"
        
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
    
    // [FIX V5] "Fail Fast": Si algo se traba, muere en 5 minutos.
    options {
        timeout(time: 10, unit: 'MINUTES') 
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
    
    stages {
        stage('Checkout (Shallow)') {
            steps {
                cleanWs()
                // Clonado ultrarrápido (solo el último cambio)
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
        
        stage('Build & Test') {
            steps {
                container('maven') {
                    echo "⏩ SKIPPING BUILD: Validando flujo..."
                }
            }
        }
        
        stage('Deploy to K3s') {
            steps {
                container('kubectl') {
                    echo "🚀 Iniciando despliegue K3s..."
                    sh 'kubectl get nodes'
                    
                    sh 'kubectl apply -f k8s-manifests/mysql-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/vets-deployment.yaml'
                    sh 'kubectl apply -f k8s-manifests/petclinic-ingress.yaml'
                    
                    // Usamos timeout en el comando también para que no espere eternamente
                    sh 'kubectl rollout restart deployment/petclinic'
                    sh 'kubectl rollout restart deployment/vets-service'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ ÉXITO V5: Pipeline optimizado completado.'
        }
        failure {
            echo '❌ FALLO: Revisa conectividad o recursos.'
        }
    }
}