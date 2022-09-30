based on https://github.com/aws/aws-app-mesh-examples/tree/main/examples/apps/colorapp

Set the environment variables


```
export AWS_PROFILE=default
export AWS_DEFAULT_REGION=ap-southeast-2
export ENVIRONMENT_NAME=DEMO
export SERVICES_DOMAIN=demo.local
export MESH_NAME=appmesh-mesh
export KEY_PAIR_NAME=uncle-russ
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export ENVOY_IMAGE=840364872350.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy:v1.21.1.1-prod
export COLOR_GATEWAY_IMAGE=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/frontend
export COLOR_TELLER_IMAGE=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/backend
```

Install everything

```
./vpc.sh
./appmesh-mesh.sh
./appmesh-colorapp.sh
./ecs-cluster.sh
./appmesh-colorapp.sh

aws ecr create-repository --repository-name frontend
aws ecr create-repository --repository-name backend

pushd src/directory ; docker build -t ${COLOR_TELLER_IMAGE} . ; popd
pushd src/frontend ; docker build -t ${COLOR_GATEWAY_IMAGE} . ; popd

aws ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com

docker push ${COLOR_TELLER_IMAGE} ; docker push ${COLOR_GATEWAY_IMAGE}

sudo yum install jq
./ecs/ecs-meshapp.sh 

```
# aws-app-mesh-simplified
