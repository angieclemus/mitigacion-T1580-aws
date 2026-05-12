# EXP-01 — Ejecución de Pacu contra la arquitectura baseline (vulnerable)

> **Propósito**: registrar la respuesta de la arquitectura vulnerable frente a la ejecución completa de los módulos de descubrimiento de Pacu asociados a T1580. Esta evidencia constituye la **línea base experimental**.

## Metadatos

| Campo | Valor |
| --- | --- |
| Identificador | EXP-01 |
| Fecha | YYYY-MM-DD |
| Operadora | Angie Catalina Lemus Leiva |
| Objetivo específico | OE3 (validación) |
| Arquitectura objetivo | Baseline vulnerable (ver `architecture/01-baseline-vulnerable.md`) |
| Identidad utilizada | (ej. `lab-attacker-victim` o `voclabs`) |
| Plataforma del atacante | Máquina local de la operadora (Windows/Linux/macOS) |
| Versión de Pacu | (ej. 1.6.x) |

## Sesión de Pacu

### Inicialización
```bash
pacu
> new_session tesis-baseline
> import_keys learner-lab
> services
```

**Resultado**: ____

### Módulos ejecutados (asociados a T1580)

| # | Módulo | Comando | Resultado |
| --- | --- | --- | --- |
| 1 | `iam__enum_users_roles_policies_groups` | `run iam__enum_users_roles_policies_groups` | ____ |
| 2 | `iam__enum_permissions` | `run iam__enum_permissions` | ____ |
| 3 | `enum_ec2` (también listado como `ec2__enum`) | `run ec2__enum` | ____ |
| 4 | `enum_s3` (también listado como `s3__bucket_finder` y `s3__download_bucket`) | `run s3__bucket_finder` | ____ |
| 5 | `enum_lightsail` (opcional) | `run lightsail__enum` | ____ |

Para cada módulo, registrar:
- **Comando completo**.
- **Salida resumida** (no pegar miles de líneas; sí las primeras 20 y las últimas 20).
- **Recursos descubiertos** (conteo: cuántas instancias, cuántos buckets, cuántos usuarios, etc.).
- **Tiempo de ejecución**.
- **Errores o denegaciones encontradas** (literal).

### Salida resumida — Ejemplo de formato

```
Módulo: iam__enum_users_roles_policies_groups
Inicio: HH:MM:SS  /  Fin: HH:MM:SS  /  Duración: __ s

Recursos descubiertos:
- Usuarios IAM: __
- Roles IAM: __
- Políticas gestionadas: __
- Grupos: __

Errores: (pegar los AccessDenied si hubo alguno)

Datos sensibles expuestos: (sí/no, detalle)
```

## Verificación cruzada en la consola AWS

Después de ejecutar Pacu, revisar manualmente:

### CloudTrail Event History
```bash
aws cloudtrail lookup-events --max-results 50 --profile learner-lab \
  --lookup-attributes AttributeKey=EventName,AttributeValue=ListBuckets
```
- ¿Aparecen las llamadas realizadas por Pacu? **Sí / No**.
- ¿Cuánto tarda la propagación al Event History? __ minutos.

### CloudWatch
- ¿Se generó alguna alarma? **No esperado en baseline**.

## Métricas del experimento baseline

| Métrica | Valor |
| --- | --- |
| Total de llamadas a la API generadas por Pacu | __ |
| % de llamadas exitosas | __ % |
| % de llamadas denegadas | __ % |
| Recursos enumerados con éxito | __ |
| Alarmas generadas | 0 (esperado) |
| Tiempo total del experimento | __ minutos |

## Capturas asociadas

- `captures/EXP-01_pacu-session-init_YYYYMMDD.png`
- `captures/EXP-01_iam-enum-output_YYYYMMDD.png`
- `captures/EXP-01_s3-enum-output_YYYYMMDD.png`
- `captures/EXP-01_ec2-enum-output_YYYYMMDD.png`
- `captures/EXP-01_cloudtrail-no-alarms_YYYYMMDD.png`

## Conclusión

Resumir en prosa qué se logró enumerar y por qué la arquitectura baseline es vulnerable a T1580. Esta conclusión es la **referencia comparativa** para EXP-03 (mismo ataque contra arquitectura endurecida).
