# Bitácora maestra de experimentos

Tabla única de seguimiento de todas las pruebas del laboratorio. Se actualiza después de cada sesión.

| ID | Fecha | OE | Fase | Acción | Resultado esperado | Resultado observado | Evidencia | Estado |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| EXP-00 | 2026-05-14 | OE1 | 1 | Caracterización del Learner Lab (IAM, S3, EC2, CloudTrail, CloudWatch) | Identificar capacidades y restricciones | Completado. Restricción crítica: el rol `voclabs` no puede crear usuarios IAM ni claves de acceso; se documenta como limitación metodológica y se usa `voclabs` como identidad única en EXP-01/EXP-03. | `evidence/00-baseline-environment.md` | ☑ |
| EXP-01 | 2026-05-15 | OE3 | 3 | Pacu contra arquitectura baseline | Enumeración exitosa de la mayoría de recursos | Completado. 23 roles, 7 políticas, 1 EC2 (IP pública exfiltrada), 2 buckets S3, 2 archivos descargados. 0 alarmas. 0 logs. | `evidence/01-attack-baseline-T1580.md` | ☑ |
| EXP-02 | 2026-06-04 a 2026-06-15 | OE2 / OE3 | 2 | Implementación de controles CTL-01 a CTL-08 en arquitectura endurecida | Controles aplicados y verificados | Completado. 6/8 controles aplicados de forma completa. CTL-04 y CTL-05 quedaron documentados como limitación metodológica del lab (sin `iam:AttachRolePolicy` ni creación de usuarios/MFA). | `evidence/02-controls-implementation.md` | ☑ |
| CTL-01 | 2026-05-15 | OE2 | 2 | Block Public Access global en S3 | Bloqueo de acceso público a nivel de cuenta | Aplicado y verificado: los 4 parámetros activos a nivel de cuenta. | `evidence/02-controls-implementation.md#ctl-01` | ☑ |
| CTL-02 | 2026-06-04 | OE2 | 2 | Cifrado por defecto SSE-S3 | Cifrado automático en todos los buckets | Aplicado (`AES256`, `BucketKeyEnabled`). | `evidence/02-controls-implementation.md#ctl-02` | ☑ |
| CTL-03 | 2026-06-04 | OE2 | 2 | Versionado en S3 | Versionado activo | Aplicado y verificado (`Status: Enabled`). MFA Delete no aplicable (limitación del lab). | `evidence/02-controls-implementation.md#ctl-03` | ☑ |
| CTL-04 | 2026-06-04 | OE2 | 2 | Política IAM de mínimo privilegio | Denegación de `Describe*`, `List*` | Política `DenyT1580Enumeration` creada y verificada. No se pudo adjuntar a ningún rol (`iam:AttachRolePolicy` denegado) — limitación metodológica del lab. | `evidence/02-controls-implementation.md#ctl-04` | ⚠ |
| CTL-05 | 2026-06-04 | OE2 | 2 | MFA habilitado | MFA activo (donde el lab lo permita) | No aplicable: el lab deniega `iam:CreateUser` e `iam:CreateVirtualMFADevice`. Documentado como limitación metodológica. | `evidence/02-controls-implementation.md#ctl-05` | ⚠ |
| CTL-06 | 2026-06-04 | OE3 | 3 | Trail CloudTrail multirregión | Logs persistidos en S3 | Trail `TesisT1580Trail` creado y logging activo, validación de integridad habilitada. Logs en `s3://tesis-trail-65227`. | `evidence/02-controls-implementation.md#ctl-06` | ☑ |
| CTL-07 | 2026-06-04 | OE3 | 3 | Alarma CloudWatch sobre `Describe*` | Alarma dispara con umbral configurado | Filtro de métrica `T1580EnumerationCalls` y alarma `T1580-EnumerationDetected` creados (umbral 10 llamadas / 300 s). Estado inicial `INSUFFICIENT_DATA` (sin tráfico aún). | `evidence/02-controls-implementation.md#ctl-07` | ☑ |
| CTL-08 | 2026-06-04 | OE3 | 3 | Snapshots EBS y versionado | Restauración verificada | Snapshot `snap-0d7e4d31b438b8340` creado y completado (100%) sobre `vol-005326b870783c755`. | `evidence/02-controls-implementation.md#ctl-08` | ☑ |
| EXP-03 | 2026-06-30 | OE3 | 3 | Pacu contra arquitectura endurecida | Mayoría de llamadas denegadas; alarmas disparadas | Completado. Resultado mixto y bien documentado: CTL-06/CTL-07 detectaron el ataque exitosamente (trail completo + 6 activaciones de alarma vs 0/0 en baseline), pero CTL-01/CTL-04 no redujeron la superficie de enumeración ni evitaron la exfiltración (acceso autenticado de cuenta, no público; CTL-04 nunca adjuntada). Validación de resiliencia (CTL-03/CTL-02) cerrada: restauración de versión S3 verificada con coincidencia exacta de ETag y contenido. | `evidence/03-attack-post-hardening.md` | ☑ |
| DOC-01 | 2026-06-30 | OE4 | 4 | Guía técnica bilingüe (es/en) | Versión final revisada | Redactada en 11 secciones, consolidando evidencia real de EXP-00 a EXP-03 y CTL-01 a CTL-08. Bibliografía (sección 11) reconciliada con la numeración exacta de `TESIS ANGIE2.docx` (32 referencias); citas insertadas en cuerpo del texto (secciones 2, 3, 5, 9). | `docs/es/guia-tecnica.md`, `docs/en/technical-guide.md` | ☑ |
| DOC-02 | 2026-06-30 | OE4 | 4 | Checklist bilingüe | Versión final | Verificado: ambas versiones (es/en) completas y consistentes entre sí, organizadas por dominio y mapeadas a los tres marcos de referencia. | `checklists/` | ☑ |
| DOC-03 | YYYY-MM-DD | OE4 | 4 | Publicación del repo GitHub | Repo público accesible | Pendiente. | (URL del repo) | ☐ |

## Estados

- ☐ Pendiente
- ◐ En progreso
- ☑ Completado
- ⚠ Bloqueado (registrar motivo en la celda de resultado observado)

## Registro de incidencias del lab

Si una sesión termina por presupuesto, tiempo o error, registrar aquí:

| Fecha | Incidencia | Impacto | Mitigación |
| --- | --- | --- | --- |
| 2026-06-30 | Durante EXP-03, `ec2__enum` sin acotar región generó `ConnectTimeoutError` en `me-south-1` (región opt-in no habilitada en el Learner Lab). | Interrupción del módulo 3, sin pérdida de datos previos. | Repetir el módulo con `--regions us-east-1`, igual que en EXP-01, para mantener comparabilidad y evitar regiones opt-in. |
| 2026-06-30 | `detection__enum_services` (módulo 5 de EXP-03) reportó inicialmente 0/0/0/0 en CloudTrail/CloudWatch/Config/VPC — falso negativo. El módulo no admite `--regions` y prueba regiones en orden no determinista; ante el primer `ACCESS DENIED` (regiones fuera de `us-east-1` bloqueadas por el lab), aborta la enumeración para las regiones restantes sin llegar a `us-east-1`, donde sí existen el trail y la alarma. | Resultado inicial no representativo del estado real de CTL-06/CTL-07. | Comando de sesión `set_regions us-east-1` antes de relanzar el módulo. Resultado corregido: 1 trail, 1 alarma encontrados. |
