#! /bin/usr/env bash
set -ex

ACTION=${1:-"apply"}

do_namespaces() {
    kubectl ${ACTION} -f namespaces.yaml $*
}

do_knative() {
    kubectl ${ACTION} -f knative/serving-crds.yaml $*
    kubectl ${ACTION} -f knative/serving-core.yaml $*
}

do_istio(){
    kubectl ${ACTION} -f knative/istio/istio.yaml $* || true
    kubectl ${ACTION} -f knative/istio/net-istio.yaml $* || true
    kubectl ${ACTION} -f knative/istio/istio.yaml $* 
}

do_databases(){
    kubectl ${ACTION} -f databases/secrets.yaml $*
    kubectl ${ACTION} -f databases/config-map.yaml $*
    kubectl ${ACTION} -f databases/mysql.yaml $*
    kubectl ${ACTION} -f databases/redis.yaml $*
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