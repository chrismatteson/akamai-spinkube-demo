# SpinKube on Linode Gecko using K3d
This code spins up one or more clusers of K3d on Linode instances and then installs SpinKube. To use this code simply run:

`
terraform init
terraform apply -auto-approve
`

By passing in a -variable `edge_regions`, the regions where a cluster is created can be alternted. The kubeconfigs for each cluster will be placed in this folder.

Once these steps are complete, you can now deploy spin apps to the cluster. A quick test is here:

`
kubectl apply -f https://raw.githubusercontent.com/spinkube/spin-operator/main/config/samples/simple.yaml
kubectl port-forward svc/simple-spinapp 8083:80
`

In a new window:
`
curl localhost:8083/hello
`