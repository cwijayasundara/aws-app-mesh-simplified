#!/usr/bin/env bash
# vim:syn=sh:ts=4:sw=4:et:ai

set -ex

if [ -z $AWS_ACCOUNT_ID ]; then
    echo "AWS_ACCOUNT_ID environment variable is not set."
    exit 1
fi

if [ -z $AWS_DEFAULT_REGION ]; then
    echo "AWS_DEFAULT_REGION environment variable is not set."
    exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
FRONTEND_IMAGE=${FRONTEND_IMAGE:-"${ECR_URL}/frontend"}
DIRECTORY_IMAGE=${DIRECTORY_IMAGE:-"${ECR_URL}/directory"}

GO_PROXY=${GO_PROXY:-"https://proxy.golang.org"}
AWS_CLI_VERSION=$(aws --version 2>&1 | cut -d/ -f2 | cut -d. -f1)

ecr_login() {
    if [ $AWS_CLI_VERSION -gt 1 ]; then
        aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | \
            docker login --username AWS --password-stdin ${ECR_URL}
    else
        $(aws ecr get-login --no-include-email)
    fi
}

describe_create_ecr_registry() {
    local repo_name=$1
    local region=$2
    aws ecr describe-repositories --repository-names ${repo_name} --region ${region} \
        || aws ecr create-repository --repository-name ${repo_name} --region ${region}
}

# build
pushd src/frontend
docker build -t $FRONTEND_IMAGE .
popd
pushd src/directory
docker build -t $DIRECTORY_IMAGE .
popd 

# push
ecr_login
describe_create_ecr_registry frontend ${AWS_DEFAULT_REGION}
describe_create_ecr_registry directory ${AWS_DEFAULT_REGION}

docker push $FRONTEND_IMAGE
docker push $DIRECTORY_IMAGE