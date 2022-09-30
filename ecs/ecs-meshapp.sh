#!/bin/bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# ecs-colorapp.yaml expects "true" or "false" (default is "false")
# will deploy the TesterService, which perpetually invokes /color to generate history
: "${DEPLOY_TESTER:=false}"

# Creating Task Definitions
source ${DIR}/create-task-defs.sh

aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation deploy \
    --stack-name "${ENVIRONMENT_NAME}-ecs-meshapp" \
    --capabilities CAPABILITY_IAM \
    --template-file "${DIR}/ecs-meshapp.yaml"  \
    --parameter-overrides \
    EnvironmentName="${ENVIRONMENT_NAME}" \
    ECSServicesDomain="${SERVICES_DOMAIN}" \
    AppMeshMeshName="${MESH_NAME}" \
    GatewayTaskDefinition="${gateway_task_def_arn}" \
    BackendTaskDefinition="${backend_task_def_arn}" \
    BackendV2TaskDefinition="${backend_v2_task_def_arn}" \
    ColorTellerBlueTaskDefinition="${colorteller_blue_task_def_arn}" \
    ColorTellerBlackTaskDefinition="${colorteller_black_task_def_arn}" \
    DeployTester="${DEPLOY_TESTER}"