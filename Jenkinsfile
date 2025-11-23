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
        stage('Deploy & Force Restart') {
            steps {
                script {
                    echo "🚀 Iniciando despliegue V16 (Estrategia Tierra Quemada)..."
                    
                    // 1. Descargar kubectl si no existe
                    if (!fileExists('kubectl')) {
                        sh "curl -L --retry 3 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }

                    // 2. Crear el YAML con 2 RÉPLICAS (Esto es lo que queremos ver)
                    writeFile file: 'petclinic-deployment.yaml', text: '''
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petclinic
spec:
  replicas: 2
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
                    
                    // 3. Aplicar configuración
                    echo "📄 Aplicando manifiesto..."
                    sh "./kubectl apply -f petclinic-deployment.yaml"
                    
                    // 4. LA CLAVE: Borrar pods viejos para forzar creación de nuevos
                    echo "💀 Borrando pods antiguos para forzar reinicio..."
                    sh "./kubectl delete pods -l app=petclinic --wait=false"
                    
                    // 5. Verificación visual
                    echo "👀 Esperando nuevos pods..."
                    sleep 10
                    sh "./kubectl get pods -l app=petclinic"
                }
            }
        }
    }
    
    post {
        success { echo '✅ ÉXITO V16: Pods recreados.' }
    }
}
