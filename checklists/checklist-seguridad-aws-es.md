# Lista de verificación de seguridad AWS — Mitigación de T1580

Esta lista de verificación operativiza los controles propuestos en la arquitectura endurecida y se alinea con NIST CSF 2.0, NIST SP 800-210 e ISO/IEC 27017.

## Identidad y acceso (IAM)

- [ ] La cuenta raíz no se utiliza para tareas operativas.
- [ ] La cuenta raíz tiene MFA habilitado.
- [ ] No existen políticas con `Action: "*"` y `Resource: "*"` sobre identidades no administrativas.
- [ ] Toda identidad humana con acceso a la consola tiene MFA obligatorio.
- [ ] Las claves de acceso programáticas se rotan al menos cada 90 días.
- [ ] Existe una política explícita que deniega las acciones de enumeración masiva (`ec2:Describe*`, `s3:ListAllMyBuckets`, `iam:List*`, `iam:GetAccountAuthorizationDetails`) a identidades no privilegiadas.
- [ ] Los roles de servicio aplican mínimo privilegio.
- [ ] Se eliminan los usuarios, roles y claves no utilizados periódicamente.
- [ ] Los Permission Boundaries están aplicados a los roles más sensibles.

## Almacenamiento (Amazon S3)

- [ ] Block Public Access está activado a nivel de cuenta.
- [ ] Todos los buckets tienen cifrado por defecto (SSE-S3 o SSE-KMS).
- [ ] Los buckets que almacenan datos relevantes tienen versionado activo.
- [ ] Las políticas de bucket usan condiciones (`aws:SourceIp`, `aws:SecureTransport`) cuando aplica.
- [ ] El logging de acceso a S3 está habilitado hacia un bucket dedicado.
- [ ] Ningún bucket es efectivamente público salvo justificación documentada.

## Cómputo (Amazon EC2)

- [ ] Las instancias usan IMDSv2 (`HttpTokens: required`).
- [ ] Los Security Groups solo permiten los puertos estrictamente necesarios.
- [ ] No hay reglas `0.0.0.0/0` en puertos administrativos (22, 3389).
- [ ] El acceso administrativo se realiza preferentemente con AWS Systems Manager Session Manager, no con SSH directo.
- [ ] Todas las instancias tienen etiquetado mínimo: `Project`, `Environment`, `Owner`.
- [ ] Existen snapshots automáticos de los volúmenes EBS críticos.

## Trazabilidad (AWS CloudTrail)

- [ ] Existe al menos un trail multirregión habilitado.
- [ ] El trail captura eventos de gestión y eventos de datos para los buckets S3 sensibles.
- [ ] La validación de integridad de archivos de log está habilitada.
- [ ] Los logs se almacenan en un bucket S3 dedicado con política que impide su modificación o eliminación.
- [ ] Los logs se envían a un Log Group de CloudWatch Logs para análisis.

## Monitoreo (AWS CloudWatch)

- [ ] Existe un filtro de métrica para llamadas `ec2:Describe*` con alarma asociada.
- [ ] Existe un filtro de métrica para llamadas `s3:List*` con alarma asociada.
- [ ] Existe un filtro de métrica para llamadas `iam:List*` y `iam:Get*` con alarma asociada.
- [ ] Existe una alarma sobre llamadas fallidas masivas (`AccessDenied`) desde una misma identidad.
- [ ] Las alarmas notifican a un canal de respuesta (SNS, correo electrónico, etc.).

## Resiliencia y recuperación

- [ ] Existe una estrategia de respaldo para EBS (snapshots automáticos con retención).
- [ ] El versionado de S3 actúa como protección frente a borrado accidental.
- [ ] El procedimiento de restauración está documentado.
- [ ] Se ha realizado al menos una prueba de restauración exitosa.

## Cumplimiento de marcos de referencia

- [ ] Los controles aplicados se mapean a NIST CSF 2.0 (Identificar, Proteger, Detectar, Responder, Recuperar).
- [ ] Los controles aplicados se mapean a NIST SP 800-210 §4 (control de acceso para IaaS).
- [ ] Los controles aplicados se mapean a ISO/IEC 27017 (controles específicos para servicios en la nube).

## Documentación

- [ ] Cada control implementado tiene una evidencia asociada en `evidence/`.
- [ ] La bitácora maestra (`evidence/master-log.md`) está actualizada.
- [ ] Las capturas de pantalla están enmascaradas y subidas a `evidence/captures/`.
