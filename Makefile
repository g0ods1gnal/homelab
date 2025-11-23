.PHONY: help deploy destroy status ssh-elk ssh-client ssh-kali config test-connectivity

.DEFAULT_GOAL := help

help:  ## Show this help message
	@echo "ELK SIEM Lab - DevOps Edition"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

config:  ## Generate SSH configuration from Vagrant
	@echo "🔧 Generating SSH configuration..."
	@cd vagrant && vagrant ssh-config > ../ansible/ssh_config
	@cd scripts/bash && ./generate_inventory.sh
	@echo "✅ Configuration generated"

deploy: config  ## Deploy the entire lab (30-40 minutes)
	@echo "🚀 Deploying ELK SIEM Lab..."
	@echo "☕ Grab coffee - this takes ~30 minutes"
	@cd vagrant && vagrant up
	@echo "⏳ Waiting for VMs to initialize..."
	@sleep 30
	@echo "🧪 Testing connectivity..."
	@cd ansible && ansible all -m ping
	@echo "🔧 Deploying ELK stack with Ansible..."
	@cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/site.yml
	@echo ""
	@echo "🎉 Deployment complete!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📊 Kibana:      http://192.168.56.10:5601"
	@echo "🔍 Elasticsearch: http://192.168.56.10:9200"
	@echo "👤 Username:    elastic"
	@echo "🔑 Password:    ElkL@b2025"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

status:  ## Show VM status
	@cd vagrant && vagrant status

ssh-elk:  ## SSH into ELK server
	@cd vagrant && vagrant ssh elk-server

ssh-client:  ## SSH into Ubuntu client
	@cd vagrant && vagrant ssh ubuntu-client

ssh-kali:  ## SSH into Kali attacker
	@cd vagrant && vagrant ssh kali-attacker

test-connectivity:  ## Test Ansible can reach all VMs
	@cd ansible && ansible all -m ping

destroy:  ## Destroy all VMs
	@echo "💣 Destroying all VMs..."
	@cd vagrant && vagrant destroy -f
	@rm -f ansible/ssh_config
	@echo "✅ All VMs destroyed"

rebuild: destroy deploy  ## Full rebuild (destroy + deploy)

snapshot:  ## Take snapshot of current state
	@echo "📸 Taking snapshots..."
	@cd vagrant && vagrant snapshot save elk-server elk-snapshot-$$(date +%Y%m%d-%H%M%S)
	@cd vagrant && vagrant snapshot save ubuntu-client client-snapshot-$$(date +%Y%m%d-%H%M%S)
	@cd vagrant && vagrant snapshot save kali-attacker kali-snapshot-$$(date +%Y%m%d-%H%M%S)
	@echo "✅ Snapshots saved"
