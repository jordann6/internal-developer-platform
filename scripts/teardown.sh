#!/usr/bin/env bash
set -euo pipefail

echo "=== Tearing down all IDP infrastructure ==="
echo "This will destroy ALL resources. Press Ctrl+C to cancel."
echo ""
sleep 5

cd "$(dirname "${BASH_SOURCE[0]}")/../terraform/environments/dev"
terraform destroy -auto-approve

echo ""
echo "=== Teardown Complete ==="
echo "All resources destroyed."
