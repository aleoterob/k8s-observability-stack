Objetivo:
Desplegar servicios de monitoreo en Kubernetes utilizando exclusivamente Helm charts:

- Grafana
- Prometheus

El proyecto debe estar pensado siguiendo prácticas modernas de DevOps y Kubernetes, priorizando que funcione de forma estable en equipos locales con Kind o Minikube.

Requisitos:

1. Estructura del repositorio

Organizar el repo con la siguiente estructura:

helm/
grafana/
prometheus/

k8s/
namespaces/
ingress/
secrets/
configs/

docs/
scripts/
.github/workflows/

Descripción:

- `helm/` -> values.yaml y configuraciones Helm de cada servicio
- `k8s/namespaces` -> namespaces
- `k8s/ingress` -> ingress y networking
- `k8s/secrets` -> secrets templates y ejemplos
- `k8s/configs` -> manifests auxiliares
- `docs/` -> documentación
- `scripts/` -> automatización local
- `.github/workflows/` -> CI/CD

2. Setup de Kubernetes

- Utilizar únicamente Helm charts oficiales o ampliamente adoptados.
- Todo debe funcionar localmente sobre:
  - Minikube O
  - Kind
- Preferir configuraciones livianas por defecto.
- El proyecto debe soportar Linux, macOS y Windows PowerShell.

3. Prometheus

- Utilizar el chart oficial:
  - prometheus-community/kube-prometheus-stack
- Configurar:
  - almacenamiento persistente
  - scraping de métricas del cluster
  - scraping de una aplicación de ejemplo
- Exponer Prometheus mediante ClusterIP.
- Configurar resource requests/limits.

4. Grafana

- Utilizar el chart oficial de Grafana.
- Configurar:
  - almacenamiento persistente
  - datasource automático de Prometheus
  - dashboards iniciales provisionados automáticamente
- Crear usuario administrador mediante Kubernetes Secret.
- Exponer Grafana vía NodePort o Ingress.
- Configurar readiness y liveness probes.

5. Extras opcionales de observabilidad

Agregar soporte opcional para:

- Loki
- Tempo
- OpenTelemetry Collector

Estos componentes deben:

- estar deshabilitados por defecto
- poder habilitarse fácilmente mediante values.yaml

6. Scripts de automatización

Crear:

- `scripts/start.sh`
- `scripts/stop.sh`
- `scripts/reset.sh`
- scripts equivalentes para Windows PowerShell

Los scripts deben:

- crear namespaces
- agregar repositorios Helm necesarios
- instalar charts
- validar despliegues
- mostrar URLs y comandos útiles

7. Experiencia de desarrollo

Agregar comandos documentados para:

- port-forward
- logs
- troubleshooting
- health checks
- reinicio de pods
- acceso a dashboards

8. CI/CD

Agregar GitHub Actions workflow para:

- validar YAML
- ejecutar helm lint
- validar estructura del repositorio
- ejecutar kubeconform o kubeval si es posible

9. Buenas prácticas

- Usar namespaces separados.
- No hardcodear credenciales.
- Usar ConfigMaps y Secrets correctamente.
- Mantener manifests y values.yaml modulares.
- Configurar resource requests/limits.
- Configurar readiness y liveness probes.
- Seguir convenciones modernas de Kubernetes.

10. Documentación

Generar un README.md profesional incluyendo:

- arquitectura del stack
- explicación de cada componente
- prerequisitos
- instalación paso a paso
- comandos útiles
- troubleshooting
- cleanup
- ejemplos de acceso local

11. Resultado esperado

El usuario debe poder ejecutar:

./scripts/start.sh

o en Windows:

.\scripts\start.ps1

y obtener:

- Grafana funcionando
- Prometheus recolectando métricas

con mínima configuración manual.
