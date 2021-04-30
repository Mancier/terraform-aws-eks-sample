#! /bin/usr/env bash

kubectl apply -f namespaces.yaml $*

# Creating knative environment
kubectl apply -f knative/serving-crds.yaml $*
kubectl apply -f knative/serving-core.yaml $*

#Installing Istio
kubectl apply -f knative/istio/pilot.yaml $*
kubectl apply -f knative/istio/control-plane.yaml $*
