# Laboratorio IaaS para Mitigación de T1580 en AWS

**Implementación de controles de IAM y observabilidad en AWS para la protección de activos en la nube frente a tácticas de descubrimiento de infraestructura (MITRE ATT&CK T1580).**

Trabajo de grado — Ingeniería de Sistemas e Informática
Universidad Pontificia Bolivariana, Seccional Bucaramanga

Autora: Angie Catalina Lemus Leiva
Director: John Jairo Briceño Valderrama

---

## Propósito

Este repositorio contiene el laboratorio experimental, las evidencias y la guía técnica bilingüe asociados al trabajo de grado sobre la mitigación de la técnica **T1580 — Cloud Infrastructure Discovery** del marco MITRE ATT&CK en entornos de Infraestructura como Servicio (IaaS) sobre Amazon Web Services.

El laboratorio se construye bajo el paradigma metodológico de **Design Science Research (DSR)** de Hevner et al., produciendo un artefacto verificable: una arquitectura IaaS endurecida frente a la enumeración de recursos, acompañada de evidencia empírica de la efectividad de los controles.

## Estructura del repositorio

```
tesis-iaas-t1580/
├── architecture/          Diagramas de arquitectura (baseline y endurecida)
├── docs/                  Guía técnica bilingüe (es / en)
├── evidence/              Evidencias de cada fase experimental
├── checklists/            Listas de verificación de seguridad (es / en)
├── attack-simulation/     Configuración y comandos de Pacu para T1580
├── iac/                   Plantillas de Infraestructura como Código (opcional)
└── scripts/               Scripts auxiliares (reconocimiento, validación)
```

## Fases del laboratorio

1. **Fase 1 — Análisis documental (OE1)**: identificación de vectores de exposición de T1580 en EC2, S3 e IAM.
2. **Fase 2 — Diseño e implementación (OE2)**: arquitectura IaaS endurecida con IAM, MFA y políticas de S3.
3. **Fase 3 — Experimentación y validación (OE3)**: observabilidad con CloudTrail/CloudWatch y simulación controlada con Pacu.
4. **Fase 4 — Documentación y difusión (OE4)**: guía técnica bilingüe y publicación del repositorio.

## Entorno experimental

El laboratorio se desarrolla en **AWS Academy Learner Lab**, con las siguientes consideraciones operativas:

- Presupuesto limitado a 50 USD.
- Las instancias EC2 se detienen automáticamente al cerrar la sesión.
- IAM tiene restricciones: se documentan en `evidence/00-baseline-environment.md`.
- Los servicios persistentes (S3, CloudTrail, CloudWatch) deben revisarse al inicio de cada sesión.

## Cómo usar este repositorio

1. Revisar la guía técnica en `docs/es/guia-tecnica.md`.
2. Consultar los diagramas en `architecture/`.
3. Reproducir las pruebas siguiendo `attack-simulation/pacu-T1580-commands.md`.
4. Validar controles con la lista de verificación en `checklists/`.

## Licencia

Material académico de uso libre con fines investigativos y formativos. Ver `LICENSE`.

---

# IaaS Lab for T1580 Mitigation in AWS (English)

**Implementation of IAM and observability controls in AWS to protect cloud assets against infrastructure discovery techniques (MITRE ATT&CK T1580).**

This repository contains the experimental laboratory, evidence, and bilingual technical guide for the undergraduate thesis on mitigating MITRE ATT&CK technique **T1580 — Cloud Infrastructure Discovery** in AWS IaaS environments. The laboratory follows the **Design Science Research (DSR)** paradigm and produces a verifiable artifact: a hardened IaaS architecture against resource enumeration, accompanied by empirical evidence of control effectiveness.

See the structure section above for repository organization. The English technical guide is available at `docs/en/technical-guide.md`.
