#! /usr/bin/env bash

ACTION=${1:-"apply"}
set -e

if [[ $ACTION =~ /apply/ || $ACTION =~ /destroy/ ]]; then
  echo "Invalid action \n Action should be apply or destroy only"
  exit 1
fi

echo "Creations serving customer resources..."
kubectl ${ACTION} -f serving-crds.yaml 1>/dev/null 2>/dev/stderr

echo "Creating serving core..."
kubectl $ACTION -f serving-core.yaml 1>/dev/null 2>/dev/stderr

echo "Starting istio pilot and control plane"
kubectl $ACTION -f istio/pilot.yaml 1>/dev/null 2>/dev/stderr
kubectl $ACTION -f istio/control-plane.yaml 1>/dev/null 2>/dev/stderr
kubectl $ACTION -f istio/config-domain.yaml 1>/dev/null 2>/dev/stderr

[[ $? ]] && echo "Done!" || echo "Something wrong happend..."