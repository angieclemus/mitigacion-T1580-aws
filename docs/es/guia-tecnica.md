# Guía técnica — Mitigación de T1580 en AWS

> **Estado**: borrador. Se completa al cerrar las cuatro fases del laboratorio.

## 1. Resumen ejecutivo

(Una página. Síntesis del problema, la propuesta, los resultados y los entregables. Se redacta al final.)

## 2. Contexto y problema

(Reusar contenido del *Planteamiento del problema* y la *Justificación* de la tesis. Mantener la coherencia citacional con la bibliografía IEEE.)

## 3. Técnica T1580 — Cloud Infrastructure Discovery

(Descripción derivada del *Marco teórico* de la tesis. Detallar los procedimientos documentados por MITRE, los recursos enumerados típicamente y por qué la técnica es difícil de detectar sin observabilidad activa.)

## 4. Arquitectura del laboratorio

### 4.1 Versión baseline (vulnerable)
(Ver `architecture/01-baseline-vulnerable.md`.)

### 4.2 Versión endurecida
(Ver `architecture/02-hardened.md`.)

## 5. Controles implementados

| ID | Control | Servicio AWS | Marco de referencia |
| --- | --- | --- | --- |
| CTL-01 | Block Public Access global | S3 | NIST CSF 2.0 PR.AC, ISO 27017 |
| CTL-02 | Cifrado por defecto | S3 | NIST CSF 2.0 PR.DS |
| ... | ... | ... | ... |

(Completar con los controles consolidados en `evidence/02-controls-implementation.md`.)

## 6. Simulación del ataque

### 6.1 Herramienta y enfoque
(Pacu desde la máquina local; ver `attack-simulation/`.)

### 6.2 Ejecución contra el baseline
(Resumir resultados de `evidence/01-attack-baseline-T1580.md`.)

### 6.3 Ejecución contra la arquitectura endurecida
(Resumir resultados de `evidence/03-attack-post-hardening.md`.)

## 7. Resultados comparativos

(Tabla comparativa de métricas: recursos enumerados, % de llamadas exitosas, alarmas generadas, trazabilidad disponible. Esta sección es el corazón del trabajo.)

## 8. Limitaciones del laboratorio

(Documentar honestamente las restricciones del AWS Academy Learner Lab y cómo se adaptó el diseño metodológico.)

## 9. Conclusiones y trabajo futuro

(Síntesis de aportes, alineada con los cuatro objetivos específicos. Líneas futuras: extensión a otras técnicas MITRE, integración con SOAR, etc.)

## 10. Lista de verificación

Ver `checklists/checklist-seguridad-aws-es.md`.

## 11. Referencias

(Numeración IEEE, alineada con la tesis principal.)
