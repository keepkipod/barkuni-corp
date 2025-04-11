replicaCount: 1

serviceAccount:
  create: true
  name: external-dns
  annotations:
    eks.amazonaws.com/role-arn: "${irsa_role_arn}"

provider: aws
txtOwnerId: "my-identifier"
source: service
policy: sync
registry: txt
interval: 1m
