# Infraestructura como Código (opcional)

Este directorio queda reservado para futuras plantillas de **CloudFormation** o **Terraform** que automaticen el despliegue de la arquitectura endurecida.

Para el alcance del trabajo de grado, el despliegue se hace **manualmente desde la consola y la CLI** para preservar la trazabilidad pedagógica de cada paso en las evidencias. Una versión futura del trabajo podría incluir plantillas IaC como mejora.

## Estructura propuesta (cuando se implemente)

```
iac/
├── cloudformation/
│   ├── 01-iam-controls.yaml
│   ├── 02-s3-hardening.yaml
│   └── 03-observability.yaml
└── terraform/
    └── (alternativa equivalente)
```
