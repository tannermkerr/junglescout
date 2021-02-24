# Overview
application endpoint: [JS App](http://jsapp-alb-name-1381614574.us-west-2.elb.amazonaws.com)
In a readme I would normally describe the application at a high level with links to docs containing diagrams etc. 

Depending on the requirements of the application, one way to scale would be to provide a list of regions to the stack, in order to deploy the necessary infrastructure (load balancer, tasks, services, etc.). I have only implemented one region, but expanding the stack/ci config to deploy multiple clusters across regions wouldn't be too difficult or time consuming. This assumption is based on other Iac tools I've worked with, so I'd consult the experts/research the best ways to do so.

## NOTE
* Normally I would have retained the git history of the source, but am creating a new one for convenience.
* I would prefer a Iac repository separate from the source, but again I put it all in here for convenience for those who will look at it.
* Also, this is my first time using ECR, ECS, circleci, and terraform, so might not be using best naming conventions/best practices.
* This assumes that the stack exists prior to making changes to the source, as the stack defines the ecr repository that circle ci publishes to.
* I noticed someone has recently used this aws account and stored terraform state files in s3. I will do the same as terraform best practices state to store state file remotely for team situations.
* Not sure about best way to push the state file to s3 at the moment. I assume it would be best in a pipe step in circle ci, after a  terraform apply, to ensure there's no human error/forgetfulness/cross environment issues here.

## TODO
* dedicated VPC if necessary
* Version tagging/ immutable image tags
* https/disable http
* route53
* cloudfront 
* penetration tests
* autoscaling
* rate limiting
* attribute based access control