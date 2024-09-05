terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    remote = {
      source = "tenstad/remote"
      version = "0.1.3"
    }
  }
}

# ------------- Configure variables ----------------------
variable "AZURE_TENANT_ID" {
  type = string
}
variable "AZURE_CLIENT_ID" {
  type = string
}
variable "AZURE_CLIENT_SECRET" {
  type = string
}
variable "AZURE_SUBSCRIPTION_ID" {
  type = string
}

provider "azurerm" {
  features {}

  tenant_id         = var.AZURE_TENANT_ID
  client_id         = var.AZURE_CLIENT_ID
  client_secret     = var.AZURE_CLIENT_SECRET
  subscription_id   = var.AZURE_SUBSCRIPTION_ID

}

variable "vm_count" {
  type    = number
  default = 3
  validation {
    condition     = var.vm_count >= 2 && var.vm_count <= 100
    error_message = "The value of vm_count must be between 2 and 100."
  }
}

resource "random_password" "vm_password" {
  count = var.vm_count
  length  = 16
  special = true
}

# --------------- Provision the VMs and their dependencies -------------------
resource "azurerm_resource_group" "rg" {
  name     = "tf-demo"
  location = "Germany West Central"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "tf-demo-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "tf-demo-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "tf-demo-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "public_ip" {
  count               = var.vm_count
  name                = "demo-pip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "tf-demo-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "tf-demo-vm-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "demo"
  admin_password      = random_password.vm_password[count.index].result
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  disable_password_authentication   = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# ---------- Wait for VM public ip addresses to be provisioned and available--------------------
data "azurerm_public_ip" "public_ip" {
  count = var.vm_count
  name = azurerm_public_ip.public_ip[count.index].name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_linux_virtual_machine.vm]
}
resource "null_resource" "wait_for_ip" {
  count = var.vm_count

  provisioner "local-exec" {
    command = <<EOT
    while ! nc -zv ${data.azurerm_public_ip.public_ip[count.index].ip_address} 22; do
      echo "Waiting for VM ${count.index} Public IP to be accessible..."
      sleep 5
    done
    echo "Public IP ${data.azurerm_public_ip.public_ip[count.index].ip_address} is now accessible."
    EOT
  }
}
# ---------- Run the ping test on each VM --------------------
resource "null_resource" "ping_test" {
  count = var.vm_count

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = data.azurerm_public_ip.public_ip[count.index].ip_address
      user        = azurerm_linux_virtual_machine.vm[count.index].admin_username
      password    = random_password.vm_password[count.index].result
    }

    inline = [
      "ping -c 4 ${azurerm_linux_virtual_machine.vm[(count.index + 1)%var.vm_count].private_ip_address} | tee /home/demo/ping.txt"
    ]
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [null_resource.wait_for_ip]
}

data "remote_file" "ping" {
  count = var.vm_count

  conn {
    host     = data.azurerm_public_ip.public_ip[count.index].ip_address
    user     = azurerm_linux_virtual_machine.vm[count.index].admin_username
    password = random_password.vm_password[count.index].result
    sudo     = true
  }

  path = "/home/demo/ping.txt"
  depends_on = [null_resource.ping_test]
}

# ------------- Save the outputs ------------
output "vm_user" {
  value = {
    for i in range(var.vm_count) : "vm_${i + 1}_username" => azurerm_linux_virtual_machine.vm[i].admin_username
  }
}

output "vm_passwords" {
  sensitive = true
  value = {
    for i in range(var.vm_count) : "vm_${i + 1}_password" => nonsensitive(random_password.vm_password[i].result)
  }
}

resource "local_file" "passwords" {
    content  = jsonencode({
      for i in range(var.vm_count) : "vm_${i + 1}_password" => random_password.vm_password[i].result
    })
    filename = "passwords.txt"
}

output "ping_results" {
  value = {
    for i in range(var.vm_count) : "vm_${i}_to_vm_${(i+1)%var.vm_count}" => data.remote_file.ping[i].content
  }
}