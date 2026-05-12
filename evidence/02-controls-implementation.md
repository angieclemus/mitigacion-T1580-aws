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

**Resultado**: ____

**Captura**: `captures/CTL-01_block-public-access_YYYYMMDD.png`

---

## CTL-02 — Cifrado por defecto en buckets S3

- **Categoría**: S3
- **Marco**: NIST CSF 2.0 — PR.DS; ISO/IEC 27017 — CLD.10.1.
- **Descripción**: ____

**Configuración aplicada**: ____

**Verificación**: ____

---

## CTL-03 — Versionado y MFA Delete

- **Categoría**: S3 / Resiliencia
- **Marco**: NIST CSF 2.0 — RC.RP.
- **Descripción**: ____

---

## CTL-04 — Política de mínimo privilegio para identidad estándar

- **Categoría**: IAM
- **Marco**: NIST CSF 2.0 — PR.AC-4; NIST SP 800-210 §4.
- **Descripción**: política que deniega explícitamente las acciones de enumeración masiva asociadas a T1580 a identidades no privilegiadas.

**Política de ejemplo (a documentar la final aplicada)**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyEnumerationT1580",
      "Effect": "Deny",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "s3:ListAllMyBuckets",
        "iam:ListUsers",
        "iam:ListRoles",
        "iam:ListPolicies",
        "iam:GetAccountAuthorizationDetails"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalTag/Role": "SecurityAdmin"
        }
      }
    }
  ]
}
```

> **Nota**: en el Learner Lab, ajustar el alcance al rol disponible.

---

## CTL-05 — Habilitación de MFA

- **Categoría**: IAM
- **Marco**: NIST SP 800-63 (AAL2); NIST CSF 2.0 — PR.AC-7.
- **Descripción**: ____

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

**Resultado**: ____

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

---

## CTL-08 — Estrategia de respaldo (snapshots EBS y versionado S3)

- **Categoría**: Resiliencia
- **Marco**: NIST CSF 2.0 — RC.RP.

---

## Tabla resumen de controles aplicados

| ID | Control | Servicio | Estado | Evidencia |
| --- | --- | --- | --- | --- |
| CTL-01 | Block Public Access global | S3 | ☐ Aplicado | captures/CTL-01_*.png |
| CTL-02 | Cifrado por defecto | S3 | ☐ | |
| CTL-03 | Versionado y MFA Delete | S3 | ☐ | |
| CTL-04 | Mínimo privilegio | IAM | ☐ | |
| CTL-05 | MFA | IAM | ☐ | |
| CTL-06 | Trail multirregión | CloudTrail | ☐ | |
| CTL-07 | Alarma Describe* | CloudWatch | ☐ | |
| CTL-08 | Respaldo y recuperación | EBS / S3 | ☐ | |

## Conclusión

(Resumir, una vez completados los controles, qué quedó aplicado, qué se adaptó por restricciones del lab y cuál es el estado final de la arquitectura para pasar a EXP-03.)
