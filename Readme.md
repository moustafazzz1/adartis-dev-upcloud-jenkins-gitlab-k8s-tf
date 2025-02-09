- Step 1: `terraform init && terraform apply`
- Step 2: `./postconfig.sh`
- Step 3: 
#Note Manual Step Due to Gitlab missing Config
https://gitlab.com/gitlab-org/gitlab/-/issues/21806

Solution:
Gitlab Console -> Admin Area > Settings -> Network -> outbound Requests ->    
Allow requests to the local network from webhooks and integrations :: Note Allow it by marking on this attrib:
- After Setup Execute these commands to add webhook
- Step 4
```bash 
POD_NAME=$(kubectl get pods -n default -l app=gitlab -o json | jq -r  .items[0].metadata.name)

kubectl exec -it $POD_NAME -- bash -c "chmod +x /tmp/webhook.sh && ./tmp/webhook.sh"
```


## Explanation of `webhook.sh`

The `webhook.sh` script automates the creation of a webhook in GitLab to enable communication between GitLab and Jenkins. This webhook ensures that Jenkins pipelines are triggered automatically when specific GitLab events occur.

### Purpose of the Script

- **API Tokens:**
  - `PRIVATE-TOKEN`: Authenticates requests to the GitLab API.
  - `JENKINS_API_TOKEN`: Used for Jenkins API authentication.

- **Webhook Configuration:**
  - Sends a `POST` request to the GitLab API to create a webhook for project ID `1`.
  - The webhook URL is `http://jenkins.default.svc.cluster.local:8080/centralized-pipelines/test-job`, which points to the Jenkins service running inside the Kubernetes cluster.

- **SSL Verification:**
  - The `enable_ssl_verification=false` parameter disables SSL verification for the webhook, as communication occurs within the internal Kubernetes network.

---

### `webhook.sh` Script Content

```bash
#!/bin/bash
JENKINS_API_TOKEN=116594c2e30348a25af086ff0bd442107b
curl --header "PRIVATE-TOKEN: c-6vQMnRBqtrDOQmvnf-kjtHXpZs0jhdEWM" \
  -X POST "http://127.0.0.1/api/v4/projects/1/hooks?url=http://jenkins.default.svc.cluster.local:8080/centralized-pipelines/test-job&&enable_ssl_verification=false" \
  --user "admin:116594c2e30348a25af086ff0bd442107b"
