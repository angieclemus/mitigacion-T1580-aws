# Evidencias experimentales

Este directorio contiene la documentación cronológica de cada prueba realizada en el laboratorio. La estructura está diseñada para que cada archivo sea un **registro reproducible** que sustente las afirmaciones de la tesis con evidencia concreta.

## Archivos

| Archivo | Fase | Contenido |
| --- | --- | --- |
| `00-baseline-environment.md` | 1 | Caracterización del entorno AWS Academy Learner Lab (qué permite, qué no) |
| `01-attack-baseline-T1580.md` | 3 | Ejecución de Pacu contra la arquitectura vulnerable |
| `02-controls-implementation.md` | 2-3 | Aplicación de cada control de la arquitectura endurecida |
| `03-attack-post-hardening.md` | 3 | Ejecución de Pacu contra la arquitectura endurecida |
| `master-log.md` | Transversal | Tabla maestra de seguimiento de todas las pruebas |

## Cómo registrar una evidencia

Cada prueba se registra siguiendo el siguiente esquema:

1. **Identificador** único de la prueba (formato `EXP-NN`).
2. **Fecha y hora** de ejecución.
3. **Objetivo específico** al que aporta (OE1, OE2, OE3 u OE4).
4. **Comando o acción** ejecutada (literal, copiable).
5. **Resultado esperado** según el diseño.
6. **Resultado observado** (literal, sin interpretación).
7. **Evidencia anexa**: ruta a la captura de pantalla o al log correspondiente (en `evidence/captures/`).
8. **Interpretación**: comparación esperado vs. observado y conclusión.

## Política sobre datos sensibles

- **NUNCA** incluir credenciales reales, ni siquiera parcialmente.
- Las cuentas de AWS, ARNs y Account IDs reales se enmascaran (ej. `123456789012` → `XXXXXXXXXXXX`).
- Las direcciones IP públicas reales del laboratorio se enmascaran (ej. `54.X.X.X`).
- Las capturas de pantalla se editan para tachar identificadores antes de subirlas.

## Capturas

Las capturas de pantalla van en `evidence/captures/` (carpeta a crear cuando empieces a tomar evidencia). Se nombran con el patrón:

```
EXP-NN_descripcion-corta_YYYYMMDD.png
```

Ejemplo: `EXP-03_pacu-enum-s3-baseline_20260515.png`
