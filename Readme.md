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

## Moustafa New

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
