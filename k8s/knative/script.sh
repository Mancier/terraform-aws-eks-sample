#! /usr/bin/env bash

ACTION=${1:-"apply"}
set -e

if [[ ! $ACTION =~ /apply|destroy/ ]]; then
  echo "Invalid action \n Action should be apply or destroy only"
  exit 1
fi

echo "Creations serving customer resources..."
kubectl apply --file serving-crds.yaml

echo "Creating serving core..."
kubectl apply --file serving-core.yaml

echo "Starting istio pilot and control plane"
kubectl apply --file istio/pilot.yaml
kubectl apply --file istio/control-plane.yaml

[[ $? ]] && echo "Done!" || echo "Something wrong happend..."