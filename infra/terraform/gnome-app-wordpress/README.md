# Gnome App Wordpress

A simple project to deploy a wordpress container into ECS Fargate

## Design

The first decision for me is a no-brainer, we are using a container for our application runtime environment.

Why ? It's portable, easy to deploy and doesn't require any complex configuration management tools.

Secondly, which container runtime to use? In AWS we have a few options:

* EC2 with Docker [x]
* Elastic Beanstalk [x]
* Elastic Containter Service [/]
* Elastic Kubernetes Service [x]

EC2 and Elastic Beanstalk would be OK for a straightforward app, but require setting up autoscaling groups and managing and patching an operating system.
We don't really want to have to do this unless there's a good reason.

Elastic Kubernetes Service is a fantastic managed Kubernetes control plane service, but requires a lot of configuration and the control plane still needs
updating, as do the supporting services such as networking and DNS. It is overkill for our requirements.

Elastic Container Service is a great container orchestration service, yet running workloads still requires setting up EC2 instances. However we can
leverage fargate to leverage AWS serverless functionality to run our containers. This requires no infrastructure setup and minimal ECS cluster configuration.

## Where to start

1. Writing any configuration from scratch is time consuming, so I suggest always looking
for a template and/or modules to do most of the heavy lifting.

2. Next we should set up the automation straight away, we want our resources deployed
by a machine not a developer. This will create the right conditions for
consistency and collaboration.

3. Once we have the pieces in place we can customise the configuration to suit our needs and start testing it.

## My approach

I already have an automation bootstrapper written for terraform HCP so I have
leveraged this to deploy into a sandbox AWS account. See `terraform-cloud-aws-bootstrap`