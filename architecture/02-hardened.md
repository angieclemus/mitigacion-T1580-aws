# Arquitectura endurecida

## Propósito

Esta arquitectura aplica los controles de mitigación propuestos en el trabajo de grado, alineados con NIST SP 800-210, ISO/IEC 27017 y el AWS Well-Architected Framework (pilar de seguridad). Su objetivo es **reducir la superficie de ataque** frente a T1580 y **generar visibilidad detectable** sobre los intentos de enumeración.

## Componentes y controles aplicados

### Capa de cómputo
- **1 instancia EC2** Amazon Linux 2, tipo `t2.micro` o `t3.micro`.
- Security Group con reglas mínimas (solo los puertos estrictamente necesarios, idealmente acceso por SSM Session Manager y no SSH directo).
- IMDSv2 obligatorio (`HttpTokens: required`) para prevenir el robo de credenciales de instancia.
- Etiquetado completo: `Project`, `Environment`, `Owner`, `Classification`.

### Capa de almacenamiento
- **Block Public Access** activado a nivel de cuenta (no solo por bucket).
- **Cifrado por defecto** SSE-S3 (AES-256) en todos los buckets.
- **Versionado** activado en buckets con datos relevantes.
- **Políticas de bucket** restrictivas que solo permiten acceso a principales autorizados, con condiciones de origen (`aws:SourceIp`, `aws:SecureTransport: true`).
- **Logging de acceso** habilitado hacia un bucket dedicado.

### Capa de identidad
- **Principio de mínimo privilegio**: políticas granulares que permiten solo las acciones estrictamente necesarias por rol funcional.
- **MFA obligatorio** para todos los usuarios con acceso a la consola (donde el Learner Lab lo permita).
- **Rotación** de credenciales programáticas.
- **Permission Boundaries** aplicados a los roles más sensibles.
- **Sin políticas con `Action: "*"` o `Resource: "*"`**.
- Eliminación de usuarios y claves no utilizados.

### Capa de observabilidad
- **AWS CloudTrail** con trail multirregión habilitado, registrando eventos de gestión y eventos de datos para S3.
- **Logs de CloudTrail** almacenados en un bucket dedicado con política que impide su modificación o eliminación.
- **AWS CloudWatch** con alarmas configuradas para:
  - Volúmenes anómalos de llamadas `ec2:Describe*` por unidad de tiempo.
  - Volúmenes anómalos de llamadas `s3:ListBuckets` o `s3:ListObjects`.
  - Volúmenes anómalos de llamadas `iam:List*` y `iam:Get*`.
  - Cualquier llamada exitosa desde una IP no autorizada.

### Capa de resiliencia
- **Snapshots automáticos** de EBS para la instancia EC2.
- **Versionado** activado en S3 con política de retención.
- **Estrategia de recuperación** documentada y probada.

## Vectores de exposición mitigados

| Vector original | Control aplicado |
| --- | --- |
| Enumeración EC2 sin restricción | IAM denegando `ec2:Describe*` a identidades no autorizadas |
| Listado de buckets sin restricción | IAM denegando `s3:ListAllMyBuckets`; Block Public Access global |
| Enumeración completa de IAM | Política denegando `iam:List*` salvo a roles administrativos específicos |
| Sin trazabilidad | Trail dedicado, logs inmutables, alarmas activas |
| Sin detección | Alarmas de CloudWatch sobre patrones de enumeración |

## Diagrama

El diagrama visual de esta arquitectura está disponible en `source/02-hardened.drawio` (versión editable) y como imagen en este mismo directorio (`02-hardened.png`).

## Validación esperada

Al ejecutar Pacu contra esta arquitectura con las credenciales del usuario "comprometido":

- La mayoría de los módulos de enumeración fallan con `AccessDenied`.
- Las llamadas que sí se ejecutan generan **alarmas en CloudWatch** que se documentan como evidencia.
- El **trail de CloudTrail** captura cada llamada con metadatos completos (identidad, IP de origen, parámetros).
- El **respaldo y la recuperación** se validan restaurando un snapshot.

La comparación entre la respuesta de la arquitectura baseline y la endurecida ante el mismo ataque constituye la **evidencia empírica central** del trabajo de grado.
