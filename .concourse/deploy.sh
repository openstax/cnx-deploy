#!/bin/bash

set -e

# place ssh private key
mkdir $HOME/.ssh
cat >$HOME/.ssh/id_rsa <<EOF
$SSH_PRIVATE_KEY
EOF
chmod 600 $HOME/.ssh/id_rsa

set -x

# add QA as known host
ssh -o StrictHostKeyChecking=no -T rundeck@qa.cnx.org || echo 'Added github as known host'

cd cnx-deploy
pip install ansible
ansible-playbook -i "environments/${ENVIRONMENT}/inventory main.yml" -vvv
