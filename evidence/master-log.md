# Bitácora maestra de experimentos

Tabla única de seguimiento de todas las pruebas del laboratorio. Se actualiza después de cada sesión.

| ID | Fecha | OE | Fase | Acción | Resultado esperado | Resultado observado | Evidencia | Estado |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| EXP-00 | YYYY-MM-DD | OE1 | 1 | Caracterización del Learner Lab (IAM, S3, EC2, CloudTrail, CloudWatch) | Identificar capacidades y restricciones | (resumen) | `evidence/00-baseline-environment.md` | ☐ |
| EXP-01 | YYYY-MM-DD | OE3 | 3 | Pacu contra arquitectura baseline | Enumeración exitosa de la mayoría de recursos | | `evidence/01-attack-baseline-T1580.md` | ☐ |
| CTL-01 | YYYY-MM-DD | OE2 | 2 | Block Public Access global en S3 | Bloqueo de acceso público a nivel de cuenta | | `evidence/02-controls-implementation.md#ctl-01` | ☐ |
| CTL-02 | YYYY-MM-DD | OE2 | 2 | Cifrado por defecto SSE-S3 | Cifrado automático en todos los buckets | | `evidence/02-controls-implementation.md#ctl-02` | ☐ |
| CTL-03 | YYYY-MM-DD | OE2 | 2 | Versionado en S3 | Versionado activo | | `evidence/02-controls-implementation.md#ctl-03` | ☐ |
| CTL-04 | YYYY-MM-DD | OE2 | 2 | Política IAM de mínimo privilegio | Denegación de `Describe*`, `List*` | | `evidence/02-controls-implementation.md#ctl-04` | ☐ |
| CTL-05 | YYYY-MM-DD | OE2 | 2 | MFA habilitado | MFA activo (donde el lab lo permita) | | `evidence/02-controls-implementation.md#ctl-05` | ☐ |
| CTL-06 | YYYY-MM-DD | OE3 | 3 | Trail CloudTrail multirregión | Logs persistidos en S3 | | `evidence/02-controls-implementation.md#ctl-06` | ☐ |
| CTL-07 | YYYY-MM-DD | OE3 | 3 | Alarma CloudWatch sobre `Describe*` | Alarma dispara con umbral configurado | | `evidence/02-controls-implementation.md#ctl-07` | ☐ |
| CTL-08 | YYYY-MM-DD | OE3 | 3 | Snapshots EBS y versionado | Restauración verificada | | `evidence/02-controls-implementation.md#ctl-08` | ☐ |
| EXP-03 | YYYY-MM-DD | OE3 | 3 | Pacu contra arquitectura endurecida | Mayoría de llamadas denegadas; alarmas disparadas | | `evidence/03-attack-post-hardening.md` | ☐ |
| DOC-01 | YYYY-MM-DD | OE4 | 4 | Guía técnica bilingüe (es/en) | Versión final revisada | | `docs/es/guia-tecnica.md`, `docs/en/technical-guide.md` | ☐ |
| DOC-02 | YYYY-MM-DD | OE4 | 4 | Checklist bilingüe | Versión final | | `checklists/` | ☐ |
| DOC-03 | YYYY-MM-DD | OE4 | 4 | Publicación del repo GitHub | Repo público accesible | | (URL del repo) | ☐ |

## Estados

- ☐ Pendiente
- ◐ En progreso
- ☑ Completado
- ⚠ Bloqueado (registrar motivo en la celda de resultado observado)

## Registro de incidencias del lab

Si una sesión termina por presupuesto, tiempo o error, registrar aquí:

| Fecha | Incidencia | Impacto | Mitigación |
| --- | --- | --- | --- |
| | | | |
