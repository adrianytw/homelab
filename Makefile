SHELL := /usr/bin/env bash

ANSIBLE_PLAYBOOK ?= uvx --from ansible-core ansible-playbook
ANSIBLE_INVENTORY ?= ansible/inventory/homelab.ini
ANSIBLE_FLAGS ?= -K
STACK ?= all

.PHONY: check inventory inventory-router inventory-nmac backup-routeros backup-opentofu review-routeros ansible-check ansible-storage ansible-k3s

check:
	@scripts/check.sh

inventory: inventory-router inventory-nmac

inventory-router:
	@scripts/inventory-routeros.sh

inventory-nmac:
	@scripts/inventory-nmac.sh

backup-routeros:
	@scripts/backup-routeros.sh

backup-opentofu:
	@scripts/backup-opentofu-state.sh $(STACK)

review-routeros:
	@scripts/review-routeros-backup.sh

ansible-check:
	@$(ANSIBLE_PLAYBOOK) -i $(ANSIBLE_INVENTORY) ansible/playbooks/storage.yml --syntax-check
	@$(ANSIBLE_PLAYBOOK) -i $(ANSIBLE_INVENTORY) ansible/playbooks/k3s.yml --syntax-check

ansible-storage:
	@$(ANSIBLE_PLAYBOOK) -i $(ANSIBLE_INVENTORY) ansible/playbooks/storage.yml $(ANSIBLE_FLAGS)

ansible-k3s:
	@$(ANSIBLE_PLAYBOOK) -i $(ANSIBLE_INVENTORY) ansible/playbooks/k3s.yml $(ANSIBLE_FLAGS)
