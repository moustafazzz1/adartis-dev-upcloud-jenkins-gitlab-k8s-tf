#!/bin/bash
TOKEN_STRING=`cat /tmp/token`
NAMESPACE=default
KEY_PATH="./key_pairs/"
KEY_FILENAME="id_rsa"
eval `ssh-agent` 
chmod 400 /tmp/$KEY_FILENAME 
ssh-add /tmp/$KEY_FILENAME
key_pub=$(cat /tmp/$KEY_FILENAME.pub)
curl --data-urlencode "key=$key_pub" --data-urlencode "title=$HOSTNAME" "http://127.0.0.1/api/v4/user/keys?private_token=$TOKEN_STRING"
mkdir -p ~/.ssh 
ssh-keyscan -t rsa $HOSTNAME >> ~/.ssh/known_hosts
cd /tmp/sampleapp 
git config --global user.name "Administrator" 
git config --global user.email "admin@example.com" 
git init --initial-branch=main 
git remote add origin git@$HOSTNAME:root/centralized-pipelines.git 
git add . 
git commit -m "Initial commit" 
git push --set-upstream origin main