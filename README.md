# Letsencrypt automation

## Java keystores

You have to set up SSH access to all infra hosts with appropriate private keys first.

To update/deploy JKS run

    cd jks
    ./deploy-all jkstab


## Rancher certs

You'll need ~/.envtab and ~/.netrc properly set up for it to work.

To renew certs in rancher infrastructure run

    sh certbot-renew.sh

To deploy a certificate to all rancher servers and environments in ~/.envtab run

    cd rancher
    ./deploy-to-all.sh ... 

To manage a certificate manually to one of the servers defined in ~/.envtab run

    cd rancher
    ./deploy.sh ...

Both deploy.sh and deploy-to-all.sh will document usage when started with no arguments.

