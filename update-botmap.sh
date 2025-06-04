#!/bin/sh
set -eu

# nginx bot map updater script
# version 0.7
# 2025-06 tony@
#
# This script syncs the global bot-mapping.conf from Paper Leaf's github
# if changes are detected
# -- it will copy them over to the appropriate directory
# -- runs the nginx configuration checker
# -- if all looks good
#	-- reload the nginx
#	-- otherwise go back to the previous working copy
#

echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="

# https://github.com/paper-leaf-tech/nginx/tree/main
#
ORIGIN="https://raw.githubusercontent.com/paper-leaf-tech/nginx/refs/heads/main/bot-mapping.conf"

TEMP="/root/paperleaf/bot-mapping.conf"
TARGET="/etc/nginx/conf.d/bot-mapping.conf"

WORKING="/etc/nginx/conf.d/bot-mapping.conf.working"

# Step 1: download latest version
if ! curl -fsSL "$ORIGIN" -o "$TEMP"; then
	echo "❌ failed to fetch updated config"
	exit 1
fi

# Step 2: update the target if we have an updated copy
if ! cmp -s "$TEMP" "$TARGET"; then
	echo "🔄 changes detected, applying update..."

	cp "$TEMP" "$TARGET";

	# check for the syntax
	if nginx -t; then
		echo "✅ config test OK, reloading NGINX..."
		service nginx reload; # systemctl reload nginx

		# only promote to working if NGINX is healthy
		cp "$TARGET" "$WORKING"
	else
		echo "❌ config test failed, rolling back to previous known copy..."
		cp "$WORKING" "$TARGET"
		exit 1
	fi
else
	echo "✅ no changes detected."
fi
