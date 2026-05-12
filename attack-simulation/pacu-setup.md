# Pacu — Instalación y configuración

## Qué es Pacu

Pacu es el framework de explotación de AWS desarrollado por **Rhino Security Labs**, de código abierto. Es la herramienta de referencia citada en la documentación oficial de MITRE ATT&CK para la técnica T1580 — Cloud Infrastructure Discovery, porque incluye módulos específicos para enumerar instancias EC2, buckets S3, usuarios, roles y políticas IAM.

En este laboratorio Pacu cumple el rol de **adversario simulado**: actúa con credenciales legítimas pero "comprometidas" para reproducir el comportamiento descrito en T1580. La efectividad de los controles de la arquitectura endurecida se mide por la diferencia entre los resultados de Pacu contra la versión vulnerable y contra la versión endurecida.

## Dónde se instala

**En la máquina local de la operadora, no en AWS.**

Esto es deliberado por dos razones metodológicas:

1. **Realismo del modelo de amenaza**: en un ataque real, el adversario opera desde una infraestructura externa con credenciales obtenidas por filtración (phishing, secretos en repositorios, malware). La IP de origen externa es además una señal de detección relevante para CloudTrail.
2. **Economía de presupuesto**: ejecutar Pacu desde una instancia EC2 consume recursos del Learner Lab innecesariamente.

## Requisitos previos

- Python 3.8 o superior.
- `pip` actualizado.
- AWS CLI configurado con el perfil `learner-lab` (las credenciales se obtienen del botón "AWS Details" del Learner Lab).

## Instalación

### Opción A — Instalación con pip (recomendada para usuarias no familiarizadas con git)

```bash
pip install pacu
```

### Opción B — Instalación desde el repositorio oficial

```bash
git clone https://github.com/RhinoSecurityLabs/pacu.git
cd pacu
pip install -r requirements.txt
python3 pacu.py
```

## Primera ejecución

```bash
pacu
```

En el prompt de Pacu:

```
> new_session tesis-baseline
> import_keys learner-lab
> services
```

- `new_session` crea una sesión aislada (cada experimento debe tener su propia sesión).
- `import_keys learner-lab` importa las credenciales del perfil AWS CLI configurado.
- `services` muestra los servicios AWS que Pacu reconoce.

## Comandos esenciales

| Comando | Función |
| --- | --- |
| `list_modules` | Listar todos los módulos disponibles. |
| `search <texto>` | Buscar módulos por nombre o descripción. |
| `help <módulo>` | Ver la ayuda detallada de un módulo. |
| `run <módulo>` | Ejecutar un módulo. |
| `data` | Mostrar los datos recolectados hasta el momento. |
| `services` | Ver servicios disponibles para la sesión. |
| `exit` | Salir de Pacu. |

## Política de uso ético

Pacu es una herramienta de seguridad ofensiva. En este laboratorio:

- **Solo se ejecuta contra la cuenta de AWS Academy Learner Lab propia**, nunca contra cuentas de terceros.
- **No se utiliza para ningún propósito fuera del alcance académico** definido en el trabajo de grado.
- **Las credenciales y datos extraídos durante las pruebas no se publican** en el repositorio; solo se publican resultados enmascarados.

## Referencias

- Sitio oficial: https://github.com/RhinoSecurityLabs/pacu
- Documentación de T1580 en MITRE ATT&CK: https://attack.mitre.org/techniques/T1580/
