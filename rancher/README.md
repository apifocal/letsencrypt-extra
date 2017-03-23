# Letsencrypt - Rancher automation

## Configuration

Most of the requirements for these scripts are checked on first run, and messages are presented to guide you.

Essentially, all you need is an environment table at `~/.envtab` following the guidelines in ]envtab.sample](envtab.sample) in this repo. Depending on your preference, keep the API keys in `~/.envtab` or in `~/.netrc`.

## Basic usage

First, seed the rancher environments by using the deploy.sh script:

    ./deploy.sh add <cert> <environment>

Next maintain these certs automatically using `./deploy.sh update` or `certbot-renew-hook.sh` when renewing them:

     ./cerbot-auto renew [--cert-name=NAME] --renew-hook=/path/to/certbot-renew-hook.sh

This hook will update renewed certificates on all environments in envtab, only if the certifacte was first deployed on that environment.