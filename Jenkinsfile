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
        stage('Deploy Directo') {
            steps {
                script {
                    echo "🚀 Desplegando configuración incrustada (V14)..."

                    // Bajamos kubectl (única dependencia externa)
                    if (!fileExists('kubectl')) {
                        sh "curl -L --retry 3 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }

                    // ESCRIBIMOS EL YAML AQUÍ MISMO. ¡SIN INTERMEDIARIOS!
                    // Fíjate en 'replicas: 2'
                    writeFile file: 'petclinic-deployment.yaml', text: '''
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petclinic
spec:
  replicas: 2  # <--- ¡AQUÍ ESTÁ EL CAMBIO QUE QUEREMOS VER!
  selector:
    matchLabels:
      app: petclinic
  template:
    metadata:
      labels:
        app: petclinic
    spec:
      containers:
      - name: petclinic
        image: docker.io/library/petclinic-monolito:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "mysql"
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:mysql://mysql-db:3306/petclinic"
        - name: SPRING_DATASOURCE_USERNAME
          value: "petclinic"
        - name: SPRING_DATASOURCE_PASSWORD
          value: "petclinic"
---
apiVersion: v1
kind: Service
metadata:
  name: petclinic-service
spec:
  type: NodePort
  selector:
    app: petclinic
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
'''

                    // Aplicamos
                    sh "./kubectl apply -f petclinic-deployment.yaml"

                    // Verificamos
                    sh "./kubectl get pods -l app=petclinic"
                }
            }
        }
    }

    post {
        success { echo '✅ Despliegue completado.' }
    }
}
