#!/usr/bin/env bash
# Script for zero-downtime rolling update deployment of Phoenix web1 and web2 nodes
set -euo pipefail

COMPOSE="docker compose --env-file prod/.env.prod -f prod/docker-compose.prod.yml"

# Global error handler to catch unexpected script failures
on_error() {
  local exit_code=$?
  local line_number=$1
  echo "============================================================"
  echo "❌ DEPLOYMENT FAILED at line ${line_number} with exit code ${exit_code}!"
  echo "============================================================"
  echo "[DEBUG] Printing recent logs from web1 and web2 containers for troubleshooting:"
  $COMPOSE logs --tail 30 web1 web2 || true
  echo "============================================================"
  exit ${exit_code}
}

trap 'on_error ${LINENO}' ERR

echo "============================================================"
echo "🚀 Starting Zero-Downtime Deployment"
echo "============================================================"

echo "===> Step 1/5: Building latest Docker images..."
if ! $COMPOSE build; then
  echo "❌ FAILED: Docker image build failed. Check Dockerfile and dependencies."
  exit 1
fi

echo "===> Step 2/5: Running database migrations (one-time task)..."
if ! $COMPOSE run --rm web1 /app/bin/migrate; then
  echo "❌ FAILED: Database migration failed. Check migration files and Ecto logs."
  exit 1
fi

wait_for_healthy() {
  local service=$1
  echo "===> Waiting for service '${service}' to become healthy..."
  
  local max_attempts=30
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    # Get the container ID directly from docker compose
    local container_id
    container_id=$($COMPOSE ps -q "${service}" 2>/dev/null || echo "")
    
    local status="starting"
    if [ -n "${container_id}" ]; then
      # Safely query Docker daemon directly for the exact health status
      status=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' "${container_id}" 2>/dev/null || echo "starting")
    fi
    
    if [ "$status" = "healthy" ]; then
      echo "✅ SUCCESS: Service '${service}' is HEALTHY and ready to serve traffic!"
      return 0
    fi
    
    if [ "$status" = "unhealthy" ]; then
      echo "❌ FAILED: Service '${service}' reported UNHEALTHY status by healthcheck!"
      echo "[DEBUG] Detailed health logs for '${service}':"
      $COMPOSE logs --tail 50 "${service}"
      exit 1
    fi
    
    echo "  [${attempt}/${max_attempts}] Current status of '${service}': '${status}'. Retrying in 2s..."
    sleep 2
    attempt=$((attempt + 1))
  done

  echo "❌ FAILED: Service '${service}' timed out waiting for healthy status (${max_attempts} attempts)."
  echo "[DEBUG] Printing last 50 lines of container logs for '${service}':"
  $COMPOSE logs --tail 50 "${service}"
  exit 1
}

echo "===> Step 3/5: Deploying and updating web1..."
$COMPOSE up -d --no-deps web1
wait_for_healthy web1

echo "===> Step 4/5: Deploying and updating web2..."
$COMPOSE up -d --no-deps web2
wait_for_healthy web2

echo "===> Step 5/5: Ensuring Nginx is running and reloading configuration..."
local_nginx_cid=$($COMPOSE ps -q nginx 2>/dev/null || echo "")
local_nginx_status=""
if [ -n "${local_nginx_cid}" ]; then
  local_nginx_status=$(docker inspect --format='{{.State.Status}}' "${local_nginx_cid}" 2>/dev/null || echo "")
fi

if [ "${local_nginx_status}" = "running" ]; then
  echo "===> Reloading Nginx configuration..."
  $COMPOSE exec nginx nginx -s reload
else
  echo "===> Nginx is not running. Starting Nginx..."
  $COMPOSE up -d nginx
fi

echo "============================================================"
echo "🎉 Zero-Downtime Deployment Successfully Completed!"
echo "============================================================"
