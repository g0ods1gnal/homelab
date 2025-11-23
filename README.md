# homelab

Infrastructure-as-Code SIEM lab for learning SOC engineering and DevOps practices.

## Quick Start 
`bash git clone`
`cd homelab`
`make deploy` # Grab coffee ☕

## Philosophy
Everything is code. Everything is in Git. Everything is reproducible.

If you can't `git clone` and `make deploy`, it doesn't exist.

## What You Get
- Full ELK Stack (Elasticsearch, Logstash, Kibana)
- Multi-VM environment (Ubuntu client, Kali attacker)
- Detection rules as code (YAML)
- Attack scenarios as code (YAML)
- Python automation (alert enrichment, reporting)
- CI/CD ready (lint, test, deploy)
  
## Commands
See `make help` for all available commands.

Most common:
- `make deploy` - Deploy everything
- `make status` - Check VM status
- `make destroy` - Burn it all down
- `make ssh-elk` - SSH into ELK server

## Documentation
See [docs/](docs/) for detailed guides.
