# Spinkube on LKE
This Terraform code will spin up an LKE cluster on Linode and install SpinKube. Due to an issue with Terraform providers depending on resources, the code is broken into two steps. To utilize this code do the following:

`
cd step1
terraform init
terraform apply -auto-approve
terraform output kubeconfig > /tmp/kubeconfig
chmod 700 /tmp/kubeconfig
export KUBECONFIG=/tmp/kubeconfig
cd ../step2
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