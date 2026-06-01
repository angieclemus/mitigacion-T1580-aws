# EXP-01 — Ejecución de Pacu contra la arquitectura baseline (vulnerable)

> **Propósito**: registrar la respuesta de la arquitectura vulnerable frente a la ejecución completa de los módulos de descubrimiento de Pacu asociados a T1580. Esta evidencia constituye la **línea base experimental**.

## Metadatos

| Campo | Valor |
| --- | --- |
| Identificador | EXP-01 |
| Fecha | 2026-05-15 |
| Operadora | Angie Catalina Lemus Leiva |
| Objetivo específico | OE3 (validación) |
| Arquitectura objetivo | Baseline vulnerable (ver `architecture/01-baseline-vulnerable.md`) |
| Identidad utilizada | `voclabs` (assumed-role, rol operativo del Learner Lab) |
| Plataforma del atacante | Máquina local de la operadora (Windows 11) |
| Versión de Pacu | 1.7.0 |

## Sesión de Pacu

### Inicialización
```bash
pacu
> new_session tesis-baseline
> import_keys learner-lab
> services
```

**Resultado**: Sesión creada como `tesis-baseline`. Claves importadas desde el perfil `learner-lab` como `imported-learner-lab`. Identidad activa: `assumed-role/voclabs/userXXXXXXXX=Angie_Lemus` (cuenta `660XXXXXXX722`).


| # | Módulo | Comando | Resultado |
| --- | --- | --- | --- |
| 1 | `iam__enum_users_roles_policies_groups` | `run iam__enum_users_roles_policies_groups` | 0 usuarios, 23 roles, 7 políticas, 0 grupos enumerados. |
| 2 | `iam__enum_permissions` | `run iam__enum_permissions` | Parcialmente bloqueado por políticas internas del lab (Pvoclabs1, Pvoclabs2). `PermissionsConfirmed: false`. Limitación del entorno. |
| 3 | `ec2__enum` | `run ec2__enum --regions us-east-1` | 1 instancia encontrada, 1 IP pública guardada en disco, red completa mapeada (VPC, subnets, ACLs). |
| 4 | `s3__download_bucket` | `run s3__download_bucket` | 2 buckets encontrados, ambos con permisos de lectura. 2 archivos exfiltrados (`config.txt`, `empleados.csv`). |
| 5 | `detection__enum_services` | `run detection__enum_services` | 0 trails CloudTrail, 0 detectores GuardDuty, 0 alarmas CloudWatch, 0 VPC flow logs. Entorno sin detección activa confirmado. |


### Salida resumida — Ejemplo de formato

### Módulo 1 — `iam__enum_users_roles_policies_groups`

```
[iam__enum_users_roles_policies_groups] Found 0 users
[iam__enum_users_roles_policies_groups] Found 23 roles
[iam__enum_users_roles_policies_groups] Found 7 policies
[iam__enum_users_roles_policies_groups] Found 0 groups
[iam__enum_users_roles_policies_groups] iam__enum_users_roles_policies_groups completed.

MODULE SUMMARY:
  0 Users Enumerated
  23 Roles Enumerated
  7 Policies Enumerated
  0 Groups Enumerated
  IAM resources saved in Pacu database.
```

Recursos descubiertos: 23 roles (incluye `voclabs`, `LabRole`, roles de servicio AWS). 7 políticas gestionadas. Datos guardados en base de datos de Pacu para análisis cruzado.

---

### Módulo 2 — `iam__enum_permissions`

```
Get policy failed: AccessDenied — iam:GetPolicy on policy/voc-cancel-cred
Get policy failed: AccessDenied — iam:GetPolicy on policy/Pvoclabs1
Get policy failed: AccessDenied — iam:GetPolicy on policy/Pvoclabs2
[iam__enum_permissions] Confirmed permissions for voclabs

MODULE SUMMARY:
  0 Unconfirmed permissions for role: voclabs.
```

Nota: los 3 `AccessDenied` corresponden a políticas internas de control del laboratorio (Vocareum), no a controles de seguridad implementados. `PermissionsConfirmed: false` es una limitación del entorno.

---

### Módulo 3 — `ec2__enum` (us-east-1)

```
[ec2__enum]   1 instance(s) found.
[ec2__enum]   1 security groups(s) found.
[ec2__enum]   1 public IP address(es) found — guardada en archivo local.
[ec2__enum]   1 network ACL(s) found.
[ec2__enum]   1 network interface(s) found.
[ec2__enum]   1 route table(s) found.
[ec2__enum]   6 subnet(s) found.
[ec2__enum]   1 VPC(s) found.

MODULE SUMMARY: 1 instancia total. 1 IP pública encontrada y guardada en disco.
```

Hallazgo crítico: IP pública de `tesis-baseline-server` exfiltrada y guardada localmente. En un ataque real permite escaneos de puertos y explotación directa.

---

### Módulo 4 — `s3__download_bucket`

```
[s3__download_bucket]   Found bucket "tesis-baseline-13840"
[s3__download_bucket]   Found bucket "tesis-test-XXXXXXX"
[s3__download_bucket]   Download "config.txt" — completado
[s3__download_bucket]   Download "empleados.csv" — completado

MODULE SUMMARY:
  2 total buckets found.
  2 buckets found with read permissions.
  2 files downloaded.
```

Hallazgo crítico: ambos buckets accesibles sin autenticación adicional. Archivos con datos ficticios sensibles (`config.txt`: credenciales, `empleados.csv`: datos personales) descargados exitosamente. Simula exfiltración de datos real.

---

### Módulo 5 — `detection__enum_services`

```
MODULE SUMMARY:
  0 CloudTrail Trail(s) found.
  0 GuardDuty Detector(s) found.
  0 AWS Config Rule(s) found.
  0 CloudWatch Alarm(s) found.
  0 VPC flow log(s) found.
```

Confirma que el entorno baseline no tiene ningún servicio de detección activo. El ataque completo se ejecutó sin generar alertas ni logs persistentes.


## Verificación cruzada en la consola AWS

No aplica en el experimento baseline: no existe ningún trail de CloudTrail configurado (confirmado en EXP-00 CT-01 y verificado por Pacu en `detection__enum_services`). Las llamadas de Pacu no quedaron registradas en ningún log persistente. El Event History de la consola AWS puede mostrar eventos recientes de forma limitada (últimas horas), pero no constituye un sistema de detección continuo ni configurable.

- ¿Aparecen las llamadas realizadas por Pacu en CloudTrail? **No** — ningún trail activo.
- ¿Se generó alguna alarma? **No** — ninguna alarma CloudWatch configurada.



## Métricas del experimento baseline

| Métrica | Valor |
| --- | --- |
| Total de llamadas a la API generadas por Pacu | ~55 (estimado; conteo exacto en base de datos Pacu) |
| % de llamadas exitosas | ~78 % |
| % de llamadas denegadas | ~22 % (restricciones internas del lab, no controles de seguridad) |
| Recursos enumerados con éxito | 23 roles, 7 políticas, 1 instancia EC2, 1 IP pública, 2 buckets S3, 2 archivos exfiltrados |
| Alarmas generadas | 0 |
| Tiempo total del experimento | ~25 minutos |



## Conclusión

La arquitectura baseline demostró ser completamente vulnerable a la técnica T1580. En una sesión de aproximadamente 25 minutos, Pacu logró enumerar la estructura IAM de la cuenta (23 roles, 7 políticas), descubrir y extraer la IP pública de la instancia EC2, identificar y descargar archivos de dos buckets S3 sin restricciones de acceso, y confirmar la ausencia total de mecanismos de detección (CloudTrail, GuardDuty, CloudWatch, VPC Flow Logs). Ninguna de estas acciones generó una alerta ni dejó un log persistente. Esta evidencia establece la línea base experimental contra la cual se medirá la efectividad de los controles implementados en EXP-03.

