# AWS ECS Penpot
[Self-hosting Penpot](https://help.penpot.app/technical-guide/getting-started/) in an AWS ECS Fargate cluster.

```sh
cd terragrunt/env/staging
terragrunt init
terragrunt apply --target=aws_ecs_cluster.penpot
terragrunt apply
```

Once the Terraform is finished, you'll need to push up the following images to the ECRs:

```sh
docker tag penpotapp/backend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/penpotapp/backend:latest
docker tag penpotapp/exporter:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/penpotapp/exporter:latest

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/penpotapp/backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/penpotapp/exporter:latest
```

You will also need to build your own version of the `penpotapp/frontend` image as the official image listens on port `80`.

```sh
# Clone the official repo
git clone https://github.com/penpot/penpot.git
cd penpot

# Build the frontend bundle
./manage.sh build-frontend-bundle

# Build and push the image
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/penpot-frontend:latest -f ./docker/images/Dockerfile.frontend ./docker/images 
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/penpotapp/frontend:latest
```

:warning: Still very much a work in progress and chalk full of bugs.
