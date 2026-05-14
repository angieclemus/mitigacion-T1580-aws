# EXP-00 — Caracterización del entorno AWS Academy Learner Lab

> Propósito del documento: registrar las capacidades y restricciones reales del entorno experimental durante la primera sesión, antes de construir cualquier recurso. Sirve como evidencia metodológica de las condiciones del laboratorio y justifica adaptaciones posteriores del diseño.

## Metadatos

| Campo | Valor |
| --- | --- |
| Identificador | EXP-00 |
| Fecha | 2026-05-14 |
| Hora de inicio | 13:00 (UTC-5) |
| Hora de finalización | 13:40 |
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
| Sistema operativo | Windows 11 |
| PowerShell | 5.1.26100.8115 |
| AWS CLI | 2.34.45 (Python 3.14.4 embebido) |
| Python (sistema) | 3.12.10 |
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
{                                                                                                                                                              
    "Users": []
}

### IAM-02 — Listar roles existentes
```bash
aws iam list-roles --profile learner-lab
```
**Resultado**:
- [x] Permitido — se listaron 21 roles. Roles relevantes identificados:
  - `voclabs`: rol operativo asumido actualmente (identidad "comprometida" para EXP-01).
  - `LabRole`: rol de instancia EC2 del laboratorio (se usará en la arquitectura baseline).
  - `vocareum` / `vocareum-eventbridge`: roles de la plataforma Vocareum (solo lectura, no se modifican).
  - El resto son roles de servicio AWS estándar (`AWSServiceRoleFor*`) y roles preconfigurados de otros módulos del curso (EKS, Lambda, EMR, Redshift).
- [ ] Denegado

### IAM-03 — Crear usuario IAM nuevo
```bash
aws iam create-user --user-name test-attacker-victim --profile learner-lab
```
**Resultado**:
- [ ] Permitido
- [x] Denegado — `AccessDenied: User: arn:aws:sts::660XXXXXXX722:assumed-role/voclabs/userXXXXXXXX=Angie_Lemus is not authorized to perform: iam:CreateUser on resource: arn:aws:iam::660XXXXXXX722:user/test-attacker-victim because no identity-based policy allows the iam:CreateUser action`

> *Impacto metodológico*: el Learner Lab no permite la creación de usuarios IAM. Esta restricción obliga a usar el rol `voclabs` como identidad "comprometida" durante la simulación de T1580 en EXP-01 y EXP-03. Se documenta como *limitación metodológica* del laboratorio y se discutirá en el capítulo de resultados de la tesis.

### IAM-04 — Crear política gestionada
```bash
aws iam create-policy --policy-name TestPolicy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}' \
  --profile learner-lab
```
**Resultado**:
- [x] Permitido — política creada exitosamente (`arn:aws:iam::660XXXXXXX722:policy/TestPolicy`). El rol `voclabs` tiene permiso `iam:CreatePolicy`. Esto implica que la arquitectura baseline puede simular configuraciones de política permisivas.
- [ ] Denegado


### IAM-05 — Crear claves de acceso
```bash
aws iam create-access-key --user-name <usuario-creado-en-IAM-03> --profile learner-lab
```
**Resultado**:
- [ ] Permitido
- [x] Denegado — `AccessDenied: iam:CreateAccessKey` denegado sobre el recurso `user test-attacker-victim`. Resultado esperado: el usuario no existe (IAM-03 fue denegado) y además el rol `voclabs` no tiene permiso para crear claves de acceso programáticas para otros usuarios.


## Pruebas de capacidad — S3

### S3-01 — Listar buckets
```bash
aws s3 ls --profile learner-lab
```
**Resultado**:
- [x] Permitido — sin output (lista vacía). No existen buckets S3 en la cuenta del Learner Lab en este momento.
- [ ] Denegado


### S3-02 — Crear bucket
```bash
aws s3 mb s3://tesis-test-bucket-$(Get-Random) --profile learner-lab
```
**Resultado**:
- [x] Permitido — bucket creado exitosamente (`tesis-test-13909761`). El rol `voclabs` tiene permisos completos sobre S3. Este bucket de prueba puede eliminarse al final de la sesión o quedará borrado al reiniciar el lab.
- [ ] Denegado


## Pruebas de capacidad — EC2

### EC2-01 — Describir instancias
```bash
aws ec2 describe-instances --profile learner-lab
```
**Resultado**:
- [x] Permitido — sin output (sin instancias EC2 activas en la cuenta).
- [ ] Denegado


### EC2-02 — Listar AMIs disponibles
```bash
aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --profile learner-lab --query 'Images[0:10].[ImageId,Name]' --output table
```
**Resultado**:
- [x] Permitido — se listaron AMIs de Amazon Linux 2 disponibles en us-east-1. AMI más reciente identificada: `ami-03fdf597129d2144d` (amzn2-ami-hvm-2.0.20260511.1-x86_64-gp2). Se usará como base para la instancia EC2 en EXP-02.
- [ ] Denegado


## Pruebas de capacidad — CloudTrail

### CT-01 — Listar trails existentes
```bash
aws cloudtrail describe-trails --profile learner-lab
```
**Resultado**:
- [x] Permitido — `trailList` vacío. No existe ningún trail de CloudTrail configurado en la cuenta. Esto confirma el estado baseline sin observabilidad, condición necesaria para EXP-01 (ataque sin detección).
- [ ] Denegado


### CT-02 — Crear trail propio
```bash
# Solo después de crear un bucket destino
aws cloudtrail create-trail --name TesisT1580Trail --s3-bucket-name <bucket-destino> --is-multi-region-trail --profile learner-lab
```
**Resultado**:
- [x] Permitido (con prerrequisito) — el rol `voclabs` tiene permiso `cloudtrail:CreateTrail`. El comando falló con `InsufficientS3BucketPolicyException`, no con `AccessDenied`. El bucket de prueba no tiene la política de recurso requerida por CloudTrail. La creación del trail definitivo (CTL-06) requiere configurar previamente la bucket policy correspondiente.
- [ ] Denegado


## Pruebas de capacidad — CloudWatch

### CW-01 — Listar alarmas
```bash
aws cloudwatch describe-alarms --profile learner-lab
```
**Resultado**:
- [x] Permitido — sin output (ninguna alarma CloudWatch configurada). Confirma estado baseline sin monitoreo activo.
- [ ] Denegado


### CW-02 — Crear filtro de métrica en log group
```bash
# Reservar para después de configurar CloudTrail
```

## Síntesis de restricciones identificadas

El entorno AWS Academy Learner Lab presenta las siguientes capacidades y restricciones identificadas durante EXP-00:

**Permisos IAM:** el rol `voclabs` puede listar usuarios y roles (`iam:ListUsers`, `iam:ListRoles`), y crear políticas gestionadas (`iam:CreatePolicy`). Sin embargo, **no puede crear usuarios IA** (`iam:CreateUser` denegado) ni crear claves de acceso programáticas (`iam:CreateAccessKey` denegado). Esta restricción obliga a usar el propio rol `voclabs` como identidad "comprometida" durante la simulación de T1580 en EXP-01 y EXP-03. 
Se documenta como **limitación metodológica** del laboratorio: en un entorno de producción real existirían dos identidades separadas (víctima y atacante), pero el lab las colapsa en una sola. Esta adaptación se ve dentro de la metodología DSR como una restricción del entorno de artefacto y será discutida en el capítulo de resultados de la tesis.

**S3:** permisos completos de lectura y escritura. El rol puede listar y crear buckets sin restricciones.

**EC2:** permisos de solo lectura verificados (`ec2:DescribeInstances`, `ec2:DescribeImages`). No se probó la creación de instancias en esta fase; se confirma para EXP-02.

**CloudTrail:** el rol tiene permiso para crear trails (`cloudtrail:CreateTrail`). La prueba CT-02 falló con `InsufficientS3BucketPolicyException` (no con `AccessDenied`), lo que indica que el permiso existe pero requiere configurar previamente la política del bucket destino. El entorno no tiene trails activos, lo que confirma la ausencia de observabilidad en el estado baseline.

**CloudWatch:** ninguna alarma configurada. Confirma la ausencia de monitoreo activo en el estado baseline.

**Decisión arquitectónica derivada:** el diseño de EXP-01 usará el rol `voclabs` como identidad única (atacante y propietario). Los estados baseline de CloudTrail y CloudWatch sin configuración confirman que EXP-01 se puede ejecutar sin alertas ni logs previos que contaminen la evidencia.


## Capturas asociadas

- `captures/EXP-00_iam-tests_20260514.png`

## Conclusión

El Learner Lab provee acceso suficiente para ejecutar los experimentos EXP-01 a EXP-03. La única restricción crítica es la imposibilidad de crear usuarios IAM, que se resuelve usando el rol `voclabs` como identidad comprometida y se documenta como limitación metodológica. El estado baseline sin CloudTrail ni alarmas CloudWatch es adecuado para iniciar EXP-01.
