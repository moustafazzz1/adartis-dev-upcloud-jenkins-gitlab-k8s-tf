#!/bin/bash
JENKINS_API_TOKEN=116594c2e30348a25af086ff0bd442107b
curl --header "PRIVATE-TOKEN: c-6vQMnRBqtrDOQmvnf-kjtHXpZs0jhdEWM" -X POST "http://127.0.0.1/api/v4/projects/1/hooks?url=http://jenkins.default.svc.cluster.local:8080/centralized-pipelines/test-job&&enable_ssl_verification=false"      --user "admin:116594c2e30348a25af086ff0bd442107b"
