.PHONY: help deploy destroy attack status backup reset

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

deploy: ## Deploy the entire lab
	@echo "[---] Deploying ELK SIEM Lab..."
	cd vagrant && vagrant up
	@echo "[---] Waiting for VMs to be ready..."
	sleep 30
	cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/site.yml
	@echo "[!!!] Lab deployed! Access Kibana at http://192.168.56.10:5601"

status: ## Check status of all VMs
	cd vagrant && vagrant status

ssh-elk: ## SSH into ELK server
	cd vagrant && vagrant ssh elk-server

ssh-client: ## SSH into Ubuntu client
	cd vagrant && vagrant ssh ubuntu-client

ssh-kali: ## SSH into Kali attacker
	cd vagrant && vagrant ssh kali-attacker

attack: ## Run attack scenarios
	@echo "[+++] Launching attack scenarios..."
	python3 attack-playbooks/run_scenario.py --scenario all

deploy-rules: ## Deploy detection rules to Kibana
	@echo "[+++] Deploying detection rules..."
	python3 detection-rules/deploy_rules.py

backup: ## Backup Elasticsearch data
	@echo "[+++] Backing up Elasticsearch..."
	bash scripts/bash/backup.sh

reset: ## Reset lab to clean state
	@echo "[!!!] Resetting lab..."
	cd vagrant && vagrant snapshot restore clean-slate

destroy: ## Destroy all VMs
	@echo "[!!!] Destroying all VMs..."
	cd vagrant && vagrant destroy -f

lint: ## Lint Ansible playbooks and YAML
	@echo "[---] Linting..."
	ansible-lint ansible/playbooks/*.yml
	yamllint ansible/
	yamllint detection-rules/

test: ## Run tests
	@echo "[+++] Running tests..."
	cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/site.yml --syntax-check

