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
penpotapp/frontend:latest # this is on port 80, you'll need to switch to 8080 in the nginx config
penpotapp/backend:latest
penpotapp/exporter:latest
```

Note that the default `penpotapp/frontend` image runs on port 80 and won't work with this infrastructure.  You can rebuild the Docker image to use port 8080 with the [nginx.conf from the official Penpot repo](https://github.com/penpot/penpot/blob/develop/docker/images/files/nginx.conf):

```dockerfile
FROM penpotapp/frontend:latest

USER root

ADD ./files/nginx.conf /etc/nginx/nginx.conf.template
RUN chown -R 1001:0 /etc/nginx;

USER penpot:penpot
```

:warning: Still very much a work in progress and chalk full of bugs.
