# Comandos de Pacu asociados a T1580

> Estos son los módulos de Pacu que mapean directamente a los procedimientos descritos para la técnica **T1580 — Cloud Infrastructure Discovery** del marco MITRE ATT&CK. Se ejecutan **exactamente en el mismo orden y con los mismos módulos** tanto contra la arquitectura baseline (EXP-01) como contra la endurecida (EXP-03) para garantizar comparabilidad fila por fila entre ambos experimentos.

## Preparación de la sesión

```text
pacu
> new_session <tesis-baseline | tesis-hardened>
> import_keys learner-lab
> services
> set_regions us-east-1
```

> El Learner Lab solo habilita las APIs relevantes en `us-east-1`. `set_regions us-east-1` evita que módulos sin flag `--regions` propio (como `detection__enum_services`) prueben otras regiones, reciban `ACCESS DENIED` y aborten la enumeración antes de llegar a `us-east-1`, produciendo falsos negativos.

## Bloque 1 — Enumeración de identidades (IAM)

```text
> run iam__enum_users_roles_policies_groups
> run iam__enum_permissions
> data IAM
```

Información esperada en `data IAM`:
- Lista completa de usuarios.
- Lista completa de roles y sus políticas.
- Lista completa de políticas gestionadas con sus documentos JSON.
- Lista de grupos.

## Bloque 2 — Enumeración de cómputo (EC2)

```text
> run ec2__enum --regions us-east-1
> data EC2
```

> Se restringe a `us-east-1` (igual que en EXP-01) porque el Learner Lab no tiene habilitadas las regiones "opt-in" (p. ej. `me-south-1`), lo que provoca `ConnectTimeoutError` si Pacu intenta recorrer todas las regiones por defecto.

Información esperada:
- Instancias por región (ID, tipo, estado, IP pública).
- Snapshots y volúmenes EBS.
- Security Groups y reglas.
- Key Pairs registrados.
- AMIs propias.

## Bloque 3 — Enumeración y exfiltración de almacenamiento (S3)

```text
> run s3__download_bucket
> data S3
```

> Igual que en EXP-01, este módulo intenta listar los buckets accesibles y descargar su contenido. En la arquitectura endurecida se espera que **CTL-01 (Block Public Access)** y la política de mínimo privilegio (CTL-04, si llegó a adjuntarse) impidan total o parcialmente el listado/descarga. El resultado de este bloqueo es la evidencia central de la efectividad del control.

## Bloque 4 — Enumeración de servicios de detección

```text
> run detection__enum_services
> data
```

Información esperada:
- Trails de CloudTrail configurados (se espera `TesisT1580Trail` activo por CTL-06).
- Detectores GuardDuty.
- Reglas de AWS Config.
- Alarmas CloudWatch (se espera `T1580-EnumerationDetected` por CTL-07).
- VPC Flow Logs.

Este módulo es el que permite contrastar directamente el resultado de EXP-01 ("0 CloudTrail Trail(s) found, 0 CloudWatch Alarm(s) found") contra el estado endurecido.

## Captura de evidencia

Antes y después de cada módulo, ejecutar `data` para registrar el estado acumulado y exportarlo:

```text
> export_keys
> data > pacu-output-<bloque>.json
```

O desde la sesión del shell anfitrión, redirigir la salida completa de Pacu a un archivo de log temporal (no incluido en el repo).

## Verificación cruzada en AWS

Después de cada bloque, desde una terminal aparte:

```bash
# Verificar lo que CloudTrail Event History registró
aws cloudtrail lookup-events \
  --max-results 50 \
  --lookup-attributes AttributeKey=EventName,AttributeValue=ListUsers \
  --profile learner-lab

# Verificar el estado de las alarmas (solo aplicable en EXP-03)
aws cloudwatch describe-alarms --state-value ALARM --profile learner-lab
```

## Tabla resumen para EXP-01 / EXP-03

| Bloque | Módulo | Llamadas API generadas (aprox.) | Recurso objetivo |
| --- | --- | --- | --- |
| 1 | `iam__enum_users_roles_policies_groups` | `ListUsers`, `ListRoles`, `ListGroups`, `ListPolicies`, `GetPolicy`, `GetPolicyVersion` | IAM |
| 1 | `iam__enum_permissions` | `GetAccountAuthorizationDetails`, `SimulatePrincipalPolicy` | IAM |
| 2 | `ec2__enum` | `DescribeInstances`, `DescribeSnapshots`, `DescribeVolumes`, `DescribeSecurityGroups`, `DescribeKeyPairs`, `DescribeImages` | EC2 |
| 3 | `s3__download_bucket` | `ListAllMyBuckets`, `GetBucketLocation`, `GetBucketAcl`, `GetBucketPolicy`, `GetObject` | S3 |
| 4 | `detection__enum_services` | `DescribeTrails`, `ListDetectors`, `DescribeConfigRules`, `DescribeAlarms`, `DescribeFlowLogs` | CloudTrail / GuardDuty / Config / CloudWatch / VPC |

Estas llamadas son exactamente las que se monitorean en las alarmas de CloudWatch de la arquitectura endurecida (CTL-07).
