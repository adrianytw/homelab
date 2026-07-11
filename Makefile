SHELL := /usr/bin/env bash

ANSIBLE_PLAYBOOK ?= uvx --from ansible-core ansible-playbook
ANSIBLE_INVENTORY ?= ansible/inventory/homelab.ini
ANSIBLE_FLAGS ?= -K

.PHONY: check inventory inventory-router inventory-nmac backup-routeros review-routeros ansible-check ansible-storage

check:
	@scripts/check.sh

inventory: inventory-router inventory-nmac

inventory-router:
	@scripts/inventory-routeros.sh

inventory-nmac:
	@scripts/inventory-nmac.sh

backup-routeros:
	@scripts/backup-routeros.sh

review-routeros:
	@scripts/review-routeros-backup.sh

ansible-check:
	@$(ANSIBLE_PLAYBOOK) -i $(ANSIBLE_INVENTORY) ansible/playbooks/storage.yml --syntax-check

ansible-storage:
	@$(ANSIBLE_PLAYBOOK) -i $(ANSIBLE_INVENTORY) ansible/playbooks/storage.yml $(ANSIBLE_FLAGS)
