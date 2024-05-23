#!/bin/bash
JENKINS_API_TOKEN=11a3fe97fde2df3bb26c88b218bde15f9c
curl --header "PRIVATE-TOKEN: m4nWa0wwt0bpMF4Am_Jiap86q3Wb-QQlFhQ" -X POST "http://127.0.0.1/api/v4/projects/1/hooks?url=http://jenkins.default.svc.cluster.local:8080/centralized-pipelines/test-job&&enable_ssl_verification=false"      --user "admin:11a3fe97fde2df3bb26c88b218bde15f9c"
