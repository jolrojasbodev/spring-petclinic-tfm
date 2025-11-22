pipeline {
    agent {
        kubernetes {
            // [V6 SANITY CHECK]
            // Sin Maven, sin Kubectl, sin límites complejos.
            // Solo verificamos que Jenkins puede hablar con K3s.
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-sanity-test
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    imagePullPolicy: IfNotPresent
    tty: true
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
'''
        }
    }
    
    options {
        timeout(time: 2, unit: 'MINUTES') 
    }
    
    stages {
        stage('Hola Mundo') {
            steps {
                script {
                    echo "-------------------------------------------------"
                    echo "✅ ¡HOLA MUNDO! SI LEES ESTO, JENKINS ESTÁ VIVO."
                    echo "-------------------------------------------------"
                    
                    echo "1. Verificando identidad:"
                    sh 'whoami'
                    
                    echo "2. Verificando Java:"
                    sh 'java -version'
                    
                    echo "3. Verificando sistema de archivos:"
                    sh 'ls -la'
                }
            }
        }
    }
}