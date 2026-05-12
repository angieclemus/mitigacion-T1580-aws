# Comandos de Pacu asociados a T1580

> Estos son los módulos de Pacu que mapean directamente a los procedimientos descritos para la técnica **T1580 — Cloud Infrastructure Discovery** del marco MITRE ATT&CK. Se ejecutan en el mismo orden tanto contra la arquitectura baseline (EXP-01) como contra la endurecida (EXP-03) para garantizar comparabilidad.

## Preparación de la sesión

```text
pacu
> new_session <tesis-baseline | tesis-hardened>
> import_keys learner-lab
> services
```

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
> run ec2__enum
> data EC2
```

Información esperada:
- Instancias por región (ID, tipo, estado, IP pública).
- Snapshots y volúmenes EBS.
- Security Groups y reglas.
- Key Pairs registrados.
- AMIs propias.

## Bloque 3 — Enumeración de almacenamiento (S3)

```text
> run s3__bucket_finder
> data S3
```

Para profundizar (solo si se aplica al diseño experimental y respeta el límite de presupuesto):

```text
> run s3__download_bucket
```

> ⚠ El módulo `s3__download_bucket` descarga el contenido de los buckets accesibles. **No ejecutarlo** salvo en la fase baseline y limitado al bucket público creado intencionalmente con datos ficticios.

## Bloque 4 — Otros servicios IaaS

Opcional, en función del alcance del laboratorio:

```text
> run lightsail__enum
> run rds__enum
```

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
| 3 | `s3__bucket_finder` | `ListAllMyBuckets`, `GetBucketLocation`, `GetBucketAcl`, `GetBucketPolicy` | S3 |

Estas llamadas son exactamente las que se monitorean en las alarmas de CloudWatch de la arquitectura endurecida (CTL-07).
