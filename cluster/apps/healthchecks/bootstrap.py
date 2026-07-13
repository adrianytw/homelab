import base64
import json
import os
import re
from datetime import timedelta

from django.contrib.auth.models import User
from django.db import transaction
from hc.accounts.models import Profile, Project
from hc.api.models import Channel, Check


def required(name):
    value = os.environ.get(name, "")
    if not value:
        raise RuntimeError(f"missing required environment variable: {name}")
    return value


username = required("HC_ADMIN_USERNAME")
email = required("HC_ADMIN_EMAIL").lower()
password = required("HC_ADMIN_PASSWORD")
ping_key = required("HC_PING_KEY")
ntfy_username = required("NTFY_USERNAME")
ntfy_password = required("NTFY_PASSWORD")

if not re.fullmatch(r"[a-z0-9]{22}", ping_key):
    raise RuntimeError("HC_PING_KEY must contain exactly 22 lowercase letters or digits")

checks = (
    (
        "k3s app backups",
        "k3s-app-backups",
        "15 3 * * *",
        60,
        True,
        "Daily backup of persistent k3s application data.",
    ),
    (
        "AdGuard config backup",
        "adguard-config-backup",
        "45 3 * * *",
        60,
        True,
        "Daily encrypted configuration backup from the RouterOS container.",
    ),
    (
        "RouterOS backup",
        "routeros-backup",
        "15 4 * * 0",
        60,
        True,
        "Weekly RouterOS pack with nested age-encrypted random binary password.",
    ),
    (
        "Home Assistant backup freshness",
        "ha-backup-freshness",
        "0 5 * * *",
        120,
        True,
        "Daily verification that a recent Home Assistant backup exists.",
    ),
)

with transaction.atomic():
    by_email = User.objects.filter(email__iexact=email).first()
    by_username = User.objects.filter(username=username).first()
    if by_email and by_username and by_email.pk != by_username.pk:
        raise RuntimeError("admin email and username belong to different accounts")

    user = by_email or by_username or User(username=username, email=email)
    user.username = username
    user.email = email
    user.is_active = True
    user.is_staff = True
    user.is_superuser = True
    if not user.check_password(password):
        user.set_password(password)
    user.save()
    Profile.objects.for_user(user)

    project = Project.objects.filter(owner=user, name="Homelab").first()
    if project is None:
        unnamed = list(Project.objects.filter(owner=user, name="")[:2])
        project = unnamed[0] if len(unnamed) == 1 else Project(owner=user)
    if not project.badge_key:
        project.badge_key = str(project.code)
    project.name = "Homelab"
    project.ping_key = ping_key
    project.show_slugs = True
    project.save()

    managed = []
    paused_changed = False
    for name, slug, schedule, grace_minutes, active, description in checks:
        check = Check.objects.filter(project=project, slug=slug).order_by("id").first()
        created = check is None
        if created:
            check = Check(project=project, slug=slug)

        check.name = name
        check.kind = "cron"
        check.schedule = schedule
        check.tz = "America/Chicago"
        check.grace = timedelta(minutes=grace_minutes)
        check.tags = "backup homelab"
        check.desc = description

        if created:
            check.status = "new" if active else "paused"
        elif active and check.status == "paused":
            check.create_flip("new", mark_as_processed=True)
            check.status = "new"
            check.last_start = None
            check.last_ping = None
            check.alert_after = None
        elif not active and check.status != "paused":
            check.create_flip("paused", mark_as_processed=True)
            check.status = "paused"
            check.last_start = None
            check.alert_after = None
            paused_changed = True

        if active and check.status != "paused":
            check.alert_after = check.going_down_after()
        check.save()
        managed.append(check)

    if paused_changed:
        project.update_next_nag_dates()

    auth = base64.b64encode(f"{ntfy_username}:{ntfy_password}".encode()).decode()
    url = "http://ntfy.core.svc.cluster.local/homelab-alerts"
    value = json.dumps(
        {
            "body_down": "Healthchecks reports $NAME is DOWN ($SLUG).",
            "body_up": "Healthchecks reports $NAME has recovered ($SLUG).",
            "headers_down": {
                "Authorization": f"Basic {auth}",
                "Priority": "high",
                "Tags": "rotating_light",
                "Title": "Healthchecks: $NAME DOWN",
            },
            "headers_up": {
                "Authorization": f"Basic {auth}",
                "Priority": "default",
                "Tags": "white_check_mark",
                "Title": "Healthchecks: $NAME recovered",
            },
            "method_down": "POST",
            "method_up": "POST",
            "url_down": url,
            "url_up": url,
        },
        sort_keys=True,
    )
    channel = (
        Channel.objects.filter(
            project=project, kind="webhook", name="ntfy homelab-alerts"
        )
        .order_by("id")
        .first()
    )
    if channel is None:
        channel = Channel(project=project, kind="webhook")
    channel.name = "ntfy homelab-alerts"
    channel.value = value
    channel.disabled = False
    channel.save()
    channel.checks.set(managed)

    extras = list(Project.objects.filter(owner=user).exclude(pk=project.pk)[:2])
    if (
        len(extras) == 1
        and not Check.objects.filter(project=extras[0]).exists()
        and not Channel.objects.filter(project=extras[0]).exists()
    ):
        extras[0].delete()
