# EXP-02 — Implementación de los controles de la arquitectura endurecida

> **Propósito**: registrar control por control la aplicación de los mecanismos de mitigación propuestos, con la configuración aplicada, el comando ejecutado y la verificación posterior.

## Metadatos

| Campo | Valor |
| --- | --- |
| Identificador | EXP-02 |
| Fecha | YYYY-MM-DD a YYYY-MM-DD |
| Operadora | Angie Catalina Lemus Leiva |
| Objetivo específico | OE2 y OE3 |
| Arquitectura destino | Endurecida (ver `architecture/02-hardened.md`) |

## Estructura por control

Cada control se documenta con el siguiente esquema:

- **Identificador**: `CTL-NN`
- **Categoría**: IAM / S3 / EC2 / CloudTrail / CloudWatch / Resiliencia.
- **Marco de referencia**: control asociado en NIST CSF 2.0, NIST SP 800-210 o ISO/IEC 27017.
- **Descripción**.
- **Configuración aplicada** (JSON, CLI, captura de consola).
- **Verificación**: comando o procedimiento que confirma que el control está activo.
- **Resultado de la verificación**.

---

## CTL-01 — Block Public Access global en S3

- **Categoría**: S3
- **Marco**: NIST CSF 2.0 — PR.AC; ISO/IEC 27017 — CLD.9.5.
- **Descripción**: bloquear el acceso público a nivel de cuenta para prevenir la exposición no autorizada de buckets enumerados mediante T1580.

**Configuración aplicada**:
```bash
aws s3control put-public-access-block \
  --account-id <ACCOUNT_ID> \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile learner-lab
```

**Verificación**:
```bash
aws s3control get-public-access-block --account-id <ACCOUNT_ID> --profile learner-lab
```

**Resultado**: Control aplicado y verificado. Los cuatro parámetros de Block Public Access quedaron activos a nivel de cuenta:
- `BlockPublicAcls: true`
- `IgnorePublicAcls: true`
- `BlockPublicPolicy: true`
- `RestrictPublicBuckets: true`

Ningún bucket de la cuenta puede ser expuesto públicamente mientras este control esté activo.

**Captura**: `captures/CTL-01_block-public-access_20260515.png`


---

## CTL-02 — Cifrado por defecto en buckets S3

- **Categoría**: S3
- **Marco**: NIST CSF 2.0 — PR.DS; ISO/IEC 27017 — CLD.10.1.
- **Descripción**: ____

**Configuración aplicada**:
```powershell
aws s3api put-bucket-encryption --bucket tesis-baseline-13840 \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
```

---

## CTL-03 — Versionado y MFA Delete

- **Categoría**: S3 / Resiliencia
- **Marco**: NIST CSF 2.0 — RC.RP.

**Configuración aplicada**:
```powershell
aws s3api put-bucket-versioning --bucket tesis-baseline-13840 --versioning-configuration Status=Enabled
```

```powershell
aws s3api put-bucket-versioning `
  --bucket tesis-baseline-13840 `
  --versioning-configuration Status=Enabled `
  --profile learner-lab `
  --no-cli-pager
```
**Verificación**: aws s3api get-bucket-versioning --bucket tesis-baseline-13840
{  
    "Status": "Enabled"
}
---

## CTL-04 — Política de mínimo privilegio para identidad estándar

- **Categoría**: IAM
- **Marco**: NIST CSF 2.0 — PR.AC-4; NIST SP 800-210 §4.
- **Descripción**: política que deniega explícitamente las acciones de enumeración masiva asociadas a T1580 a identidades no privilegiadas.

**Configuración aplicada**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyT1580Enumeration",
      "Effect": "Deny",
      "Action": [
        "ec2:DescribeInstances", "ec2:DescribeImages", "ec2:DescribeSnapshots",
        "ec2:DescribeSecurityGroups", "ec2:DescribeVpcs", "ec2:DescribeSubnets",
        "s3:ListAllMyBuckets", "iam:ListUsers", "iam:ListRoles",
        "iam:ListPolicies", "iam:GetAccountAuthorizationDetails"
      ],
      "Resource": "*"
    }
  ]
}
```


> **Nota**: en el Learner Lab, ajustar el alcance al rol disponible.

**Configuración aplicada**:
Política `DenyT1580Enumeration` creada exitosamente (`arn:aws:iam::660XXXXXXX722:policy/DenyT1580Enumeration`). La política deniega explícitamente las acciones de enumeración asociadas a T1580: `ec2:DescribeInstances`, `ec2:DescribeImages`, `ec2:DescribeSnapshots`, `ec2:DescribeSecurityGroups`, `s3:ListAllMyBuckets`, `iam:ListUsers`, `iam:ListRoles`, `iam:ListPolicies`, entre otras.

**Limitación metodológica**: el rol `voclabs` no tiene permiso para ejecutar `iam:AttachRolePolicy`, por lo que la política no pudo adjuntarse a ningún rol del laboratorio. En un entorno de producción real, esta política se adjuntaría a roles de identidades estándar no privilegiadas para restringir la enumeración masiva. La política queda creada y disponible como artefacto verificable del control diseñado.

**Verificación**:
```powershell
aws iam get-policy --policy-arn arn:aws:iam::660XXXXXXX722:policy/DenyT1580Enumeration
```
**Resultado**: política creada, IsAttachable: true, AttachmentCount: 0 por restricción del laboratorio.
---

## CTL-05 — Habilitación de MFA

- **Categoría**: IAM
- **Marco**: NIST SP 800-63 (AAL2); NIST CSF 2.0 — PR.AC-7.
- **Descripción**: habilitación de MFA obligatorio para todas las identidades con acceso a la consola AWS, como segundo factor de autenticación para operaciones críticas.

**Configuración aplicada**: No aplicable en el entorno del Learner Lab. La habilitación de MFA requiere usuarios IAM con dispositivo MFA registrado. El laboratorio deniega iam:CreateUser y iam:CreateVirtualMFADevice, lo que impide implementar este control en el entorno experimental.

**Resultado**: Control documentado como limitación metodológica del laboratorio. Se referencia NIST SP 800-63B (AAL2) como estándar aplicable en producción.


---

## CTL-06 — Trail multirregión en CloudTrail

- **Categoría**: CloudTrail / Observabilidad
- **Marco**: NIST CSF 2.0 — DE.AE; ISO/IEC 27017 — CLD.12.4.
- **Descripción**: trail dedicado, multirregión, con registro de eventos de datos para S3.

**Configuración aplicada**:
```bash
aws cloudtrail create-trail \
  --name TesisT1580Trail \
  --s3-bucket-name <bucket-trail> \
  --is-multi-region-trail \
  --enable-log-file-validation \
  --profile learner-lab

aws cloudtrail start-logging --name TesisT1580Trail --profile learner-lab
```

**Verificación**:
```bash
aws cloudtrail describe-trails --trail-name-list TesisT1580Trail --profile learner-lab
aws cloudtrail get-trail-status --name TesisT1580Trail --profile learner-lab
```

**Resultado**: Trail `TesisT1580Trail` creado y logging activo (`IsLogging: true`). Trail multirregión, validación de integridad de logs habilitada, eventos globales de IAM incluidos. Logs almacenados en `s3://tesis-trail-65227`.


---

## CTL-07 — Alarma CloudWatch sobre llamadas Describe* anómalas

- **Categoría**: CloudWatch / Observabilidad
- **Marco**: NIST CSF 2.0 — DE.CM; NIST SP 800-210.
- **Descripción**: filtro de métrica sobre el log group de CloudTrail que cuenta llamadas `ec2:Describe*` y dispara alarma cuando supera un umbral.

**Pasos**:
1. Enviar logs de CloudTrail a un Log Group de CloudWatch Logs.
2. Crear filtro de métrica.
3. Crear alarma sobre la métrica.

**Configuración aplicada**: (pegar comandos reales tras ejecutarlos)

**Resultado**: 
1. Log group `CloudTrail/TesisT1580Trail` creado en CloudWatch Logs.
2. Trail actualizado para enviar eventos a CloudWatch Logs usando `LabRole`.
3. Filtro de métrica `T1580EnumerationCalls` activo — cuenta llamadas `Describe*` y `List*`.
4. Alarma `T1580-EnumerationDetected` creada: umbral 10 llamadas en 300 segundos. Estado inicial: `INSUFFICIENT_DATA` (esperado — sin tráfico aún).

**Captura**: `captures/CTL-07_cloudwatch-alarm_20260515.png`

---

## CTL-08 — Estrategia de respaldo (snapshots EBS y versionado S3)

- **Categoría**: Resiliencia
- **Marco**: NIST CSF 2.0 — RC.RP.
**Configuración aplicada**:
```powershell
aws ec2 create-snapshot --volume-id vol-005326b870783c755 --description "Tesis T1580 - snapshot baseline 2026-06-04"
```

**Resultado**: Snapshot snap-0d7e4d31b438b8340 creado exitosamente. Estado: completed (100%). Volumen origen: vol-005326b870783c755 (instancia tesis-baseline-server). Ante un ataque de borrado o cifrado malicioso de la instancia, este snapshot permite restaurar el estado previo.

---

## Tabla resumen de controles aplicados

| CTL-01 | Block Public Access global | S3 | ☑ Aplicado | captures/CTL-01_block-public-access_20260515.png |
| CTL-02 | Cifrado por defecto | S3 | ☑ Aplicado | captures/CTL-02_bucket-encryption_20260515.png |
| CTL-03 | Versionado y MFA Delete | S3 | ☑ Versionado aplicado / MFA Delete: limitación del lab | captures/CTL-03_versioning_20260515.png |
| CTL-04 | Mínimo privilegio | IAM | ☑ Política creada / Adjunción: limitación del lab | |
| CTL-05 | MFA | IAM | ⚠ Limitación metodológica del lab | |
| CTL-06 | Trail multirregión | CloudTrail | ☑ Aplicado | captures/CTL-06_cloudtrail-active_20260515.png |
| CTL-07 | Alarma Describe* | CloudWatch | ☑ Aplicado | captures/CTL-07_cloudwatch-alarm_20260515.png |
| CTL-08 | Respaldo y recuperación | EBS / S3 | ☑ Aplicado | captures/CTL-08_ebs-snapshot_20260515.png |

## Conclusión

Se implementaron 6 de 8 controles de forma completa (CTL-01, CTL-02, CTL-03, CTL-06, CTL-07, CTL-08). CTL-04 quedó con la política creada pero sin adjuntar por restricción del laboratorio (iam:AttachRolePolicy denegado). CTL-05 (MFA) no es aplicable en el entorno por la imposibilidad de crear usuarios IAM. Ambas limitaciones se documentan como restricciones metodológicas del Learner Lab y se discutirán en el capítulo de resultados. La arquitectura está lista para EXP-03.