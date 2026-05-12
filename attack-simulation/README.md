# Simulación del ataque T1580 con Pacu

Este directorio contiene la documentación operativa de la simulación del adversario.

| Archivo | Contenido |
| --- | --- |
| `pacu-setup.md` | Instalación y primera configuración de Pacu en la máquina local. |
| `pacu-T1580-commands.md` | Módulos y comandos específicos asociados a T1580, en orden de ejecución. |

## Resumen del enfoque

Pacu se ejecuta **desde la máquina local de la operadora**, no desde una instancia EC2. La IP de origen externa es parte del modelo de amenaza: simula un atacante que ha obtenido credenciales del laboratorio (credenciales filtradas, comprometidas o expuestas) y enumera la infraestructura desde fuera.

La simulación se ejecuta **dos veces** con los mismos comandos:
1. **EXP-01**: contra la arquitectura baseline vulnerable.
2. **EXP-03**: contra la arquitectura endurecida.

La comparación entre ambas ejecuciones es la evidencia experimental central del trabajo de grado.
