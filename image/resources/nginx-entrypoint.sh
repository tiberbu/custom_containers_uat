#!/bin/bash

# Set variables that do not exist
if [[ -z "$BACKEND" ]]; then
  echo "BACKEND defaulting to 0.0.0.0:8000"
  export BACKEND=0.0.0.0:8000
fi
if [[ -z "$SOCKETIO" ]]; then
  echo "SOCKETIO defaulting to 0.0.0.0:9000"
  export SOCKETIO=0.0.0.0:9000
fi
if [[ -z "$UPSTREAM_REAL_IP_ADDRESS" ]]; then
  echo "UPSTREAM_REAL_IP_ADDRESS defaulting to 127.0.0.1"
  export UPSTREAM_REAL_IP_ADDRESS=127.0.0.1
fi
if [[ -z "$UPSTREAM_REAL_IP_HEADER" ]]; then
  echo "UPSTREAM_REAL_IP_HEADER defaulting to X-Forwarded-For"
  export UPSTREAM_REAL_IP_HEADER=X-Forwarded-For
fi
if [[ -z "$UPSTREAM_REAL_IP_RECURSIVE" ]]; then
  echo "UPSTREAM_REAL_IP_RECURSIVE defaulting to off"
  export UPSTREAM_REAL_IP_RECURSIVE=off
fi
if [[ -z "$FRAPPE_SITE_NAME_HEADER" ]]; then
  # shellcheck disable=SC2016
  echo 'FRAPPE_SITE_NAME_HEADER defaulting to $host'
  # shellcheck disable=SC2016
  export FRAPPE_SITE_NAME_HEADER='$host'
fi

if [[ -z "$PROXY_READ_TIMEOUT" ]]; then
  echo "PROXY_READ_TIMEOUT defaulting to 120"
  export PROXY_READ_TIMEOUT=120
fi

if [[ -z "$CLIENT_MAX_BODY_SIZE" ]]; then
  echo "CLIENT_MAX_BODY_SIZE defaulting to 50m"
  export CLIENT_MAX_BODY_SIZE=50m
fi

# shellcheck disable=SC2016
envsubst '${BACKEND}
  ${SOCKETIO}
  ${UPSTREAM_REAL_IP_ADDRESS}
  ${UPSTREAM_REAL_IP_HEADER}
  ${UPSTREAM_REAL_IP_RECURSIVE}
  ${FRAPPE_SITE_NAME_HEADER}
  ${PROXY_READ_TIMEOUT}
	${CLIENT_MAX_BODY_SIZE}' \
  </templates/nginx/frappe.conf.template >/etc/nginx/conf.d/frappe.conf
  
# ---- healthpro_erp assets symlink (sites is a volume) ----
ASSETS_DIR=/home/frappe/frappe-bench/sites/assets/healthpro_erp
SOURCE_DIR=/home/frappe/frappe-bench/apps/healthpro_erp/healthpro_erp/public
NODE_MODULES_DIR=/home/frappe/frappe-bench/apps/healthpro_erp/node_modules

mkdir -p "$ASSETS_DIR"

if [ -d "$SOURCE_DIR" ]; then
    echo "Copying healthpro_erp assets..."
    rm -rf "$ASSETS_DIR"/*
    cp -r "$SOURCE_DIR/"* "$ASSETS_DIR/"
    echo "✓ healthpro_erp assets copied"
else
    echo "⚠️  Source assets not found at $SOURCE_DIR, skipping"
fi

if [ -d "$NODE_MODULES_DIR" ]; then
    echo "Copying healthpro_erp node_modules..."
    rm -rf "$ASSETS_DIR/node_modules"
    cp -r "$NODE_MODULES_DIR" "$ASSETS_DIR/node_modules"
    echo "✓ healthpro_erp node_modules copied"
else
    echo "⚠️  node_modules not found at $NODE_MODULES_DIR, skipping"
fi

# ----------------------------------------------------------

nginx -g 'daemon off;'
