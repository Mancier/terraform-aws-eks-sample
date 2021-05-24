#! /bin/usr/env bash
set -ex

# ACTION=${1:-"apply"}

do_namespaces() {
    kubectl apply -f namespaces.yaml $*
}

do_knative() {
    kubectl apply -f knative/serving-crds.yaml $*
    kubectl apply -f knative/serving-core.yaml $*
}

do_istio(){
    kubectl apply -f knative/istio/istio.yaml $* || true
    kubectl apply -f knative/istio/net-istio.yaml $* || true
    kubectl apply -f knative/istio/istio.yaml $* 
}

do_databases(){
    kubectl apply -f databases/secrets.yaml $*
    kubectl apply -f databases/mysql.yaml $*
    kubectl apply -f databases/mongo.yaml $*
    kubectl apply -f databases/redis.yaml $*
    kubectl apply -f databases/postgres.yaml $*
}

case $@ in
    namespaces)
        do_namespaces
    ;;
    knative)
        do_knative
    ;;
    istio)
        do_istio
    ;;
    databases|database)
        do_databases
    ;;
    *)
        do_namespaces
        do_knative
        do_istio
        do_databases
    ;;
esac