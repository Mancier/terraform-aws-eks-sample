# Desenvolvimento e implementação de um sistema Function-as-a-Service usando Knative

| Data | Autor | Versao | 
| :---: | :---: | ---: |
| 24/05/21 | Victor Augusto | v1.0.0 |
---

## Introdução
Esse projeto consiste no desenvolvimento e implementação de cluster Kubernetes e Knative para provisionamento de uma infraestrutura serveless.
Um dos principais problemas do serveless é a ideia do vendo lock-in, ou seja, você fica preso ao provider que lhe oferece o serviço serverless. E como uma alternativa a isso tem-se o knative, que permite usufruir de todos os beneficios de uma aplicação serverless, sem correr o risco do vendor lock.

## Projeto
O projeto foi desenvolvido em conjunto com a Unisagrado e a Ikatec e orientado pelo Me. Henrique Martins.

## Hands On
` export KUBECONFIG=~/.kube/knative-project` 

```bash
# Hello Workload
kubectl apply --filename ./k8s/test/helloworld.yaml
```

```bash 
# Deploy usando knative
kn service create front --namespace development --image=mancier21/hello-world-react

kn service create front --namespace production --image=mancier21/hello-world-react
```

