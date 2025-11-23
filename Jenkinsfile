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
        stage('Deploy Correcto (Namespace Default)') {
            steps {
                script {
                    echo "📦 Preparando entorno V19 (Fix Namespace)..."
                    sh 'rm -f *.yaml' 
                    
                    // Cache Buster para asegurar archivos frescos
                    def cb = System.currentTimeMillis()
                    def url = "https://raw.githubusercontent.com/jolrojasbodev/spring-petclinic-tfm/main/k8s-manifests"
                    
                    echo "⬇️ Descargando manifiestos..."
                    sh "curl -L -o mysql-deployment.yaml \"${url}/mysql-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-deployment.yaml \"${url}/petclinic-deployment.yaml?t=${cb}\""
                    sh "curl -L -o vets-deployment.yaml \"${url}/vets-deployment.yaml?t=${cb}\""
                    sh "curl -L -o petclinic-ingress.yaml \"${url}/petclinic-ingress.yaml?t=${cb}\""
                    
                    // Crear YAML con 2 réplicas explícito y namespace forzado
                    writeFile file: 'petclinic-deployment.yaml', text: '''
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petclinic
  namespace: default  # <--- FORZAMOS EL NAMESPACE EN EL YAML
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
          value: "jdbc:mysql://mysql-db.default.svc.cluster.local:3306/petclinic" # URL COMPLETA (FQDN) PARA EVITAR ERRORES DNS
        - name: SPRING_DATASOURCE_USERNAME
          value: "petclinic"
        - name: SPRING_DATASOURCE_PASSWORD
          value: "petclinic"
---
apiVersion: v1
kind: Service
metadata:
  name: petclinic-service
  namespace: default # <--- FORZAMOS EL NAMESPACE AQUÍ TAMBIÉN
spec:
  type: NodePort
  selector:
    app: petclinic
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
'''

                    if (!fileExists('kubectl')) {
                        sh "curl -L --retry 3 -o kubectl https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl"
                        sh "chmod +x kubectl"
                    }
                    
                    // [FIX IMPORTANTE] Limpieza previa de servicios conflictivos en AMBOS namespaces
                    echo "🧹 Limpiando servicios zombis (Puerto 30080)..."
                    sh "./kubectl delete service petclinic-service -n jenkins --ignore-not-found=true"
                    sh "./kubectl delete service petclinic-service -n default --ignore-not-found=true"

                    echo "🚀 Aplicando cambios en namespace DEFAULT..."
                    // Usamos -n default para asegurar el tiro
                    sh "./kubectl apply -f mysql-deployment.yaml -n default"
                    sh "./kubectl apply -f petclinic-deployment.yaml -n default" 
                    sh "./kubectl apply -f vets-deployment.yaml -n default"
                    sh "./kubectl apply -f petclinic-ingress.yaml -n default"
                    
                    echo "💀 Borrando pods viejos en DEFAULT..."
                    // Esto forzará que el Deployment en 'default' cree nuevos pods
                    sh "./kubectl delete pods -l app=petclinic -n default --wait=false"
                    
                    echo "🧹 Limpieza: Borrando despliegue accidental en namespace jenkins..."
                    // Borramos el error anterior para liberar recursos
                    sh "./kubectl delete deployment petclinic -n jenkins --ignore-not-found=true"
                    
                    echo "✅ Verificando pods en DEFAULT..."
                    sleep 10
                    sh "./kubectl get pods -l app=petclinic -n default"
                }
            }
        }
    }
    
    post {
        success { echo '✅ ÉXITO V19: Despliegue corregido en Default.' }
    }
}
