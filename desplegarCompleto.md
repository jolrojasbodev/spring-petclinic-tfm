Manual de Despliegue: Spring PetClinic en Kubernetes (K3s) + JenkinsEste manual describe paso a paso cómo desplegar la infraestructura completa desde cero en una máquina virtual limpia (Ubuntu). Incluye la instalación de Docker, K3s, Jenkins y el despliegue de la aplicación PetClinic.Requisitos previos:Máquina Virtual con Ubuntu (22.04 o superior).Mínimo 4GB de RAM (Recomendado 6GB+).Acceso a Internet.Puerto 8080 libre (No tener otro Jenkins o Tomcat instalado).1. Preparación del Entorno (Fase de Sistema)Primero, actualizamos el sistema, limpiamos conflictos y preparamos las herramientas.1.1. Limpieza de Puertos (Anti-Conflictos)Antes de instalar nada, aseguramos que no haya procesos "zombis" ocupando puertos críticos.# Detener contenedores Docker sueltos que puedan estorbar
sudo docker stop $(sudo docker ps -aq) 2>/dev/null
sudo docker rm $(sudo docker ps -aq) 2>/dev/null

# Verificar que el puerto 8080 esté libre
sudo lsof -i :8080
✅ Verificación:El comando lsof no debe devolver nada. Si sale algo, mata el proceso con sudo kill -9 <PID>.1.2. Instalar Docker y HerramientasNecesitamos Docker para construir la imagen.# Actualizar sistema e instalar básicos
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io curl git unzip

# Dar permisos a tu usuario (requiere cerrar sesión o usar newgrp)
sudo usermod -aG docker $USER
newgrp docker
✅ Verificación:Ejecuta: docker run hello-worldEsperado: Mensaje "Hello from Docker!".1.3. Instalar K3s (Kubernetes Ligero)Instalamos K3s desactivando componentes innecesarios para ahorrar RAM.curl -sfL [https://get.k3s.io](https://get.k3s.io) | INSTALL_K3S_EXEC="server --disable traefik --disable metrics-server --write-kubeconfig-mode 644" sh -
✅ Verificación:Ejecuta: kubectl get nodesEsperado:NAME          STATUS   ROLES                  AGE   VERSION
tu-maquina    Ready    control-plane,master   30s   v1.xx.x+k3s1
1.4. Configurar Permisos de KubectlPara que tu usuario pueda controlar el clúster sin sudo.sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
✅ Verificación:Ejecuta: kubectl auth can-i create podsEsperado: yes2. Preparación del Proyecto (Fase de Construcción)2.1. Clonar el Repositoriocd ~
git clone [https://github.com/jolrojasbodev/spring-petclinic-tfm.git](https://github.com/jolrojasbodev/spring-petclinic-tfm.git)
cd spring-petclinic-tfm
✅ Verificación:Ejecuta: ls -FEsperado: Ver carpetas como src/, k8s-manifests/ y el archivo Dockerfile.2.2. Construir la Imagen de la Appsudo docker build -t petclinic-monolito:latest .
✅ Verificación:Ejecuta: docker images | grep petclinicEsperado: Una línea mostrando petclinic-monolito y un tamaño aprox de 300-500MB.2.3. Importar la Imagen a K3s (Side-loading)Paso Crítico: Sin esto, Kubernetes dará error ErrImageNeverPull.# 1. Exportar a archivo
sudo docker save petclinic-monolito:latest > petclinic-image.tar

# 2. Importar a K3s
sudo k3s ctr images import petclinic-image.tar
✅ Verificación:Ejecuta: sudo k3s ctr images list | grep petclinicEsperado: Debe aparecer docker.io/library/petclinic-monolito:latest.3. Despliegue de Jenkins3.1. Aplicar Manifiestos y Permisos# Namespace y Permisos (RBAC)
kubectl apply -f spring-petclinic/k8s-manifests/jenkins-namespace.yaml
kubectl apply -f jenkins-rbac.yaml

# Permiso Maestro para la cuenta 'default' (Soluciona errores 401/403)
kubectl create clusterrolebinding jenkins-default-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=jenkins:default

# Desplegar Servidor
kubectl apply -f spring-petclinic/k8s-manifests/jenkins-deployment.yaml
✅ Verificación:Ejecuta: kubectl get svc -n jenkinsEsperado: Ver jenkins-service con puertos 8080:30000/TCP y 50000:30087/TCP.3.2. Esperar arranquekubectl get pods -n jenkins -w
✅ Verificación:Esperar hasta ver estado 1/1 Running.4. Configuración Inicial de Jenkins4.1. Obtener Acceso y DesbloquearURL: http://<TU_IP_VM>:30000Obtener Clave:kubectl exec -it $(kubectl get pod -l app=jenkins -n jenkins -o jsonpath='{.items[0].metadata.name}') -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
Instalar "Suggested Plugins".Crear usuario administrador.4.2. Configuración de Identidad (CRÍTICO)Este paso previene el error "Invalid X-Instance-Identity".Ir a Manage Jenkins > System.Buscar Jenkins Location.Jenkins URL: Cambiar la IP externa por la interna:👉 http://jenkins-service.jenkins.svc.cluster.local:8080/Save.✅ Verificación:No hay comando, pero si ves la URL interna guardada, está bien. Si cambias esto más tarde, debes reiniciar el pod de Jenkins.5. Configuración de la Nube (Cloud)Instalar Plugin: Ir a Manage Jenkins > Plugins > Available, buscar Kubernetes, instalar y reiniciar.Crear Nube: Ir a Manage Jenkins > Clouds > New Cloud.Name: kubernetesType: KubernetesConfigurar Detalles:Kubernetes URL: https://kubernetes.default (o dejar vacío).Kubernetes Namespace: jenkinsCredentials: - none - (Dejar vacío).Jenkins URL: http://jenkins-service.jenkins.svc.cluster.local:8080Jenkins tunnel: jenkins-service.jenkins.svc.cluster.local:50000Use WebSocket: ⬜ Desmarcado.✅ Verificación:Dale al botón "Test Connection".Esperado: Mensaje Connected to Kubernetes v1.xx... 🟢.6. Ejecución del PipelineCrear tarea Pipeline.Repo URL: https://github.com/jolrojasbodev/spring-petclinic-tfmScript Path: JenkinsfileBuild Now.✅ Verificación:Ver la consola del Build.Esperado:Created Pod...Agent connected (Si falla aquí, revisar paso 4.2 y 5).Finished: SUCCESS.7. Verificación Final (Acceso a la App)Una vez el pipeline termine:7.1. Verificar Pods de la Appkubectl get pods -n default
✅ Verificación:Todos los pods (petclinic, mysql, vets) deben estar en 1/1 Running.Si ves ErrImageNeverPull, repite el paso 2.3.7.2. Acceso WebAverigua el puerto asignado (si usas NodePort) o entra por el Ingress (puerto 80).Opción A (Ingress - Puerto 80):http://<TU_IP_VM>Opción B (NodePort - Verificar puerto):kubectl get svc petclinic-service -n default
(Si sale 80:32000/TCP, entra por el puerto 32000).✅ Verificación Final:Abrir navegador. Debes ver la pantalla de bienvenida de Spring PetClinic.