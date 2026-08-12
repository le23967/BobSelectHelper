#!/bin/bash
set -euo pipefail
BUNDLE_ID="com.bryannelson.BobSelectHelper"
tccutil reset Accessibility "$BUNDLE_ID" || true
tccutil reset AppleEvents "$BUNDLE_ID" || true
echo "Privacy permissions reset for $BUNDLE_ID"
