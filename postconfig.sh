#!/bin/bash
# Terraform-Konfiguration wird geplant und automatisch angewendet.
terraform plan
terraform apply --auto-approve
# Die kubeconfig-Datei wird als Umgebungsvariable gesetzt, um mit dem Kubernetes-Cluster zu interagieren.
export KUBECONFIG=`pwd`"/uks-instructions/terraform/cluster/kubeconfig.yml"
# Ein GitLab-API-Token wird aus der Terraform-Ausgabe abgerufen und in einer Variablen gespeichert.
TOKEN_STRING=`terraform output api_token | tr -d '"'`
# Das gleiche GitLab-API-Token wird in einer lokalen Datei `/tmp/token` für die weitere Nutzung gespeichert.
terraform output api_token | tr -d '"' > /tmp/token
# GitLab wird mithilfe der Konfigurationsdatei `gitlab/gitlab.yaml` im Kubernetes-Cluster bereitgestellt.
kubectl apply -f gitlab/gitlab.yaml
# Der Name des GitLab-Pods wird dynamisch mithilfe eines Kubernetes-Befehls abgerufen und in einer Variablen gespeichert.
POD_NAME=$(kubectl get pods -n default -l app=gitlab -o json | jq -r  .items[0].metadata.name)
NAMESPACE=default

# Funktion, die darauf wartet, dass der angegebene Pod bereit ist.
wait_for_pod_ready() {
    local POD_NAME=$1 # Name des zu überprüfenden Pods.
    local INTERVAL=${2:-10}  # Default interval is 10 seconds

    while true; do
    # Überprüfen Sie den Bereitschaftsstatus der Container des Pods.
        local STATUS=$(kubectl get pod $POD_NAME --no-headers -o custom-columns=":status.containerStatuses[*].ready" | tr ',' '\n' | grep -v 'true')
        
        if [[ -z "$STATUS" ]]; then
            echo "Pod $POD_NAME is Running"
            break
        else
            echo "$(date) : Pod $POD_NAME is not yet ready"
            echo "Unready containers: $STATUS"
            sleep $INTERVAL
        fi
    done
}
# Warten, bis der GitLab-Pod bereit ist.
wait_for_pod_ready $POD_NAME 15
# Das API-Token wird von der lokalen Datei `/tmp/token` in den GitLab-Pod kopiert, um es intern zu verwenden.
kubectl cp /tmp/token $NAMESPACE/$POD_NAME:/tmp -c gitlab
# Das anfängliche Root-Passwort von GitLab wird aus dem Pod extrahiert und lokal in der Datei `Initial_Root_Pass_Gitlab` gespeichert.
kubectl exec -it $POD_NAME -- grep Password:  /etc/gitlab/initial_root_password > Initial_Root_Pass_Gitlab 
echo -e "\n"
# Hier wird Personal Access Token erstellt, um ein neues Projekt auf gitlab mit dem Name "centralized-pipelines" am Zeile 39 durch den Personal Access Token (TOKEN_STRING) erstellt zu werden. 
kubectl exec -it $POD_NAME -- gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api, :read_api, :read_user, :create_runner, :k8s_proxy, :read_repository, :write_repository, :ai_features, :sudo, :admin_mode, :read_service_ping], name: 'Automation token', expires_at: '2024-08-08'); token.set_token('$TOKEN_STRING'); token.save!"
echo -e "\n"
# Ein neues Projekt namens `centralized-pipelines` wird auf GitLab mit dem Personal Access Token erstellt.
kubectl exec -it $POD_NAME -- curl --header "PRIVATE-TOKEN: $TOKEN_STRING" -X POST http://127.0.0.1/api/v4/projects?name=centralized-pipelines
echo -e "\n"
# Hier erstelle ich die Schlüssel. Ich benutze diese Schlüssel, damit der sample repo auf gitlab geschikt wird. Weitere Info finden Sie in push_repo.sh
KEY_PATH="./key_pairs/"
KEY_FILENAME="id_rsa"
mkdir -p $KEY_PATH

if [[ -f $KEY_PATH/$KEY_FILENAME || -f $KEY_PATH/$KEY_FILENAME.pub ]]; then
    echo "SSH key pair already exists in the specified path."
else
   # Ein neues SSH-Schlüsselpaar wird erstellt, falls es nicht bereits vorhanden ist.
    ssh-keygen -t rsa -b 4096 -f $KEY_PATH/$KEY_FILENAME -N ""
fi
# Der öffentliche Schlüssel wird zur Referenz angezeigt.
echo "Your public key is:"
cat $KEY_PATH/$KEY_FILENAME.pub
# Die Datei-Berechtigungen für den privaten Schlüssel werden korrekt gesetzt.
chmod 400 $KEY_PATH/$KEY_FILENAME
# Das SSH-Schlüsselpaar und andere erforderliche Dateien werden in den GitLab-Pod kopiert.
kubectl cp $KEY_PATH$KEY_FILENAME.pub $POD_NAME:/tmp -c gitlab
kubectl cp $KEY_PATH$KEY_FILENAME $POD_NAME:/tmp -c gitlab
kubectl cp ./sampleapp $NAMESPACE/$POD_NAME:/tmp -c gitlab
kubectl cp /tmp/token $NAMESPACE/$POD_NAME:/tmp -c gitlab
kubectl cp ./push_repo.sh $NAMESPACE/$POD_NAME:/tmp -c gitlab
# Sicherstellen, dass das Skript `push_repo.sh` im GitLab-Pod ausführbar ist.
kubectl exec -it $POD_NAME -- chmod +x /tmp/push_repo.sh
# Das Skript `push_repo.sh` wird im GitLab-Pod ausgeführt, um Beispielcode oder Konfigurationen hochzuladen.
kubectl exec -it $POD_NAME -- ./tmp/push_repo.sh


# Jenkins-Installation und -Konfiguration.
JENKINS_POD_NAME="jenkins-0"
# Die Jenkins-Secret-Datei wird mit dem GitLab-Token aktualisiert.
sed -i -e "/^[[:space:]]*text:/s|:.*|: $TOKEN_STRING|" jenkins/secret.yaml
# Die Secrets werden angewendet und Jenkins wird mit Helm bereitgestellt.
kubectl apply -f jenkins/secret_ssh.yaml
kubectl apply -f jenkins/secret.yaml
helm upgrade -i jenkins jenkins/jenkins -f jenkins/jenkins/values.yaml
# Warten, bis der Jenkins-Pod bereit ist.
wait_for_pod_ready $JENKINS_POD_NAME 15

# Hier wird api token von Jenkins erstellt. 
cat << 'EOF' > jenkins_api_token.sh
#!/bin/bash
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_USER_PASS="admin123"
JENKINS_CRUMB=$(curl -u "$JENKINS_USER:$JENKINS_USER_PASS" -s --cookie-jar /tmp/cookies $JENKINS_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
curl -u "$JENKINS_USER:$JENKINS_USER_PASS" -H "$JENKINS_CRUMB" -s \
                    --cookie /tmp/cookies $JENKINS_URL'/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken' \
                    --data 'newTokenName=GlobalToken' > /tmp/jenkins_api_token
EOF

#webhook

kubectl cp ./jenkins_api_token.sh  $NAMESPACE/$JENKINS_POD_NAME:/tmp/jenkins_api_token.sh  -c jenkins
kubectl exec -it $JENKINS_POD_NAME -- bash -c "chmod +x /tmp/jenkins_api_token.sh && ./tmp/jenkins_api_token.sh"
kubectl cp  $NAMESPACE/$JENKINS_POD_NAME:/tmp/jenkins_api_token jenkins_api_token -c jenkins
JENKINS_API_TOKEN=$(cat jenkins_api_token| jq -r '.data.tokenValue')
cat << EOF > webhook.sh
#!/bin/bash
JENKINS_API_TOKEN=$JENKINS_API_TOKEN
curl --header "PRIVATE-TOKEN: $TOKEN_STRING" -X POST "http://127.0.0.1/api/v4/projects/1/hooks?url=http://jenkins.default.svc.cluster.local:8080/centralized-pipelines/test-job&&enable_ssl_verification=false" \
     --user "admin:$JENKINS_API_TOKEN"
EOF
kubectl cp  webhook.sh $NAMESPACE/$POD_NAME:/tmp/webhook.sh  -c gitlab 
#Install Nexus

helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm upgrade -i nexus-repository-manager sonatype/nexus-repository-manager --version 64.2.0
NEXUS_POD_NAME=$(kubectl get pods -n default -l app.kubernetes.io/instance=nexus-repository-manager -o json | jq -r  .items[0].metadata.name)
wait_for_pod_ready $NEXUS_POD_NAME 15
kubectl exec -it $NEXUS_POD_NAME -- bash -c "cat /nexus-data/admin.password" > Initial_Root_Pass_Nexus
##################

