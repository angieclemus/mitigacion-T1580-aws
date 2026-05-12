# EXP-03 — Ejecución de Pacu contra la arquitectura endurecida

> **Propósito**: comparar la respuesta del laboratorio frente al **mismo ataque** que en EXP-01, ahora con los controles de la arquitectura endurecida activos. Esta es la evidencia central que valida la efectividad de los controles propuestos.

## Metadatos

| Campo | Valor |
| --- | --- |
| Identificador | EXP-03 |
| Fecha | YYYY-MM-DD |
| Operadora | Angie Catalina Lemus Leiva |
| Objetivo específico | OE3 |
| Arquitectura objetivo | Endurecida (`architecture/02-hardened.md`) |
| Identidad utilizada | **Idéntica a EXP-01** para garantizar comparabilidad |
| Versión de Pacu | (misma que en EXP-01) |

## Ejecución de los módulos (mismos comandos que EXP-01)

| # | Módulo | Resultado EXP-01 (baseline) | Resultado EXP-03 (endurecida) |
| --- | --- | --- | --- |
| 1 | `iam__enum_users_roles_policies_groups` | (copiar de EXP-01) | ____ |
| 2 | `iam__enum_permissions` | | ____ |
| 3 | `ec2__enum` | | ____ |
| 4 | `s3__bucket_finder` | | ____ |
| 5 | `lightsail__enum` | | ____ |

## Detección y respuesta

### Alarmas generadas en CloudWatch

| Hora | Alarma | Servicio | Detalle |
| --- | --- | --- | --- |
| HH:MM | (nombre) | EC2 | (n.º de llamadas anómalas) |
| HH:MM | (nombre) | S3 | |
| HH:MM | (nombre) | IAM | |

### Eventos capturados en CloudTrail

Consulta tras la prueba:
```bash
aws cloudtrail lookup-events \
  --max-results 100 \
  --start-time "$(date -u -d '1 hour ago' --iso-8601=seconds)" \
  --profile learner-lab
```

- **N.º de eventos capturados**: ____
- **Identidad solicitante**: ____
- **Dirección IP de origen**: ____ (debe corresponder a la IP de la máquina de pruebas)

### Eventos bloqueados (AccessDenied)

Listar las llamadas que fueron denegadas por las políticas IAM aplicadas.

## Métricas comparativas

| Métrica | Baseline (EXP-01) | Endurecida (EXP-03) | Δ (mejora) |
| --- | --- | --- | --- |
| Recursos enumerados (instancias) | __ | __ | __ |
| Recursos enumerados (buckets) | __ | __ | __ |
| Usuarios/roles enumerados | __ | __ | __ |
| % de llamadas exitosas | __ % | __ % | __ p.p. |
| Alarmas generadas | 0 | __ | __ |
| Trazabilidad forense disponible | Limitada | Completa | — |
| Tiempo desde la primera llamada anómala hasta la primera alarma | N/A | __ s | — |

## Capturas asociadas

- `captures/EXP-03_pacu-denied-outputs_YYYYMMDD.png`
- `captures/EXP-03_cloudwatch-alarms_YYYYMMDD.png`
- `captures/EXP-03_cloudtrail-events_YYYYMMDD.png`

## Validación de resiliencia

Adicionalmente, simular la pérdida de un objeto en S3 o de un volumen EBS y restaurar:

- **Snapshot EBS restaurado**: sí / no, tiempo de restauración.
- **Versión anterior de objeto S3 restaurada**: sí / no.

## Conclusión

Síntesis comparativa: qué controles bloquearon qué llamadas, qué nivel de detección se alcanzó y cuál es la efectividad agregada del conjunto de controles frente a T1580 en este entorno experimental. Esta conclusión alimenta directamente el capítulo de resultados de la tesis.
