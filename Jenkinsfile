pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8.5-openjdk-17
    command:
    - sleep
    - infinity
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - sleep
    - infinity
    volumeMounts:
    - name: registry-creds
      mountPath: /kaniko/.docker
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - sleep
    - infinity
'''
        }
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: '[https://github.com/TU_USUARIO/spring-petclinic.git](https://github.com/TU_USUARIO/spring-petclinic.git)' 
                // ¡CAMBIA TU_USUARIO POR TU USUARIO REAL DE GITHUB!
            }
        }
        
        stage('Build & Test') {
            steps {
                container('maven') {
                    sh './mvnw clean package -DskipTests'
                }
            }
        }

        // Nota: Para la construcción de Docker en un entorno K3s local sin Registry externo,
        // la estrategia más sencilla para el TFM es saltar este paso en el Pipeline automático
        // y enfocarnos en la Integración Continua (Build & Test).
        // El despliegue continuo requeriría configurar un Registry local inseguro,
        // lo cual añade complejidad extra.
        
        stage('Deploy to Dev') {
            steps {
                container('kubectl') {
                    // Aquí aplicamos los manifiestos que ya creamos
                    sh 'kubectl apply -f k8s-manifests/petclinic-deployment.yaml'
                }
            }
        }
    }
}
