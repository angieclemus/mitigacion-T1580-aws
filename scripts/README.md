# Scripts auxiliares

## `reconnaissance/00-baseline-recon.sh`

Script de caracterización del entorno AWS Academy Learner Lab. Es lo primero que se ejecuta en la primera sesión del laboratorio, después de configurar el perfil de AWS CLI.

### Uso

```bash
# Configurar el perfil (una sola vez, copiando las credenciales del Learner Lab)
aws configure --profile learner-lab

# Ejecutar el reconocimiento
bash scripts/reconnaissance/00-baseline-recon.sh 2>&1 | tee recon-output.txt
```

La salida se lleva a `evidence/00-baseline-environment.md` para completar la documentación.

> **Importante**: el archivo `recon-output.txt` puede contener Account IDs, ARNs y otra información sensible. **No subirlo al repositorio**. Está cubierto por `.gitignore`.

## Recordatorio sobre credenciales

Las credenciales del Learner Lab se obtienen del botón **"AWS Details"** dentro del Learner Lab y tienen el formato:

```
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

Estas credenciales **caducan al finalizar la sesión** y se renuevan al iniciar la siguiente. El perfil `learner-lab` debe actualizarse en cada sesión.
