# Arquitectura del laboratorio

Este directorio contiene los diagramas y descripciones de las dos versiones de la arquitectura experimental:

1. **`01-baseline-vulnerable.md`** — Arquitectura inicial deliberadamente vulnerable, diseñada para reproducir las condiciones de exposición que permiten la ejecución exitosa de T1580.
2. **`02-hardened.md`** — Arquitectura endurecida con los controles de IAM, S3 y observabilidad propuestos en el trabajo de grado.

La carpeta `source/` contiene los archivos editables de los diagramas (formato draw.io o Lucidchart) para permitir su modificación durante la defensa o publicación del trabajo.

## Componentes comunes a ambas arquitecturas

| Componente | Servicio AWS | Propósito en el laboratorio |
| --- | --- | --- |
| Instancia de cómputo | Amazon EC2 (t2.micro o t3.micro) | Objetivo de enumeración (DescribeInstances) |
| Almacenamiento | Amazon S3 (3 buckets) | Objetivo de enumeración (ListBuckets) y exfiltración |
| Gestión de identidades | AWS IAM | Objetivo de enumeración (ListUsers, ListRoles, ListPolicies) |
| Atacante externo | Máquina local con Pacu | Simulación de adversario con credenciales comprometidas |

## Diferencia clave entre versiones

La diferencia no está en los servicios usados, sino en **la configuración** de cada uno. La arquitectura baseline carece de controles; la endurecida aplica el principio de mínimo privilegio, cifrado, bloqueo de acceso público, trazabilidad y alarmas.

Esto permite que la métrica de éxito del experimento sea **comparativa**: el mismo ataque (Pacu T1580) se ejecuta contra ambas arquitecturas y se mide la diferencia en resultados.
