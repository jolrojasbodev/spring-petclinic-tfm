pipeline {
    agent {
        kubernetes {
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
        skipDefaultCheckout()  // <--- ¡ESTO ES LA CLAVE! No descargará nada de GitHub.
    }
    
    stages {
        stage('Hola Mundo') {
            steps {
                script {
                    echo "-------------------------------------------------"
                    echo "✅ ¡HOLA MUNDO! SI LEES ESTO, JENKINS ESTÁ VIVO."
                    echo "-------------------------------------------------"
                    sh 'echo "Jenkins se ha comunicado con Kubernetes correctamente."'
                }
            }
        }
    }
}
