# EXP-03 — Ejecución de Pacu contra la arquitectura endurecida

> **Propósito**: comparar la respuesta del laboratorio frente al **mismo ataque** que en EXP-01, ahora con los controles de la arquitectura endurecida activos. Esta es la evidencia central que valida la efectividad de los controles propuestos.

## Metadatos

| Campo | Valor |
| --- | --- |
| Identificador | EXP-03 |
| Fecha | 2026-06-30 |
| Operadora | Angie Catalina Lemus Leiva |
| Objetivo específico | OE3 |
| Arquitectura objetivo | Endurecida (`architecture/02-hardened.md`) |
| Identidad utilizada | **Idéntica a EXP-01** (`voclabs`, assumed-role) para garantizar comparabilidad |
| Versión de Pacu | 1.7.0 (misma que en EXP-01) |

## Preparación de la sesión

```text
pacu
> new_session tesis-hardened
> import_keys learner-lab
> services
> set_regions us-east-1
```

> `set_regions us-east-1` limita las regiones que recorren todos los módulos de la sesión. Es necesario porque el Learner Lab solo habilita las APIs de CloudTrail/CloudWatch/EC2 en `us-east-1`; sin esta restricción, módulos como `detection__enum_services` (que no admite `--regions`) prueban otras regiones primero, reciben `ACCESS DENIED` y abortan la enumeración para el resto de regiones sin llegar nunca a `us-east-1`, produciendo falsos negativos.

## Ejecución de los módulos (mismos 5 módulos que EXP-01, ver `attack-simulation/pacu-T1580-commands.md`)

| # | Módulo | Resultado EXP-01 (baseline) | Resultado EXP-03 (endurecida) |
| --- | --- | --- | --- |
| 1 | `iam__enum_users_roles_policies_groups` | 0 usuarios, 23 roles, 7 políticas, 0 grupos enumerados. | 0 usuarios, 23 roles, 8 políticas, 0 grupos enumerados. Sin bloqueo — CTL-04 nunca quedó adjunta al rol `voclabs` (limitación del lab), por lo que la enumeración IAM básica no se ve afectada. La política adicional respecto al baseline es la propia `DenyT1580Enumeration` creada en CTL-04, ahora visible en el listado. |
| 2 | `iam__enum_permissions` | Parcialmente bloqueado por políticas internas del lab (Pvoclabs1, Pvoclabs2). `PermissionsConfirmed: false`. | Resultado idéntico al baseline: los mismos 3 `AccessDenied` (`Pvoclabs1`, `Pvoclabs2`, `voc-cancel-cred`) son restricciones internas de Vocareum, no de CTL-04. `0 Confirmed permissions`, `0 Unconfirmed permissions for role: voclabs`. Sin cambio atribuible a los controles del laboratorio. |
| 3 | `ec2__enum` | 1 instancia encontrada, 1 IP pública guardada en disco, red completa mapeada (VPC, subnets, ACLs). | Resultado idéntico al baseline: 1 instancia, 1 SG, 1 IP pública exfiltrada, 1 VPC, 6 subnets, 1 ACL, 1 tabla de rutas, 1 interfaz de red. Sin reducción de superficie — ningún CTL aplicado restringe `ec2:Describe*` a nivel de IAM (esa era la función de CTL-04, no adjuntada por restricción del lab). |
| 4 | `s3__download_bucket` | 2 buckets encontrados, ambos con permisos de lectura. 2 archivos exfiltrados (`config.txt`, `empleados.csv`). | **3 buckets encontrados** (`tesis-baseline-13840`, `tesis-test-13909761`, `tesis-trail-65227` — este último es el bucket de logs de CloudTrail creado en CTL-06). `config.txt` y `empleados.csv` exfiltrados de nuevo desde `tesis-baseline-13840`, igual que en EXP-01. Además se descargaron objetos del bucket de logs (`AWSLogs/.../CloudTrail-Digest/...json.gz`) antes de interrumpir el módulo manualmente (Ctrl+C) por el alto volumen de prompts por objeto. **CTL-01 (Block Public Access) no bloqueó la enumeración ni la descarga**: BPA solo restringe acceso público/anónimo, no el acceso de una identidad autenticada de la cuenta con permisos de S3 ya concedidos (`voclabs`, confirmado en EXP-00 S3-02). El control que sí habría bloqueado este vector es la política de mínimo privilegio (CTL-04), que no se pudo adjuntar por restricción del lab. Hallazgo adicional: el bucket de logs de CloudTrail (CTL-06) es accesible con la misma identidad comprometida, exponiendo la evidencia forense al mismo atacante. |
| 5 | `detection__enum_services` | 0 trails, 0 detectores GuardDuty, 0 alarmas CloudWatch, 0 VPC flow logs. | **1 CloudTrail trail encontrado** (`TesisT1580Trail`, CTL-06), **1 alarma CloudWatch encontrada** (`T1580-EnumerationDetected`, CTL-07). 0 GuardDuty, 0 Config, 0 VPC Flow Logs — controles fuera del alcance del laboratorio, sin cambio respecto al baseline. **Nota metodológica**: la primera ejecución sin acotar región dio 0/0 (falso negativo) porque el módulo prueba regiones en un orden no determinista y, ante el primer `ACCESS DENIED` (el lab solo permite estas APIs en `us-east-1`), deja de consultar el resto de regiones — sin llegar nunca a `us-east-1`. Se corrigió con el comando de sesión `set_regions us-east-1` antes de relanzar el módulo (el módulo no admite el flag `--regions` directamente). |

> **Hipótesis a validar**: el módulo 4 debería fallar o devolver 0 buckets accesibles por efecto de CTL-01 (Block Public Access). El módulo 5 debería mostrar `TesisT1580Trail` activo (CTL-06) y la alarma `T1580-EnumerationDetected` (CTL-07), a diferencia del 0/0 de EXP-01.

## Detección y respuesta

### Alarmas generadas en CloudWatch

Obtenido con `aws cloudwatch describe-alarm-history --alarm-name T1580-EnumerationDetected --profile learner-lab`. La alarma `T1580-EnumerationDetected` (umbral: ≥10 llamadas `Describe*`/`List*` en 300s) transicionó a estado **ALARM seis veces** durante la ventana de ejecución de EXP-03 (hora local UTC-5):

| Hora (transición a ALARM) | Pico detectado | Hora (vuelta a OK) | Observación |
| --- | --- | --- | --- |
| 09:53:55 | 24 llamadas / 5 min | 09:58:55 | Primera activación — corresponde al inicio del Bloque 1 (IAM) |
| 10:09:55 | 16 llamadas / 5 min | 10:14:55 | |
| 10:21:55 | 46 llamadas / 5 min | 10:28:55 | Pico más alto del experimento — coincide con el primer intento de `ec2__enum` sin acotar región (antes del `ConnectTimeoutError` en `me-south-1`) |
| 10:38:55 | 15 llamadas / 5 min | 10:43:55 | |
| 11:21:55 | 10 llamadas / 5 min | 11:26:55 | Umbral cruzado justo en el límite |
| 12:10:55 | 12 llamadas / 5 min | (activa al momento de la consulta) | Corresponde al módulo `detection__enum_services` tras `set_regions us-east-1` |

**Conclusión de esta sección**: la alarma detectó correctamente cada ráfaga de actividad de enumeración generada por Pacu a lo largo de las ~2h20 que duró la sesión de EXP-03, incluyendo el incidente no planeado del timeout de `ec2__enum`. El estado "OK" observado en una consulta puntual a mitad del experimento (11:26:55–12:10:55) reflejaba únicamente una pausa entre módulos, no una falla del control — la lectura del historial completo es indispensable para no subestimar la efectividad de CTL-07.

### Eventos capturados en CloudTrail

Confirmado vía `aws cloudtrail get-trail-status --name TesisT1580Trail`: `IsLogging: true`, `StartLoggingTime: 2026-06-04T15:11:11-05:00`, `LatestDeliveryTime: 2026-06-30T11:36:15-05:00` (entrega activa durante toda la sesión de ataque). Trail multirregión con validación de integridad habilitada (`LogFileValidationEnabled: true`), reenviando a CloudWatch Logs vía `LabRole`.

- **N.º de eventos capturados**: no cuantificado con `lookup-events` (pendiente, opcional — la métrica de CloudWatch ya confirma el conteo de llamadas `Describe*`/`List*` por ventana de 5 min).
- **Identidad solicitante**: `assumed-role/voclabs/user5074925=Angie_Lemus` (misma identidad que EXP-01).
- **Dirección IP de origen**: no verificada explícitamente en esta sesión (pendiente si se requiere para el capítulo de resultados).

### Eventos bloqueados (AccessDenied)

Ningún `AccessDenied` observado durante EXP-03 es atribuible a los controles CTL-01..CTL-08. Los únicos `AccessDenied` registrados (en el módulo `iam__enum_permissions`, sobre `Pvoclabs1`, `Pvoclabs2`, `voc-cancel-cred`) son restricciones internas de la plataforma Vocareum, idénticas a las de EXP-01 — no derivan de la política `DenyT1580Enumeration` (CTL-04), que nunca quedó adjunta al rol `voclabs`.

## Métricas comparativas

| Métrica | Baseline (EXP-01) | Endurecida (EXP-03) | Δ (mejora) |
| --- | --- | --- | --- |
| Recursos enumerados (instancias EC2) | 1 | 1 | Sin cambio |
| Recursos enumerados (buckets S3) | 2 | 3 (incluye el bucket de logs de CTL-06) | Empeora (+1) |
| Archivos exfiltrados de S3 | 2 | 2 (+ objetos del bucket de logs) | Sin mejora — empeora si se cuenta el bucket de logs |
| Usuarios/roles IAM enumerados | 0 usuarios, 23 roles | 0 usuarios, 23 roles | Sin cambio |
| Políticas IAM enumeradas | 7 | 8 (incluye `DenyT1580Enumeration`, sin adjuntar) | Sin cambio funcional |
| Trails de CloudTrail visibles | 0 | 1 (`TesisT1580Trail`) | Mejora — observabilidad ahora existe |
| Alarmas CloudWatch generadas | 0 | 6 activaciones en ~2h20 | Mejora — detección activa y funcional |
| Trazabilidad forense disponible | Ninguna (0 logs) | Completa (trail multirregión + validación de integridad) | Mejora sustancial |
| Tiempo desde el inicio del ataque hasta la primera alarma | N/A | ≈ minutos (primera activación a las 09:53, dentro de la primera ventana de evaluación de 5 min tras iniciar el Bloque 1) | Mejora — detección casi en tiempo real |

**Lectura del resultado**: los controles de **detección** (CTL-06, CTL-07) fueron completamente efectivos — el ataque que en EXP-01 pasó inadvertido (0 logs, 0 alarmas) en EXP-03 generó 6 activaciones de alarma y quedó íntegramente registrado en CloudTrail. Sin embargo, los controles de **prevención** (CTL-01 Block Public Access, CTL-04 mínimo privilegio) **no redujeron la superficie de enumeración ni impidieron la exfiltración**: BPA no aplica a identidades autenticadas de la cuenta, y CTL-04 nunca se pudo adjuntar por la restricción `iam:AttachRolePolicy` del Learner Lab. El resultado neto es una arquitectura que **detecta** el ataque T1580 pero no lo **previene** bajo el modelo de amenaza de credenciales legítimas comprometidas usado en este laboratorio.

## Capturas asociadas

- `captures/EXP-03_pacu-denied-outputs_YYYYMMDD.png`
- `captures/EXP-03_cloudwatch-alarms_YYYYMMDD.png`
- `captures/EXP-03_cloudtrail-events_YYYYMMDD.png`

## Validación de resiliencia

**Prueba ejecutada**: simulación de corrupción/ataque sobre `config.txt` en `tesis-baseline-13840` y restauración mediante versionado S3 (CTL-03).

| Paso | Acción | Resultado |
| --- | --- | --- |
| 1 | `list-object-versions` sobre el objeto original | `VersionId: "null"` — el objeto se subió el 2026-05-15, antes de activar el versionado (CTL-03, 2026-06-04). Los objetos preexistentes a la activación quedan marcados con la versión especial `null`. |
| 2 | Sobrescritura del objeto con contenido corrupto (`aws s3 cp`) | Nueva versión creada: `Euhb.BuBz8MXLbnlRj.2hqtliMbuVPt9` (46 bytes, `IsLatest: true`). Versión original conservada como `null` (`IsLatest: false`). |
| 3 | Restauración con `aws s3api copy-object --copy-source "...?versionId=null"` | Copia exitosa. `ETag` resultante (`edd23f25adcf6f597fb669499a400582`) idéntico al de la versión original — restauración byte-a-byte verificada. |
| 4 | Verificación de contenido (`aws s3 cp s3://.../config.txt -`) | Contenido recuperado coincide exactamente con el original (`servidor=prod-db-01`, `password=S3cr3t123`, `region=us-east-1`). |

**Hallazgo adicional**: la copia restaurada quedó automáticamente cifrada (`ServerSideEncryption: AES256`), confirmando que CTL-02 (cifrado por defecto) se aplica también a objetos restaurados, no solo a las cargas originales.

- **Snapshot EBS restaurado**: no ejecutado en esta sesión — se priorizó la prueba de versionado S3 por rapidez y costo. Pendiente como validación opcional adicional si el presupuesto del lab lo permite.
- **Versión anterior de objeto S3 restaurada**: **sí**, verificado con coincidencia exacta de `ETag` y contenido.

**Conclusión de la prueba**: CTL-03 (versionado) y CTL-02 (cifrado por defecto) son controles de resiliencia plenamente funcionales y verificados empíricamente — ante una manipulación maliciosa de un objeto S3 (ej. ransomware, alteración de configuración), el dato original es recuperable de forma íntegra y rápida.

## Conclusión

EXP-03 demuestra un resultado mixto, pero metodológicamente sólido: la arquitectura endurecida **no impidió** que Pacu enumerara IAM, EC2 y S3 con los mismos resultados (o peores, en el caso de S3) que en la arquitectura baseline de EXP-01, porque las identidades comprometidas en este modelo de amenaza ya poseían permisos legítimos amplios y los controles de prevención disponibles en el entorno (Block Public Access, cifrado, versionado) no restringen el acceso de identidades autenticadas de la propia cuenta — solo el acceso público/anónimo. El único control capaz de cerrar ese vector, la política de mínimo privilegio (CTL-04), no pudo aplicarse por una restricción operativa del AWS Academy Learner Lab (`iam:AttachRolePolicy` denegado), no por una falla de diseño.

En contraste, los controles de **observabilidad** fueron completamente efectivos: el mismo ataque que en EXP-01 transcurrió sin dejar rastro (0 logs, 0 alarmas) en EXP-03 generó un trail completo en CloudTrail y **6 activaciones de la alarma CloudWatch** distribuidas a lo largo de la sesión, con tiempos de detección de pocos minutos desde el inicio de cada ráfaga de enumeración.

La conclusión central para el capítulo de resultados de la tesis es que, en el entorno restringido del Learner Lab, la arquitectura endurecida propuesta **transforma un ataque T1580 completamente silencioso en uno completamente detectable**, pero **no lo previene** cuando el atacante opera con credenciales legítimas de la cuenta. Esto resalta que, frente a T1580 ejecutado con credenciales comprometidas, el control de mayor impacto potencial (mínimo privilegio IAM) es también el más difícil de validar empíricamente en un entorno académico con restricciones administrativas — una limitación que debe discutirse explícitamente como hallazgo metodológico, no como debilidad del diseño de controles.
