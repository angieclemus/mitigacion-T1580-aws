#!/usr/bin/env bash
# ============================================================================
# 00-baseline-recon.sh
# ----------------------------------------------------------------------------
# Caracterización del entorno AWS Academy Learner Lab antes de construir
# cualquier recurso. Cada comando es no destructivo y prueba qué permite
# el laboratorio.
#
# Uso:
#   1. Configurar el perfil 'learner-lab' con `aws configure --profile learner-lab`
#      usando las credenciales mostradas en "AWS Details" del Learner Lab.
#   2. Ejecutar:  bash 00-baseline-recon.sh 2>&1 | tee recon-output.txt
#   3. Llevar la salida a evidence/00-baseline-environment.md
# ============================================================================

set +e   # No salir ante errores: queremos registrar cada AccessDenied.

PROFILE="learner-lab"
REGION="us-east-1"

section() {
  echo
  echo "================================================================="
  echo "==  $1"
  echo "================================================================="
}

run() {
  echo
  echo "[CMD] $*"
  eval "$@"
  echo "[EXIT] $?"
}

section "1. Identidad asignada por el lab"
run "aws sts get-caller-identity --profile $PROFILE"

section "2. IAM — capacidades"
run "aws iam list-users --profile $PROFILE --max-items 5"
run "aws iam list-roles --profile $PROFILE --max-items 5"
run "aws iam list-policies --profile $PROFILE --scope Local --max-items 5"
run "aws iam create-user --user-name test-attacker-victim --profile $PROFILE"
run "aws iam delete-user --user-name test-attacker-victim --profile $PROFILE"

section "3. S3 — capacidades"
run "aws s3 ls --profile $PROFILE"
run "aws s3control get-public-access-block --account-id \$(aws sts get-caller-identity --profile $PROFILE --query Account --output text) --profile $PROFILE"

section "4. EC2 — capacidades"
run "aws ec2 describe-instances --profile $PROFILE --region $REGION --max-items 5"
run "aws ec2 describe-security-groups --profile $PROFILE --region $REGION --max-items 5"
run "aws ec2 describe-images --owners amazon --filters Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2 --profile $PROFILE --region $REGION --query 'Images[0:3].[ImageId,Name]' --output table"

section "5. CloudTrail — capacidades"
run "aws cloudtrail describe-trails --profile $PROFILE --region $REGION"
run "aws cloudtrail lookup-events --max-results 5 --profile $PROFILE --region $REGION"

section "6. CloudWatch — capacidades"
run "aws cloudwatch describe-alarms --profile $PROFILE --region $REGION --max-items 5"
run "aws logs describe-log-groups --profile $PROFILE --region $REGION --max-items 5"

section "Fin del reconocimiento."
echo "Llevar esta salida a evidence/00-baseline-environment.md y completar la síntesis."
