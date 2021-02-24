# Overview
Normally I would have retained the git history of the source, but am creating a new one for convenience.

I noticed someone has recently used aws account this and stored terraform state files in s3. I will likely do the same as terraform best practices state to store state file remotely for team situations.

Added default scan for vulnerabilities.

Not sure about best way to push the state file to s3 at the moment. I assume it would be best in a pipe step in circle ci, post terraform apply, to ensure there's no human error/forgetfulness/cross environment issues here.

## TODO
VPC
Versioning
Leave docker image tag as mutable until satisfactory versioning scheme determined