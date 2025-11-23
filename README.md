# SOC-as-Code

> **A complete Security Operations Center lab environment built using Infrastructure-as-Code principles. Reproducible, version-controlled, and production-grade.**

│  git clone → make deploy → ☕ 30 minutes → Full SOC Lab     │

## Project Philosophy

**If you can't `git clone` it and rebuild it in one command, it doesn't exist.**

This isn't a collection of manual setup instructions. This is a complete, automated SOC lab that demonstrates:
- **Infrastructure as Code** (Vagrant + VirtualBox)
- **Configuration Management** (Ansible)
- **Version Control** (Git)
- **Enterprise Architecture** (ELK Stack SIEM)
- **Security Operations** (Detection rules + Attack scenarios)

Perfect for learning, demonstrations, and building real SOC engineering skills.

---

## Architecture

### Infrastructure Overview
```
┌──────────────────────────────────────────────────────────────────┐
│                         Host Machine                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐    │
│  │  ELK Server    │  │ Ubuntu Client  │  │ Kali Attacker  │    │
│  │  192.168.56.10 │  │ 192.168.56.20  │  │ 192.168.56.50  │    │
│  │                │  │                │  │                │    │
│  │ • Elasticsearch│  │ • Nginx        │  │ • Hydra        │    │
│  │ • Logstash     │  │ • Suricata     │  │ • Nmap         │    │
│  │ • Kibana       │  │ • Filebeat     │  │ • SQLMap       │    │
│  │                │  │                │  │ • Nikto        │    │
│  │ 6GB RAM        │  │ 2GB RAM        │  │ 2GB RAM        │    │
│  │ 2 CPUs         │  │ 1 CPU          │  │ 2 CPUs         │    │
│  └────────────────┘  └────────────────┘  └────────────────┘    │
│         │                    │                    │              │
│         └────────────────────┴────────────────────┘              │
│              Private Network: 192.168.56.0/24                    │
└──────────────────────────────────────────────────────────────────┘
```

### Component Details

| Component | Purpose | Technology |
|-----------|---------|------------|
| **ELK Server** | SIEM - Collects, stores, and analyzes logs | Elasticsearch 8.11, Logstash, Kibana |
| **Ubuntu Client** | Log source - Generates security events | Nginx, Suricata IDS, Filebeat |
| **Kali Attacker** | Threat simulation - Generates malicious traffic | Hydra, Nmap, SQLMap, Nikto |

### Data Flow
```
Attack Tools (Kali) → Network Traffic → Suricata IDS (Ubuntu) → Logs
                                                                    ↓
Web Traffic → Nginx Access Logs (Ubuntu) ────────────────→ Filebeat
                                                                    ↓
System Events → Syslog (Ubuntu) ───────────────────────→ Filebeat
                                                                    ↓
                                                    Elasticsearch (ELK Server)
                                                                    ↓
                                                    Kibana (Visualization)
```

---

## 🚀 Quick Start

### Prerequisites

**System Requirements:**
- **RAM:** 16GB minimum (10GB allocated to VMs)
- **Disk:** 200GB free space
- **CPU:** 4+ cores recommended
- **OS:** Linux

**Software Requirements:**
```bash
# Arch Linux
sudo pacman -S virtualbox virtualbox-host-modules-arch vagrant ansible git python python-pip

# Ubuntu/Debian
sudo apt update
sudo apt install virtualbox vagrant ansible git python3 python3-pip

# Fedora
sudo dnf install VirtualBox vagrant ansible git python3 python3-pip
```

**Python Dependencies:**
```bash
pip install --user ansible-lint yamllint elasticsearch requests pyyaml jinja2 python-dotenv pandas
```

### One-Command Deployment
```bash
# Clone the repository
git clone https://github.com/g0ods1gnal/socascode.git
cd socascode

# Deploy everything (takes ~30-40 minutes)
make deploy

**What happens during deployment:**
1. 📦 Creates 3 VMs with Vagrant
2. ⏳ Waits for VMs to boot
3. 🔧 Generates SSH and Ansible configuration
4. 🧪 Tests connectivity
5. ⚙️ Installs and configures ELK stack
6. 📊 Sets up log sources and shippers
7. ✅ Verifies deployment

**Grab coffee ☕ - this takes 30-40 minutes on first run.**

---

## 📖 Usage

### Access the Lab

After deployment completes:

**Kibana (Web Interface):**
- URL: http://localhost:5601 or http://192.168.56.10:5601
- Username: `elastic`
- Password: `<YOUR-PASSWORD>`

**Elasticsearch (API):**
```bash
curl -u elastic:ElkL@b2025 http://192.168.56.10:9200
```

### Common Commands
```bash
# Show all available commands
make help
# Check VM status
make status
# SSH into VMs
make ssh-elk        # ELK server
make ssh-client     # Ubuntu client
make ssh-kali       # Kali attacker
# Test connectivity
make test-connectivity
# Take snapshots (save current state)
make snapshot
# Destroy everything
make destroy
# Full rebuild
make rebuild
```

### Manual VM Management
```bash
cd vagrant

# Control individual VMs
vagrant up elk-server
vagrant halt ubuntu-client
vagrant reload kali-attacker

# View logs
vagrant ssh elk-server -c "sudo journalctl -xeu elasticsearch"

# Check resource usage
vagrant ssh elk-server -c "free -h && df -h"
```

---

## 🧪 Testing & Validation

### Verify Deployment
```bash
# Test Elasticsearch
curl -u elastic:ElkL@b2025 http://192.168.56.10:9200
# Should return cluster info JSON

# Test Kibana
curl -I http://192.168.56.10:5601
# Should return HTTP 200

# Check Filebeat is shipping logs
curl -u elastic:ElkL@b2025 http://192.168.56.10:9200/_cat/indices?v
# Should show filebeat-* indices
```

### Generate Test Data
```bash
# SSH into ubuntu-client and generate web traffic
vagrant ssh ubuntu-client
curl http://localhost
for i in {1..100}; do curl -s http://localhost > /dev/null; done
exit

# Check logs appear in Kibana
# Open http://localhost:5601
# Navigate to: Discover → Create data view → filebeat-*
```

---

## 🎯 Use Cases

### 1. SOC Analyst Training
- Practice log analysis
- Build detection rules
- Investigate security incidents
- Learn SIEM operations

### 2. Security Research
- Test detection logic
- Develop custom rules
- Analyze attack patterns
- Experiment with threat hunting

### 3. Development & Testing
- Test security tools
- Develop integrations
- Validate detection rules
- CI/CD for security content

---

## 🐛 Troubleshooting

### VMs Won't Start
```bash
# Check VirtualBox kernel modules
lsmod | grep vbox
sudo modprobe vboxdrv vboxnetadp vboxnetflt

# Verify VirtualBox works
VBoxManage --version
VBoxManage list vms

# Check disk space
df -h
```

### Ansible Can't Connect
```bash
# Regenerate configuration
make config

# Test SSH manually
cd vagrant
vagrant ssh elk-server

# Check SSH keys exist
ls -la vagrant/.vagrant/machines/*/virtualbox/private_key
```

### Elasticsearch Won't Start
```bash
# Check logs
vagrant ssh elk-server
sudo journalctl -xeu elasticsearch.service
sudo tail -100 /var/log/elasticsearch/soc-lab-cluster.log

# Common fixes:
# - Increase heap size in jvm.options.j2
# - Disable swap: sudo swapoff -a
# - Check disk space: df -h
```

### Kibana Won't Start
```bash
# Check logs
vagrant ssh elk-server
sudo journalctl -xeu kibana.service
sudo tail -100 /var/log/kibana/kibana.log

# Verify Elasticsearch is accessible
curl -u elastic:ElkL@b2025 http://localhost:9200
```

### "Not Enough Memory" Errors
```bash
# Reduce VM memory in Vagrantfile:
# elk-server: 6GB → 4GB
# ubuntu-client: 2GB → 1GB

# Then rebuild
make rebuild
```

---

## 📚 Documentation

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Detailed system design
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Step-by-step deployment guide
- **[DETECTION_RULES.md](docs/DETECTION_RULES.md)** - Writing and testing detection rules

---

## 🔐 Security Considerations

**⚠️ This is a LAB environment. NOT for production use.**

Security simplifications made for learning:
- ❌ SSL/TLS disabled on Elasticsearch
- ❌ Default credentials used
- ❌ All services exposed on 0.0.0.0
- ❌ No authentication on Kibana API
- ❌ Weak encryption keys

**For production environments:**
- ✅ Enable SSL/TLS everywhere
- ✅ Use strong, unique passwords
- ✅ Implement proper authentication
- ✅ Use certificate-based auth
- ✅ Enable audit logging
- ✅ Implement network segmentation

---

## 🗺️ Roadmap

**Phase 1: Core Infrastructure** ✅
- [x] VM provisioning with Vagrant
- [x] Configuration with Ansible
- [x] ELK Stack deployment
- [x] Log shipping with Filebeat

**Phase 2: Detection & Response** (In Progress)
- [ ] Custom detection rules
- [ ] Attack scenario automation
- [ ] Incident response playbooks
- [ ] Threat intelligence feeds

**Phase 3: Advanced Features** (Planned)
- [ ] Logstash pipeline configuration
- [ ] Machine learning detections
- [ ] SOAR integration
- [ ] Custom dashboards

**Phase 4: Enterprise Features** (Future)
- [ ] Multi-node Elasticsearch cluster
- [ ] High availability setup
- [ ] Performance tuning
- [ ] Production hardening

---

**Built for learning. Ready for production concepts.**
```
┌─────────────────────────────────────────────────────────────┐
│  "If you can't rebuild it from scratch in 30 minutes,      │
│   you don't really understand it."                          │
└─────────────────────────────────────────────────────────────┘
```
