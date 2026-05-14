# EXP-00 — Caracterización del entorno AWS Academy Learner Lab

> Propósito del documento: registrar las capacidades y restricciones reales del entorno experimental durante la primera sesión, antes de construir cualquier recurso. Sirve como evidencia metodológica de las condiciones del laboratorio y justifica adaptaciones posteriores del diseño.

## Metadatos

| Campo | Valor |
| --- | --- |
| Identificador | EXP-00 |
| Fecha | 2026-05-14 |
| Hora de inicio | 9:10 (UTC-5) |
| Hora de finalización | ***** |
| Operadora | Angie Catalina Lemus Leiva |
| Objetivo específico | OE1 (preparación) |
| Sesión Learner Lab | 1 |

## Configuración inicial

| Item | Resultado |
| --- | --- |
| Cuenta AWS (enmascarada) | 660XXXXXXX722 |
| Rol/usuario asignado por el lab | assumed-role/voclabs/userXXXXXXXX |
| Región configurada | us-east-1 |
| Perfil CLI local | learner-lab |

## Entorno local

| Herramienta | Versión |
| --- | --- |
| Sistema operativo | Windows [10/11] |
| PowerShell | [salida de `$PSVersionTable.PSVersion`] |
| AWS CLI | [salida de `aws --version`] |
| Python | [salida de `python --version`] |
| Editor | Visual Studio Code |
| Cliente Git | GitHub Desktop |

*Incidencia durante la configuración del perfil*:
Al crear los archivos `credentials` y `config` con Notepad, Windows agregó automáticamente la extensión `.txt` (oculta por defecto en el Explorador). Esto causó el error `The config profile (learner-lab) could not be found` al ejecutar `aws sts get-caller-identity`. Se resolvió renombrando los archivos para eliminar la extensión con `Rename-Item`. Se deja constancia como nota práctica para futuras réplicas del laboratorio.

## Pruebas de capacidad — IAM

Ejecutar cada comando y registrar el resultado completo.

### IAM-01 — Listar usuarios existentes
```bash
aws iam list-users --profile learner-lab
```
**Resultado**:
- [ ] Permitido — listar resultado relevante.
- [ ] Denegado — pegar el error `AccessDenied` completo.

### IAM-02 — Listar roles existentes
```bash
aws iam list-roles --profile learner-lab
```
**Resultado**:
- [ ] Permitido
- [ ] Denegado

### IAM-03 — Crear usuario IAM nuevo
```bash
aws iam create-user --user-name test-attacker-victim --profile learner-lab
```
**Resultado**:
- [ ] Permitido (importante: este resultado define si la simulación usa un usuario IAM dedicado o se adapta al rol `voclabs`).
- [ ] Denegado

### IAM-04 — Crear política gestionada
```bash
aws iam create-policy --policy-name TestPolicy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}' \
  --profile learner-lab
```
**Resultado**:
- [ ] Permitido
- [ ] Denegado

### IAM-05 — Crear claves de acceso
```bash
aws iam create-access-key --user-name <usuario-creado-en-IAM-03> --profile learner-lab
```
**Resultado**:
- [ ] Permitido (registrar el Access Key ID, **no el Secret**, e indicar que se almacena fuera del repo).
- [ ] Denegado

## Pruebas de capacidad — S3

### S3-01 — Listar buckets
```bash
aws s3 ls --profile learner-lab
```
**Resultado**: ____

### S3-02 — Crear bucket
```bash
aws s3 mb s3://tesis-test-bucket-$(Get-Random) --profile learner-lab
```
**Resultado**: ____

## Pruebas de capacidad — EC2

### EC2-01 — Describir instancias
```bash
aws ec2 describe-instances --profile learner-lab
```
**Resultado**: ____

### EC2-02 — Listar AMIs disponibles
```bash
aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --profile learner-lab --query 'Images[0:10].[ImageId,Name]' --output table
```
**Resultado**: ____

## Pruebas de capacidad — CloudTrail

### CT-01 — Listar trails existentes
```bash
aws cloudtrail describe-trails --profile learner-lab
```
**Resultado**: ____

### CT-02 — Crear trail propio
```bash
# Solo después de crear un bucket destino
aws cloudtrail create-trail --name TesisT1580Trail --s3-bucket-name <bucket-destino> --is-multi-region-trail --profile learner-lab
```
**Resultado**: ____

## Pruebas de capacidad — CloudWatch

### CW-01 — Listar alarmas
```bash
aws cloudwatch describe-alarms --profile learner-lab
```
**Resultado**: ____

### CW-02 — Crear filtro de métrica en log group
```bash
# Reservar para después de configurar CloudTrail
```

## Síntesis de restricciones identificadas

Resumir aquí, en prosa, las restricciones encontradas y cómo se adapta el diseño metodológico:

> Ejemplo: "El Learner Lab no permite la creación de usuarios IAM nuevos (IAM-03 denegado con `AccessDenied: User is not authorized to perform: iam:CreateUser`). Esta restricción obliga a usar el rol `voclabs` como 'identidad comprometida' durante la simulación. Esto se documenta como **limitación metodológica** del laboratorio y se discute en el capítulo de resultados de la tesis."

## Capturas asociadas

- `captures/EXP-00_iam-tests_YYYYMMDD.png`
- `captures/EXP-00_s3-tests_YYYYMMDD.png`
- `captures/EXP-00_ec2-tests_YYYYMMDD.png`
- `captures/EXP-00_cloudtrail-tests_YYYYMMDD.png`

## Conclusión

(Resumen de una o dos líneas con la decisión arquitectónica derivada de esta caracterización.)
