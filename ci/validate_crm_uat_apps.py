"""Validate the credential-free app list before a CRM UAT image build."""

import base64
import binascii
import json
import os
import sys
from pathlib import Path

EXPECTED = [
    ("https://github.com/frappe/erpnext", "version-15"),
    ("https://github.com/frappe/payments", "version-15"),
    ("https://github.com/frappe/hrms", "version-15"),
    ("https://github.com/tiberbu/crm.git", "develop"),
    ("https://github.com/tiberbu/openmeter_mediator.git", "feat/hmis-essentials-postman"),
]


def validate(apps: object) -> bool:
    if not isinstance(apps, list) or len(apps) != len(EXPECTED):
        print("CRM UAT app list must contain exactly five apps", file=sys.stderr)
        return False

    for index, (app, expected) in enumerate(zip(apps, EXPECTED, strict=True), start=1):
        if (
            not isinstance(app, dict)
            or set(app) != {"url", "branch"}
            or (app["url"], app["branch"]) != expected
        ):
            print(f"Invalid CRM UAT app entry {index}", file=sys.stderr)
            return False

    return True


def main() -> int:
    prepare = len(sys.argv) == 3 and sys.argv[1] == "--from-env"
    if not prepare and len(sys.argv) != 2:
        print("Usage: validate_crm_uat_apps.py [--from-env] <apps.json>", file=sys.stderr)
        return 2

    try:
        if prepare:
            payload = base64.b64decode(os.environ["APPS_JSON_BASE64"], validate=True)
            apps = json.loads(payload)
        else:
            apps = json.loads(Path(sys.argv[1]).read_text())
    except (KeyError, OSError, ValueError, UnicodeDecodeError, binascii.Error):
        print("Invalid CRM UAT app list", file=sys.stderr)
        return 1

    if not validate(apps):
        return 1

    if prepare:
        output = Path(sys.argv[2])
        with os.fdopen(os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "w") as file:
            json.dump(apps, file)

    print("CRM UAT app list validated: five credential-free apps in order")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
