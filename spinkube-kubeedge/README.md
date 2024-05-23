# SpinKube on KubeEdge with Linode
This example deploys SpinKube and KubeEdge to an LKE cluster and then adds in additional KubeEdge nodes in other regions. Due to a limitation of Terraform providers having dependencies on other resources, the code is split into 3 steps. To run the code take the following steps:

`
cd step1
terraform init
terraform apply -auto-approve
terraform output kubeconfig > /tmp/kubeconfig
export KUBECONFIG=/tmp/kubeconfig
`
The next step requires some time for LKE to deploy a node and for it's ip to come online, so if you run it immediately after step1 finishes and it fails, wait 10 seconds and try again.
`
cd ../step2
terraform init
terraform apply -auto-approve
cd ../step3
terraform init
terraform apply -auto-approve
`

Once these steps are complete, you can now deploy spin apps to the cluster. A quick test is here:

`
kubectl apply -f https://raw.githubusercontent.com/spinkube/spin-operator/main/config/samples/simple.yaml
kubectl port-forward svc/simple-spinapp 8083:80
`

In a new window:
`
curl localhost:8083/hello
`