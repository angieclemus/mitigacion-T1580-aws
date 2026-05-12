# Arquitectura baseline — vulnerable

## Propósito

Esta arquitectura reproduce las **condiciones de exposición estructurales** documentadas en la literatura sobre seguridad en la nube y que permiten que la técnica T1580 tenga éxito. No está diseñada para ser desplegada en producción.

## Componentes y configuración intencionalmente débil

### Capa de cómputo
- **1 instancia EC2** Amazon Linux 2, tipo `t2.micro` o `t3.micro` (Free Tier).
- Security Group con reglas permisivas (puerto 22 abierto a `0.0.0.0/0`).
- Sin etiquetado de recursos, lo que dificulta el inventario.

### Capa de almacenamiento
- **Bucket S3 — `tesis-public-data`**: Block Public Access **desactivado**, ACL `public-read`, sin cifrado, sin versionado.
- **Bucket S3 — `tesis-internal-logs`**: Block Public Access activado parcialmente, sin política de bucket restrictiva, sin cifrado por defecto.
- **Bucket S3 — `tesis-backups`**: configuración por defecto de AWS, sin versionado ni cifrado.

### Capa de identidad
- **Usuario IAM `lab-attacker-victim`** (si el Learner Lab permite crearlo) con política `AdministratorAccess` o `*:*` sobre todos los recursos.
- Sin MFA.
- Credenciales programáticas activas (Access Key + Secret).
- En caso de que el Learner Lab no permita crear usuarios IAM, se usa el rol `voclabs` directamente como "identidad comprometida" y se documenta esta restricción metodológica.

### Capa de observabilidad
- **CloudTrail**: solo el Event History por defecto (90 días, sin trail personalizado).
- **CloudWatch**: sin alarmas configuradas.
- Sin logging de acceso en los buckets S3.

### Capa de resiliencia
- Sin snapshots de EBS programados.
- Sin versionado en buckets.

## Vectores de exposición habilitados

Esta configuración habilita los siguientes vectores asociados a T1580:

1. **Enumeración de instancias EC2** sin restricción ni detección.
2. **Listado de buckets S3** sin restricción; acceso público a contenido del bucket `tesis-public-data`.
3. **Enumeración completa de usuarios, roles y políticas IAM**.
4. **Imposibilidad de trazabilidad forense** posterior al incidente, dado que CloudTrail no está configurado con un trail dedicado.

## Diagrama

El diagrama visual de esta arquitectura está disponible en `source/01-baseline-vulnerable.drawio` (versión editable) y como imagen en este mismo directorio (`01-baseline-vulnerable.png`).

## Validación esperada

Al ejecutar Pacu contra esta arquitectura con las credenciales del usuario `lab-attacker-victim`, se espera:

- Listado exitoso de todos los buckets, instancias, usuarios, roles y políticas.
- Sin alarmas generadas.
- Sin trazabilidad clara más allá del Event History limitado.

Estos resultados constituyen la **línea base experimental** contra la cual se compara la arquitectura endurecida.
