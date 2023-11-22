# kubeadm cloud init file for ubuntu 20.04 #

This repository contains a cloud init file that can be used to prepare for the LFS258 exam.
Additionally there are some terraform files to test installing kubernetes with kubeadm on hetzner.
Below are some very coarse instructions but if you are following the LFS258 (Certified Kubernetes Administrator CKA) course it will make sense.

## Running the scripts in this repository ##
To test this script you can deploy a VM with any cloud provider that supports cloud-init. You can do this manually or you can test this setup with hetzner cloud using the terraform files in this repository.

To setup a Hetzner account sign up [here](https://hetzner.cloud/?ref=h5eQUyhOof7b) (this is an affiliate link).
Once you have an account you'll need to [create an API key](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/)
Provide the API key to terraform when requested or create an [.tfvars file](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files).

use `terraform plan` in the root of this repository to view the terraform plan or `terraform apply` to apply the terraform plan.

The terraform will deploy two servers:
- cp (k8scp)
- worker (worker)

If you want to manually use the cloud init file you'll need to deploy two servers with these host names as well.

Once you have the two servers deployed follow these two steps to install Kubernetes. The instructions purposely install an older version of Kubernetes so that you can test the upgrade process as part of the course instructions.

## Configure kubernetes master ##

Wait for the command `cloud-init status --wait` to ensure cloud init is finished. 

1. On server `k8scp` execute: 
```
wget https://docs.projectcalico.org/manifests/calico.yaml
```

2. edit /etc/hosts add alias for master node with the name k8scp and worker node using the public ip's of both so that you have something like this:
```
87.55.x.1 k8scp
87.55.x.1 worker
```
3. Create a kubeadm config file in your user directory: `nano kubeadm-config.yaml`:
```
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.28.1
controlPlaneEndpoint: "k8scp:6443"
networking:
  podSubnet: 192.168.0.0/16
```
4. Execute kubeadm to install kubernetes `kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out`
5. copy commands to copy kube.config file from kubeadm output to student user
6. Execute `su student` commands below are executed as student.
7. `sudo cp /root/calico.yaml .`
8. `kubectl apply -f calico.yaml`
9. `source <(kubectl completion bash)`
10. `echo "source <(kubectl completion bash)" >> $HOME/.bashrc`
11. enable alias
```
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
```

## configure kubernetes worker ##

1. edit /etc/hosts add alias for master node with the name k8scp and worker node using the public ip's of both so that you have something like this:
```
87.55.x.1 k8scp
87.55.x.1 worker
```
2. on server `k8scp` execute: `sudo kubeadm token create` to create an token.
3. create validation hash for worker node to join:
```
openssl x509 -pubkey \
-in /etc/kubernetes/pki/ca.crt | openssl rsa \
-pubin -outform der 2>/dev/null | openssl dgst \
-sha256 -hex | sed 's/ˆ.* //'
```
4. Replace the join token and the validation hash in the command below
```
kubeadm join \
--token yqlt6r.nsdmqmpc3hujwa4k \
k8scp:6443 \
--discovery-token-ca-cert-hash \
sha256:692d65316d198a1901a5523d790ca7509aeaa494c600bcca366f20c62568e198
```
5. Execute above command on the `worker` node. 

## testing cloud init scripts ##
If you want to test the cloud init scripts without recreating an vm in the cloud you can use below instructions.

Install lxd: `sudo snap install lxd` 

Initialize lxd: `lxd init --minimal`

launch a host: `lxc launch ubuntu:jammy my-test -c linux.kernel_modules=overlay -c linux.kernel_modules=br_netfilter -c=user.user-data="$(cat cloudinit.yaml)"`

SSH to the node: `lxc shell my-test`
Verify: `cloud-init status --wait`
Cleanup: `lxc stop my-test` and `lxc rm my-test`


**Source: https://cloudinit.readthedocs.io/en/latest/topics/tutorial.html**
