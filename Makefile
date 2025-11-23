.PHONY: help deploy destroy status ssh-elk ssh-client ssh-kali config test-connectivity deploy-rules attack lint clean

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo " SOC Lab"
	@echo " Everything as Code. Everything in Git. Everything Reproducible."
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

config: ## Generate SSH and Ansible configuration
	@echo "🔧 Generating SSH configuration from Vagrant..."
	@cd vagrant && vagrant ssh-config > ../ansible/ssh_config
	@echo "📝 Generating Ansible inventory..."
	@cd scripts/bash && ./generate_inventory.sh
	@echo "✅ Configuration generated successfully"

deploy: config ## Deploy the entire lab (takes ~30-40 minutes)
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🚀 Deploying SOC Lab"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "This will:"
	@echo " 1. Create 3 VMs (ELK server, Ubuntu client, Kali attacker)"
	@echo " 2. Install and configure ELK stack"
	@echo " 3. Setup log sources (Nginx, Suricata)"
	@echo " 4. Deploy detection rules"
	@echo ""
	@echo "☕ Grab coffee - this takes ~30-40 minutes"
	@echo ""
	@cd vagrant && vagrant up
	@echo ""
	@echo "⏳ Waiting for VMs to fully boot (30 seconds)..."
	@sleep 30
	@echo ""
	@echo "🧪 Testing connectivity..."
	@cd ansible && ansible all -m ping
	@echo ""
	@echo "🔧 Deploying ELK stack with Ansible (this is the slow part)..."
	@cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/site.yml
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🎉 Deployment Complete!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Access your lab:"
	@echo " 📊 Kibana: http://192.168.56.10:5601"
	@echo " http://localhost:5601 (if port forwarded)"
	@echo " 🔍 Elasticsearch: http://192.168.56.10:9200"
	@echo ""
	@echo "Credentials:"
	@echo " 👤 Username: elastic"
	@echo " 🔑 Password: ElkL@b2025"
	@echo ""
	@echo "Next steps:"
	@echo " - make deploy-rules # Deploy detection rules"
	@echo " - make attack # Run attack scenarios"
	@echo " - make ssh-elk # SSH into ELK server"
	@echo ""

status: ## Show VM status
	@cd vagrant && vagrant status

ssh-elk: ## SSH into ELK server
	@cd vagrant && vagrant ssh elk-server

ssh-client: ## SSH into Ubuntu client
	@cd vagrant && vagrant ssh ubuntu-client

ssh-kali: ## SSH into Kali attacker
	@cd vagrant && vagrant ssh kali-attacker

test-connectivity: ## Test Ansible connectivity to all VMs
	@echo "🧪 Testing Ansible connectivity..."
	@cd ansible && ansible all -m ping

deploy-rules: ## Deploy detection rules to Kibana
	@echo "📋 Deploying detection rules to Kibana..."
	@cd detection-rules && python3 deploy_rules.py
	@echo "✅ Detection rules deployed"

attack: ## Run attack scenarios
	@echo "💀 Launching attack scenarios..."
	@cd attack-playbooks && python3 run_scenario.py --scenario all
	@echo "✅ Attack scenarios complete"

destroy: ## Destroy all VMs
	@echo "💣 Destroying all VMs..."
	@cd vagrant && vagrant destroy -f
	@rm -f ansible/ssh_config
	@echo "✅ All VMs destroyed"

rebuild: destroy deploy ## Full rebuild (destroy + deploy)

snapshot: ## Take snapshot of all VMs
	@echo "📸 Taking snapshots of all VMs..."
	@cd vagrant && vagrant snapshot save elk-server manual-$$(date +%Y%m%d-%H%M%S)
	@cd vagrant && vagrant snapshot save ubuntu-client manual-$$(date +%Y%m%d-%H%M%S)
	@cd vagrant && vagrant snapshot save kali-attacker manual-$$(date +%Y%m%d-%H%M%S)
	@echo "✅ Snapshots saved"

lint: ## Lint all code (Ansible, YAML, Python)
	@echo "🔍 Linting Ansible playbooks..."
	@ansible-lint ansible/playbooks/*.yml || true
	@echo ""
	@echo "🔍 Linting YAML files..."
	@yamllint ansible/ detection-rules/ || true
	@echo ""
	@echo "🔍 Linting Python scripts..."
	@cd scripts/python && pylint *.py || true

clean: destroy ## Clean everything (VMs, caches, generated files)
	@echo "🧹 Cleaning up..."
	@cd vagrant && rm -rf .vagrant/
	@rm -f ansible/ssh_config
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✅ Cleaned"
