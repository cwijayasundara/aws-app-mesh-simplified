#!/bin/bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [ -z "${ENVOY_IMAGE}" ]; then
    echo "ENVOY_IMAGE environment is not defined"
    exit 1
fi

if [ -z "${COLOR_GATEWAY_IMAGE}" ]; then
    echo "COLOR_GATEWAY_IMAGE environment is not defined"
    exit 1
fi

if [ -z "${COLOR_TELLER_IMAGE}" ]; then
    echo "COLOR_TELLER_IMAGE environment is not defined"
    exit 1
fi

stack_output=$(aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    cloudformation describe-stacks --stack-name "${ENVIRONMENT_NAME}-ecs-cluster" \
    | jq '.Stacks[].Outputs[]')

task_role_arn=($(echo $stack_output \
    | jq -r 'select(.OutputKey == "TaskIamRoleArn") | .OutputValue'))

execution_role_arn=($(echo $stack_output \
    | jq -r 'select(.OutputKey == "TaskExecutionIamRoleArn") | .OutputValue'))

ecs_service_log_group=($(echo $stack_output \
    | jq -r 'select(.OutputKey == "ECSServiceLogGroup") | .OutputValue'))

envoy_log_level="debug"

generate_xray_container_json() {
    app_name=$1
    xray_container_json=$(jq -n \
    --arg ECS_SERVICE_LOG_GROUP $ecs_service_log_group \
    --arg AWS_REGION $AWS_DEFAULT_REGION \
    --arg AWS_LOG_STREAM_PREFIX "${app_name}-xray" \
    -f "${DIR}/xray-container.json")
}

generate_envoy_container_json() {
    app_name=$1
    envoy_container_json=$(jq -n \
    --arg ENVOY_IMAGE $ENVOY_IMAGE \
    --arg VIRTUAL_NODE "mesh/$MESH_NAME/virtualNode/${app_name}-vn" \
    --arg APPMESH_XDS_ENDPOINT "${APPMESH_XDS_ENDPOINT}" \
    --arg ENVOY_LOG_LEVEL $envoy_log_level \
    --arg ECS_SERVICE_LOG_GROUP $ecs_service_log_group \
    --arg AWS_REGION $AWS_DEFAULT_REGION \
    --arg AWS_LOG_STREAM_PREFIX "${app_name}-envoy" \
    -f "${DIR}/envoy-container.json")
}

generate_sidecars() {
    app_name=$1
    generate_envoy_container_json ${app_name}
    generate_xray_container_json ${app_name}
}

generate_version_teller_task_def() {
    version=$1
    task_def_json=$(jq -n \
    --arg NAME "$ENVIRONMENT_NAME-backend-${version}" \
    --arg STAGE "$APPMESH_STAGE" \
    --arg VERSION "${version}" \
    --arg APP_IMAGE $COLOR_TELLER_IMAGE \
    --arg AWS_REGION $AWS_DEFAULT_REGION \
    --arg ECS_SERVICE_LOG_GROUP $ecs_service_log_group \
    --arg AWS_LOG_STREAM_PREFIX_APP "backend-${version}-app" \
    --arg TASK_ROLE_ARN $task_role_arn \
    --arg EXECUTION_ROLE_ARN $execution_role_arn \
    --argjson ENVOY_CONTAINER_JSON "${envoy_container_json}" \
    --argjson XRAY_CONTAINER_JSON "${xray_container_json}" \
    -f "${DIR}/backend-base-task-def.json")
    # echo !!!!
    # echo $task_def_json | jq .
    task_def=$(aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    ecs register-task-definition \
    --cli-input-json "$task_def_json")
}

# Color Gateway Task Definition
generate_sidecars "directory"
task_def_json=$(jq -n \
    --arg NAME "$ENVIRONMENT_NAME-Gateway" \
    --arg STAGE "$APPMESH_STAGE" \
    --arg API_ENDPOINT "http://backend.$SERVICES_DOMAIN:9080/api" \
    --arg TCP_ECHO_ENDPOINT "tcpecho.$SERVICES_DOMAIN:2701" \
    --arg APP_IMAGE $COLOR_GATEWAY_IMAGE \
    --arg AWS_REGION $AWS_DEFAULT_REGION \
    --arg ECS_SERVICE_LOG_GROUP $ecs_service_log_group \
    --arg AWS_LOG_STREAM_PREFIX_APP "gateway-app" \
    --arg TASK_ROLE_ARN $task_role_arn \
    --arg EXECUTION_ROLE_ARN $execution_role_arn \
    --argjson ENVOY_CONTAINER_JSON "${envoy_container_json}" \
    --argjson XRAY_CONTAINER_JSON "${xray_container_json}" \
    -f "${DIR}/gateway-base-task-def.json")


    
echo $task_def_json | jq .
task_def=$(aws --profile "${AWS_PROFILE}" --region "${AWS_DEFAULT_REGION}" \
    ecs register-task-definition \
    --cli-input-json "$task_def_json")
gateway_task_def_arn=($(echo $task_def \
    | jq -r '.taskDefinition | .taskDefinitionArn'))

# Color Teller White Task Definition
generate_sidecars "backend-v1"
generate_version_teller_task_def "v1"
backend_task_def_arn=($(echo $task_def \
    | jq -r '.taskDefinition | .taskDefinitionArn'))
# 
# # Color Teller Red Task Definition
generate_sidecars "backend-v2"
generate_version_teller_task_def "v2"
backend_v2_task_def_arn=($(echo $task_def \
    | jq -r '.taskDefinition | .taskDefinitionArn'))
# 
# # Color Teller Blue Task Definition
# generate_sidecars "colorteller-blue"
# generate_color_teller_task_def "blue"
# colorteller_blue_task_def_arn=($(echo $task_def \
#     | jq -r '.taskDefinition | .taskDefinitionArn'))
# 
# # Color Teller Black Task Definition
# generate_sidecars "colorteller-black"
# generate_color_teller_task_def "black"
# colorteller_black_task_def_arn=($(echo $task_def \
#     | jq -r '.taskDefinition | .taskDefinitionArn'))