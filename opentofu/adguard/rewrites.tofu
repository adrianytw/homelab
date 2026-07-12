resource "adguard_rewrite" "test_k8s" {
  domain  = "test.k8s.nairdev.com"
  answer  = "192.168.88.20"
  enabled = true
}

resource "adguard_rewrite" "adguard" {
  domain  = "adguard.nairdev.com"
  answer  = "192.168.88.1"
  enabled = true
}

resource "adguard_rewrite" "router" {
  domain  = "router.nairdev.com"
  answer  = "192.168.88.1"
  enabled = true
}

resource "adguard_rewrite" "glance" {
  domain  = "home.nairdev.com"
  answer  = "192.168.88.20"
  enabled = true
}

resource "adguard_rewrite" "uptime_kuma" {
  domain  = "status.nairdev.com"
  answer  = "192.168.88.20"
  enabled = true
}

resource "adguard_rewrite" "ntfy" {
  domain  = "notify.nairdev.com"
  answer  = "192.168.88.20"
  enabled = true
}

resource "adguard_rewrite" "healthchecks" {
  domain  = "health.ops.nairdev.com"
  answer  = "192.168.88.20"
  enabled = true
}

resource "adguard_rewrite" "prometheus" {
  domain  = "prom.ops.nairdev.com"
  answer  = "192.168.88.20"
  enabled = true
}

resource "adguard_rewrite" "grafana" {
  domain  = "grafana.nairdev.com"
  answer  = "192.168.88.20"
  enabled = true
}
