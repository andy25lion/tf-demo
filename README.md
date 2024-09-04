# tf-demo

## Building and starting the terraform environment
```
docker build -t tf-demo .
docker run --rm -it -v $(pwd)/.vscode-server:/root/.vscode-server -v $(pwd)/:/tf-demo --name tf-demo tf-demo bash
```

## Example .tfvars file
For privacy reasons the Azure credentials will be loaded as TF_VAR_ environment variables in the demo

```
vm_count    = 3
AZURE_TENANT_ID         = <PLACEHOLDER>
AZURE_CLIENT_ID         = <PLACEHOLDER>
AZURE_CLIENT_SECRET     = <PLACEHOLDER>
AZURE_SUBSCRIPTION_ID   = <PLACEHOLDER>
```

## Expected output
```
Outputs:

ping_results = {
  "vm_0_to_vm1" = <<-EOT
  PING 10.0.2.6 (10.0.2.6) 56(84) bytes of data.
  64 bytes from 10.0.2.6: icmp_seq=1 ttl=64 time=1.08 ms
  64 bytes from 10.0.2.6: icmp_seq=2 ttl=64 time=1.38 ms
  64 bytes from 10.0.2.6: icmp_seq=3 ttl=64 time=1.15 ms
  64 bytes from 10.0.2.6: icmp_seq=4 ttl=64 time=1.26 ms
  
  --- 10.0.2.6 ping statistics ---
  4 packets transmitted, 4 received, 0% packet loss, time 3004ms
  rtt min/avg/max/mdev = 1.084/1.220/1.381/0.118 ms
  
  EOT
  "vm_1_to_vm2" = <<-EOT
  PING 10.0.2.4 (10.0.2.4) 56(84) bytes of data.
  64 bytes from 10.0.2.4: icmp_seq=1 ttl=64 time=0.577 ms
  64 bytes from 10.0.2.4: icmp_seq=2 ttl=64 time=0.765 ms
  64 bytes from 10.0.2.4: icmp_seq=3 ttl=64 time=0.962 ms
  64 bytes from 10.0.2.4: icmp_seq=4 ttl=64 time=0.934 ms
  
  --- 10.0.2.4 ping statistics ---
  4 packets transmitted, 4 received, 0% packet loss, time 3030ms
  rtt min/avg/max/mdev = 0.577/0.809/0.962/0.156 ms
  
  EOT
  "vm_2_to_vm0" = <<-EOT
  PING 10.0.2.5 (10.0.2.5) 56(84) bytes of data.
  64 bytes from 10.0.2.5: icmp_seq=1 ttl=64 time=0.740 ms
  64 bytes from 10.0.2.5: icmp_seq=2 ttl=64 time=1.15 ms
  64 bytes from 10.0.2.5: icmp_seq=3 ttl=64 time=5.83 ms
  64 bytes from 10.0.2.5: icmp_seq=4 ttl=64 time=0.733 ms
  
  --- 10.0.2.5 ping statistics ---
  4 packets transmitted, 4 received, 0% packet loss, time 3010ms
  rtt min/avg/max/mdev = 0.733/2.115/5.837/2.155 ms
  
  EOT
}
vm_passwords = <sensitive>
vm_user = {
  "vm_1_username" = "demo"
  "vm_2_username" = "demo"
  "vm_3_username" = "demo"
}
```