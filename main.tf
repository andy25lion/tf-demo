terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

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
}

resource "random_password" "vm_password" {
  count = var.vm_count
  length  = 16
  special = true
}


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

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "tf-demo-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
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

output "vm_user" {
  value = {
    for i in range(var.vm_count) : "vm_${i + 1}_username" => azurerm_linux_virtual_machine.vm[i].admin_username
  }
}

output "vm_passwords" {
  sensitive = true
  value = nonsensitive({
    for i in range(var.vm_count) : "vm_${i + 1}_password" => nonsensitive(random_password.vm_password[i].result)
  })
}

resource "local_file" "passwords" {
    content  = jsonencode({
      for i in range(var.vm_count) : "vm_${i + 1}_password" => random_password.vm_password[i].result
    })
    filename = "passwords.txt"
}