# Guía técnica — Mitigación de T1580 en AWS

> **Estado**: completa. Redactada al cierre de las cuatro fases del laboratorio (EXP-00 a EXP-03, CTL-01 a CTL-08).

## 1. Resumen ejecutivo

La técnica **T1580 — Cloud Infrastructure Discovery** del marco MITRE ATT&CK describe el reconocimiento que un adversario realiza sobre los recursos de una cuenta en la nube (instancias de cómputo, buckets de almacenamiento, identidades IAM) una vez ha obtenido credenciales válidas. Este reconocimiento es habitualmente el primer paso hacia objetivos más graves: movimiento lateral, exfiltración de datos o despliegue de recursos no autorizados.

Este trabajo construyó y evaluó empíricamente, bajo el paradigma de **Design Science Research** (Hevner et al.) [32], un artefacto verificable: una arquitectura IaaS endurecida en AWS, acompañada de ocho controles de mitigación (CTL-01 a CTL-08) distribuidos en las capas de identidad, almacenamiento y observabilidad. La efectividad del artefacto se validó ejecutando el **mismo ataque** —reproducido con la herramienta Pacu— contra una arquitectura baseline deliberadamente vulnerable (EXP-01) y contra la arquitectura endurecida (EXP-03), usando en ambos casos la identidad operativa del AWS Academy Learner Lab.

**Resultado principal**: los controles de **detección y observabilidad** (CloudTrail multirregión, alarmas de CloudWatch) fueron completamente efectivos — el mismo ataque que en la arquitectura baseline transcurrió sin dejar rastro (0 logs, 0 alarmas) generó, contra la arquitectura endurecida, un registro forense completo y **seis activaciones de alarma** en aproximadamente dos horas de ejecución. Sin embargo, los controles de **prevención** orientados a restringir la enumeración en sí (Block Public Access, política IAM de mínimo privilegio) **no lograron reducir la superficie de descubrimiento**, porque el modelo de amenaza validado —credenciales legítimas comprometidas— ya posee permisos amplios que ningún control de acceso público restringe, y la política de mínimo privilegio diseñada (CTL-04) no pudo adjuntarse al rol operativo por una restricción administrativa propia del entorno académico (`iam:AttachRolePolicy` denegado).

Este hallazgo —una arquitectura que **detecta** pero no siempre **previene**— constituye el aporte empírico central del trabajo: evidencia que, frente a T1580 ejecutado con credenciales comprometidas, el control de mayor impacto potencial (mínimo privilegio IAM) es también el más sensible a restricciones operativas del entorno donde se despliega, mientras que los controles de observabilidad son robustos y replicables incluso bajo dichas restricciones.

## 2. Contexto y problema

La adopción de infraestructura en la nube ha transformado los modelos operativos de las organizaciones, incrementando proporcionalmente su superficie de ataque. Amazon Web Services concentra aproximadamente el 50 % del mercado de servicios IaaS [1] y opera bajo un modelo de responsabilidad compartida: el proveedor asegura la infraestructura subyacente, mientras que la configuración segura de los servicios corresponde al cliente [16]. Esta distinción, clara en teoría, constituye en la práctica la principal fuente de vulnerabilidades explotables.

La magnitud del problema está documentada empíricamente. Las brechas ocurridas en nubes públicas cuestan en promedio USD 5,17 millones por incidente —el tipo más costoso registrado— y el 40 % de todas las brechas involucran datos distribuidos en múltiples entornos [2]. El abuso de cuentas válidas representó el vector de acceso inicial en el 35 % de las intrusiones en la nube durante 2024, año en que estas intrusiones crecieron un 26 % [3]. El tiempo promedio de *breakout* (el intervalo entre el acceso inicial y el movimiento lateral) se redujo a 48 minutos en 2024, con el caso más rápido registrado en 51 segundos [3] — una ventana que exige controles validados previamente, no diseñados en respuesta a un incidente activo.

En este contexto, T1580 describe cómo un adversario, tras comprometer un acceso inicial, enumera sistemáticamente instancias, buckets S3 y políticas IAM mediante llamadas legítimas a las APIs de AWS [4]. Su peligrosidad radica en que estas llamadas son **indistinguibles, a nivel de API, del comportamiento normal de usuarios autorizados** en ausencia de auditoría activa — condición agravada por factores estructurales documentados: el 99 % de las identidades en la nube poseen permisos excesivos y el 61 % de las cuentas raíz en AWS carece de MFA [5], mientras que la configuración incorrecta de CloudTrail presenta una tasa de error del 100 % en auditorías sectoriales [6]. La mala configuración y el control de cambios inadecuado son, de hecho, la principal amenaza documentada en entornos cloud durante 2024, por encima incluso de los ataques de día cero [7].

El problema que aborda este trabajo es doble: (1) determinar qué controles de IAM y observabilidad mitigan efectivamente T1580 en una arquitectura IaaS sobre AWS, y (2) generar evidencia empírica reproducible de su efectividad — superando así la principal limitación de los estudios documentales: la imposibilidad de comprobar si los controles propuestos funcionan en la práctica.

## 3. Técnica T1580 — Cloud Infrastructure Discovery

MITRE ATT&CK (*Adversarial Tactics, Techniques, and Common Knowledge*) es una base de conocimiento sobre tácticas y técnicas adversariales, construida a partir de observaciones de ataques reales [8]. T1580 se ubica en la táctica **Discovery** (TA0007) y describe cómo un adversario, con credenciales comprometidas, identifica recursos de infraestructura en un entorno IaaS —instancias de cómputo, snapshots, buckets y bases de datos— empleando APIs, CLI y herramientas de terceros como Pacu [4]. El Center for Threat-Informed Defense de MITRE sistematizó el mapeo de estas técnicas para entornos IaaS en el proyecto *Defending IaaS with ATT&CK* [9].

Los procedimientos documentados típicamente incluyen:

- **Enumeración de cómputo**: listado de instancias, imágenes (AMIs), volúmenes, snapshots, grupos de seguridad y configuración de red (VPCs, subredes, tablas de rutas) — llamadas como `DescribeInstances` o `DescribeSnapshots` revelan la topología completa de la infraestructura comprometida [4].
- **Enumeración de almacenamiento**: listado de buckets mediante `ListBuckets`, políticas de acceso asociadas, y en casos de configuración débil, lectura directa de su contenido [24].
- **Enumeración de identidad**: listado de usuarios, roles, grupos y políticas IAM, incluyendo intentos de confirmar permisos efectivos (`iam:SimulatePrincipalPolicy`, `GetAccountAuthorizationDetails`) [22].
- **Enumeración de servicios de detección**: verificación de si existen mecanismos de observabilidad activos (CloudTrail, GuardDuty, Config, CloudWatch) antes de proceder con acciones más agresivas — un adversario sofisticado prioriza operar en ausencia de detección.

El valor estratégico de T1580 para el atacante radica en que la información recopilada en esta fase guía las siguientes acciones: selección de recursos para escalar privilegios, identificación de datos a exfiltrar y definición de rutas de movimiento lateral. Desde la perspectiva defensiva, esto convierte a T1580 en un punto crítico de interrupción: si los controles de IAM restringen lo que una credencial comprometida puede ver, y los mecanismos de observabilidad detectan patrones inusuales de llamadas a la API, la cadena de ataque puede interrumpirse antes de que el adversario complete su reconocimiento.

La dificultad de detectar T1580 radica en que, salvo por los servicios de observabilidad mencionados, **no existe una señal de "ataque" distinguible de una consulta administrativa rutinaria**. La mitigación, por tanto, no puede basarse solo en impedir estas llamadas (lo que rompería operaciones administrativas legítimas) sino en una combinación de:

1. **Principio de mínimo privilegio** [19]: cada identidad debe operar con el conjunto mínimo de permisos necesario para su función, evitando excesos explotables en caso de compromiso. En entornos IaaS este principio resulta particularmente crítico, ya que la proliferación de identidades, roles y políticas amplía la superficie de ataque [25].
2. **Reducción de la exposición pública** de recursos de almacenamiento mediante políticas de bucket, ACLs y Block Public Access [24], de forma que la enumeración exitosa no derive automáticamente en acceso no autorizado.
3. **Observabilidad activa** mediante AWS CloudTrail, que registra cada llamada a la API con la identidad del solicitante, la hora, la IP de origen y los parámetros de la solicitud [21], complementado con AWS CloudWatch para generar alarmas sobre volúmenes anómalos de llamadas.

Este laboratorio diseñó y validó controles para las tres dimensiones.

## 4. Arquitectura del laboratorio

### 4.1 Versión baseline (vulnerable)

Arquitectura de referencia que reproduce condiciones de exposición estructurales documentadas en la literatura: instancia EC2 sin restricciones de red relevantes para el alcance del experimento, buckets S3 sin Block Public Access ni cifrado por defecto, ausencia de trail de CloudTrail dedicado y sin alarmas de CloudWatch configuradas. Detalle completo en `architecture/01-baseline-vulnerable.md`.

### 4.2 Versión endurecida

Arquitectura objetivo, alineada con NIST SP 800-210, ISO/IEC 27017 y el pilar de seguridad del AWS Well-Architected Framework, que incorpora ocho controles (CTL-01 a CTL-08) en las capas de almacenamiento, identidad y observabilidad. El diseño completo —incluyendo controles que no pudieron validarse por restricciones del entorno académico (MFA, adjunción de políticas IAM)— está documentado en `architecture/02-hardened.md`. La sección 8 de esta guía detalla la brecha entre el diseño y lo efectivamente validado.

## 5. Controles implementados

| ID | Control | Categoría | Marco de referencia | Estado |
| --- | --- | --- | --- | --- |
| CTL-01 | Block Public Access global en S3 | S3 | NIST CSF 2.0 PR.AC [30]; ISO/IEC 27017 CLD.9.5 [29] | ☑ Aplicado y verificado |
| CTL-02 | Cifrado por defecto SSE-S3 (AES-256) | S3 | NIST CSF 2.0 PR.DS [30]; ISO/IEC 27017 CLD.10.1 [29] | ☑ Aplicado y verificado |
| CTL-03 | Versionado de buckets S3 | S3 / Resiliencia | NIST CSF 2.0 RC.RP [30] | ☑ Aplicado y verificado (MFA Delete: no aplicable en el lab) |
| CTL-04 | Política IAM de mínimo privilegio (`DenyT1580Enumeration`) | IAM | Principio de mínimo privilegio [19]; NIST CSF 2.0 PR.AC-4 [30]; NIST SP 800-210 §4 [17] | ⚠ Política creada y verificada; no se pudo adjuntar al rol operativo (`iam:AttachRolePolicy` denegado por el lab) |
| CTL-05 | MFA obligatorio | IAM | NIST SP 800-63 [23]; NIST CSF 2.0 PR.AC-7 [30] | ⚠ No aplicable — el lab deniega la creación de usuarios IAM y dispositivos MFA virtuales |
| CTL-06 | Trail de CloudTrail multirregión con validación de integridad | CloudTrail / Observabilidad | AWS CloudTrail [21]; NIST CSF 2.0 DE.AE [30]; ISO/IEC 27017 CLD.12.4 [29] | ☑ Aplicado y verificado |
| CTL-07 | Alarma CloudWatch sobre llamadas `Describe*`/`List*` anómalas | CloudWatch / Observabilidad | NIST CSF 2.0 DE.CM [30]; NIST SP 800-210 [17] | ☑ Aplicado y verificado — disparada empíricamente en EXP-03 |
| CTL-08 | Snapshots EBS y versionado S3 como estrategia de respaldo | Resiliencia | NIST CSF 2.0 RC.RP [30] | ☑ Aplicado y verificado — restauración de versión S3 confirmada en EXP-03 |

Detalle de configuración, comandos ejecutados y evidencia de verificación de cada control en `evidence/02-controls-implementation.md`.

**Síntesis**: 6 de 8 controles quedaron completamente aplicados y verificados. Los dos controles no aplicables/no adjuntables (CTL-04, CTL-05) comparten una misma causa raíz — restricciones administrativas del AWS Academy Learner Lab sobre la gestión de identidades — y se discuten como limitación metodológica en la sección 8.

## 6. Simulación del ataque

### 6.1 Herramienta y enfoque

La simulación utilizó **Pacu** (Rhino Security Labs) [27], el framework de explotación de AWS que constituye la herramienta de referencia en la documentación oficial de MITRE ATT&CK para T1580 [4], ejecutado desde la máquina local de la operadora —no desde una instancia EC2 dentro de la cuenta— para preservar el realismo del modelo de amenaza (un adversario externo con credenciales filtradas). El mismo conjunto de cinco módulos se ejecutó, en el mismo orden, contra ambas arquitecturas para garantizar comparabilidad: `iam__enum_users_roles_policies_groups`, `iam__enum_permissions`, `ec2__enum`, `s3__download_bucket` y `detection__enum_services`. Detalle operativo completo en `attack-simulation/`.

### 6.2 Ejecución contra el baseline (EXP-01)

Contra la arquitectura baseline, Pacu enumeró exitosamente **23 roles, 7 políticas, 1 instancia EC2 (con IP pública exfiltrada), 2 buckets S3 y descargó 2 archivos** con datos ficticios sensibles, en aproximadamente 25 minutos. El módulo `detection__enum_services` confirmó la ausencia total de mecanismos de detección activos (0 trails, 0 alarmas, 0 detectores GuardDuty). Ninguna de estas acciones generó una alerta ni dejó un registro persistente. Detalle completo en `evidence/01-attack-baseline-T1580.md`.

### 6.3 Ejecución contra la arquitectura endurecida (EXP-03)

Contra la arquitectura endurecida, con identidad idéntica a EXP-01, los resultados fueron mixtos:

- La enumeración de IAM y EC2 produjo **resultados idénticos al baseline** (23 roles, 1 instancia, misma IP pública exfiltrada): ningún control aplicado restringe estas llamadas a nivel de IAM, porque CTL-04 no pudo adjuntarse al rol.
- La exfiltración S3 **no fue bloqueada por CTL-01** (Block Public Access): este control restringe acceso público/anónimo, no el acceso de una identidad autenticada de la propia cuenta con permisos ya concedidos. Se encontró además un tercer bucket enumerable — el bucket de logs de CloudTrail creado por CTL-06 — exponiendo potencialmente la evidencia forense a la misma identidad comprometida.
- El módulo de detección confirmó, tras corregir una limitación operativa de Pacu en el entorno (ver sección 8), **1 trail de CloudTrail activo y 1 alarma configurada**, frente al 0/0 del baseline.
- La verificación cruzada directa con AWS CLI confirmó que la alarma `T1580-EnumerationDetected` transicionó a estado `ALARM` **seis veces** durante la sesión de ataque (~2h20), con picos de hasta 46 llamadas `Describe*`/`List*` en una ventana de 5 minutos, y que el trail mantuvo entrega continua de logs durante toda la prueba.
- Una prueba adicional de resiliencia confirmó la restauración exitosa de una versión anterior de un objeto S3 manipulado, con coincidencia exacta de contenido y `ETag`.

Detalle completo, incluyendo notas metodológicas sobre incidentes del lab durante la prueba, en `evidence/03-attack-post-hardening.md`.

## 7. Resultados comparativos

| Métrica | Baseline (EXP-01) | Endurecida (EXP-03) | Lectura |
| --- | --- | --- | --- |
| Instancias EC2 enumeradas | 1 | 1 | Sin cambio — CTL-04 no adjuntado |
| Buckets S3 enumerados | 2 | 3 (incluye bucket de logs) | Empeora — nuevo activo expuesto por CTL-06 sin control de acceso adicional |
| Archivos exfiltrados de S3 | 2 | 2 (+ objetos del bucket de logs) | Sin mejora |
| Roles/políticas IAM enumerados | 23 / 7 | 23 / 8 | Sin cambio funcional |
| Trails de CloudTrail visibles | 0 | 1 | Mejora — observabilidad ahora existe |
| Activaciones de alarma CloudWatch | 0 | 6 (en ~2h20) | Mejora — detección activa y funcional |
| Trazabilidad forense | Ninguna | Completa (trail multirregión, validación de integridad) | Mejora sustancial |
| Tiempo hasta la primera alarma | N/A | Minutos desde el inicio de la enumeración | Mejora — detección casi en tiempo real |
| Resiliencia ante manipulación de datos | No probada | Restauración S3 verificada (ETag idéntico) | Mejora — capacidad de recuperación confirmada |

**Lectura agregada**: la arquitectura endurecida no redujo la *superficie de enumeración* disponible para un atacante con credenciales legítimas de la cuenta, pero transformó un ataque completamente silencioso en uno **detectado en minutos y con trazabilidad forense completa**, y demostró capacidad de **recuperación verificada** ante manipulación de datos. Estos tres planos —prevención, detección, resiliencia— no avanzaron de forma uniforme, y esa asimetría es en sí misma un resultado relevante para el capítulo de discusión de la tesis.

## 8. Limitaciones del laboratorio

El AWS Academy Learner Lab impuso restricciones administrativas que condicionaron el diseño y la interpretación de los resultados:

1. **Imposibilidad de crear usuarios IAM o dispositivos MFA virtuales** (`iam:CreateUser`, `iam:CreateVirtualMFADevice` denegados). Esto impidió implementar CTL-05 (MFA) y obligó a usar el rol `voclabs` como identidad única, colapsando los roles de "víctima" y "atacante" que en un entorno de producción real estarían separados. Documentado desde EXP-00.
2. **Imposibilidad de adjuntar políticas gestionadas a roles** (`iam:AttachRolePolicy` denegado). Esto impidió que CTL-04 —la política de mínimo privilegio diseñada específicamente para denegar las acciones de enumeración de T1580— tuviera efecto real, a pesar de haberse creado y verificado correctamente como artefacto. Esta es la limitación de mayor impacto en los resultados de EXP-03: sin ella, ningún control aplicado restringe la enumeración de IAM/EC2 a nivel de permisos.
3. **Regiones "opt-in" no habilitadas en la cuenta del lab**, lo que generó un `ConnectTimeoutError` al ejecutar `ec2__enum` sin acotar región, y un falso negativo en `detection__enum_services` (0/0 reportado inicialmente) porque el módulo aborta la enumeración de una API ante el primer `ACCESS DENIED` en una región distinta a `us-east-1`, sin llegar nunca a consultar la región donde realmente existen los recursos. Ambos incidentes se resolvieron acotando la sesión a `us-east-1` (`--regions us-east-1` y `set_regions us-east-1` respectivamente) y se documentan como notas metodológicas reproducibles en `evidence/master-log.md`.
4. **Presupuesto limitado** (50 USD) y reinicio de instancias EC2 al cerrar sesión, lo que condicionó el alcance de la validación de resiliencia a una prueba de restauración de versión S3 (de bajo costo) en lugar de una restauración completa de volumen EBS desde snapshot.

Estas limitaciones no invalidan los resultados; por el contrario, evidencian una tensión real entre el diseño de controles de seguridad y las restricciones administrativas de los entornos donde se despliegan — un hallazgo metodológicamente relevante en sí mismo, particularmente para organizaciones que operan con modelos de cuentas compartidas o con gobernanza de IAM centralizada fuera de su control directo.

## 9. Conclusiones y trabajo futuro

Este trabajo es de naturaleza aplicada: se orienta a resolver un problema práctico documentado —la ausencia de controles validados experimentalmente para mitigar T1580 en IaaS sobre AWS— mediante un enfoque experimental que reproduce condiciones de ataque controladas y mide la respuesta de los controles implementados [31]. El laboratorio cumplió los cuatro objetivos específicos del trabajo de grado: (OE1) se caracterizaron los vectores de exposición de T1580 en EC2, S3 e IAM sobre una arquitectura baseline deliberadamente vulnerable; (OE2) se diseñó e implementó una arquitectura endurecida con ocho controles distribuidos en identidad, almacenamiento y resiliencia; (OE3) se validó empíricamente la efectividad de dichos controles mediante un ataque controlado reproducido de forma idéntica contra ambas arquitecturas, incluyendo verificación cruzada con AWS CLI y una prueba de restauración; (OE4) se produjo esta guía técnica bilingüe, evidencia detallada por fase y una bitácora maestra trazable, publicadas en un repositorio público.

El aporte principal es evidencia empírica —no solo teórica— de que los controles de **observabilidad** (CloudTrail, CloudWatch) son robustos y replicables frente a T1580 incluso en entornos con restricciones administrativas severas, mientras que los controles de **prevención basados en IAM** dependen críticamente de permisos de gobernanza (como `iam:AttachRolePolicy`) que pueden no estar disponibles para quien diseña la arquitectura, separando la responsabilidad de "diseñar el control correcto" de la de "tener autoridad para aplicarlo".

**Líneas futuras de trabajo**:
- Repetir EXP-03 en una cuenta AWS con control administrativo completo, para verificar si CTL-04 adjuntado efectivamente reduce la superficie de enumeración a los niveles esperados por el diseño.
- Extender el laboratorio a otras técnicas de la táctica Discovery del dominio cloud de MITRE ATT&CK (p. ej., T1526 — Cloud Service Discovery).
- Integrar las alarmas de CloudWatch con un flujo de respuesta automatizado (SOAR), evaluando el tiempo de contención además del tiempo de detección.
- Evaluar el mismo conjunto de controles en un modelo multicuenta con AWS Organizations y Service Control Policies, donde el mínimo privilegio se aplica a nivel de organización y no depende de permisos del rol comprometido.

## 10. Lista de verificación

Ver `checklists/checklist-seguridad-aws-es.md` para la lista de verificación operativa completa, organizada por dominio (IAM, S3, EC2, CloudTrail, CloudWatch, resiliencia) y mapeada a NIST CSF 2.0, NIST SP 800-210 e ISO/IEC 27017.

## 11. Referencias

> Numeración idéntica a la bibliografía consolidada del documento de tesis (`TESIS ANGIE2.docx`), para mantener coherencia citacional entre ambos documentos.

[1] SentinelOne, "Top 10 AWS Security Issues You Need to Know," 2025. [En línea]. Disponible en: https://tinyurl.com/aws-security-s1

[2] IBM, "Cost of a Data Breach Report 2024," IBM Security, jul. 2024. [En línea]. Disponible en: https://tinyurl.com/ibm-breach-2024

[3] CrowdStrike, "2025 Global Threat Report," CrowdStrike, feb. 2025. [En línea]. Disponible en: https://tinyurl.com/cs-threat-2025

[4] MITRE, "Cloud Infrastructure Discovery, Technique T1580," MITRE ATT&CK, 2024. [En línea]. Disponible en: https://attack.mitre.org/techniques/T1580/

[5] SecurityToday, "Cloud Misconfigurations: The 10 Most Dangerous Security Gaps in AWS and Azure," feb. 2026. [En línea]. Disponible en: https://tinyurl.com/cloud-misconfig-2026

[6] Trend Micro, "The Most Common Cloud Misconfigurations That Could Lead to Security Breaches," 2021. [En línea]. Disponible en: https://tinyurl.com/trendmicro-misconfig

[7] RSA Conference, "Cloud Misconfigurations: Still the Biggest Threat in 2025?" oct. 2025. [En línea]. Disponible en: https://tinyurl.com/rsa-cloudmisconfig

[8] B. Strom, A. Applebaum, D. Miller, K. Nickels, A. Pennington y C. Thomas, "MITRE ATT&CK: Design and Philosophy," MITRE Corp., 2018. [En línea]. Disponible en: https://tinyurl.com/attck-design

[9] MITRE CTID, "Defending IaaS with ATT&CK," Center for Threat-Informed Defense, 2021. [En línea]. Disponible en: https://ctid.mitre.org/projects/attck-for-cloud/

[10] S. Roy et al., "MITRE ATT&CK Applications in Cybersecurity and The Way Forward," arXiv, 2023. [En línea]. Disponible en: https://tinyurl.com/attck-applications

[11] Z. Jadidi et al., "Threat Hunting Using MITRE ATT&CK Framework," en Proc. IEEE TrustCom, 2021.

[12] M. Munddt et al., "The Application of MITRE ATT&CK Framework in Mitigating Cyberattacks in the Public Sector," IACIS, 2024. [En línea]. Disponible en: https://tinyurl.com/attck-publicsector

[13] S. Achleitner et al., "Cyber Deception: Virtual Networks to Defend Insider Reconnaissance," en Proc. ACM CCS MIST Workshop, 2016.

[14] R. Guo et al., "A Practical Honeypot-Based Threat Intelligence Framework for Cloud Environments," arXiv, 2025. [En línea]. Disponible en: https://tinyurl.com/honeypot-cloud-2025

[15] P. Mell y T. Grance, "The NIST Definition of Cloud Computing," NIST SP 800-145, sep. 2011. [En línea]. Disponible en: https://tinyurl.com/nist-800-145

[16] Amazon Web Services, "Shared Responsibility Model," 2023. [En línea]. Disponible en: https://tinyurl.com/aws-shared-resp

[17] V. Hu et al., "General Access Control Guidance for Cloud Systems," NIST SP 800-210, jul. 2020. [En línea]. Disponible en: https://doi.org/10.6028/NIST.SP.800-210

[18] SANS Institute, "MITRE's Updated ATT&CK Framework: What Cloud Defenders Need to Know," 2023. [En línea]. Disponible en: https://tinyurl.com/sans-attck-cloud

[19] J. H. Saltzer y M. D. Schroeder, "The Protection of Information in Computer Systems," Proc. IEEE, vol. 63, no. 9, pp. 1278–1308, sep. 1975.

[20] M. Kleppmann, *Designing Data-Intensive Applications*. Sebastopol, CA: O'Reilly Media, 2017.

[21] Amazon Web Services, "AWS CloudTrail Documentation," 2024. [En línea]. Disponible en: https://tinyurl.com/aws-cloudtrail-doc

[22] Amazon Web Services, "AWS Identity and Access Management," 2023. [En línea]. Disponible en: https://tinyurl.com/aws-iam-doc

[23] NIST, "Digital Identity Guidelines," NIST SP 800-63, 2017. [En línea]. Disponible en: https://tinyurl.com/nist-800-63

[24] Amazon Web Services, "Amazon S3 Documentation," 2024. [En línea]. Disponible en: https://tinyurl.com/aws-s3-doc

[25] NIST, "Glossary of Key Information Security Terms," NISTIR 7298 Rev. 3, 2019. [En línea]. Disponible en: https://tinyurl.com/nist-glossary

[26] Datadog, "State of Cloud Security 2024," 2024. [En línea]. Disponible en: https://tinyurl.com/datadog-cloudsec-2024

[27] Rhino Security Labs, "Pacu: The AWS Exploitation Framework," GitHub, 2019. [En línea]. Disponible en: https://github.com/RhinoSecurityLabs/pacu

[28] Amazon Web Services, "ISO/IEC 27001:2022 Compliance," 2024. [En línea]. Disponible en: https://tinyurl.com/aws-iso27001

[29] ISO/IEC, "ISO/IEC 27017:2015 – Code of Practice for Information Security Controls for Cloud Services," 2015. [En línea]. Disponible en: https://www.iso.org/standard/43757.html

[30] NIST, "Cybersecurity Framework 2.0," 2024. [En línea]. Disponible en: https://tinyurl.com/nist-csf-20

[31] R. Hernández-Sampieri, C. Fernández-Collado y M. P. Baptista-Lucio, *Metodología de la Investigación*, 6.ª ed. México D.F.: McGraw-Hill, 2014.

[32] A. R. Hevner, S. T. March, J. Park y S. Ram, "Design science in information systems research," *MIS Quarterly*, vol. 28, no. 1, pp. 75–105, mar. 2004. [En línea]. Disponible en: https://doi.org/10.2307/25148625
