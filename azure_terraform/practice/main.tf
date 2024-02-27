# Note: We can either add a Internet gateway or Private network gateway

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-resource-group"
  location = var.region
}

# resource "azurerm_network_security_group" "this" {
#   name = "${var.prefix}-secuirty-group"
#   location            = "${var.region}"
#   resource_group_name = azurerm_resource_group.rg.name

#   security_rule = [{
#     name                       = "ssh"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "22"
#     destination_port_range     = "22"
#   },
#   {
#     name                       = "http"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "80"
#     destination_port_range     = "80"
#   }]

#   tags = {
#     environment = "Production"
#   }
# }

resource "azurerm_virtual_network" "vpc" {
  name                = "${var.prefix}-vpn"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}-subnet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vpc.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "configuration1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "this" {
  name                = "${var.prefix}-fip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# resource "azurerm_lb" "this" {
#     name = "${var.prefix}-lb"
#     location = azurerm_resource_group.rg.location
#     resource_group_name = azurerm_resource_group.rg.name

#     frontend_ip_configuration {
#       name = "PublicIPAddress"
#       public_ip_address_id = azurerm_public_ip.this.id
#     }
# }

resource "tls_private_key" "insecure" {
  algorithm = "ED25519"
}

locals {
  ssh_key_public = sensitive(tls_private_key.insecure.public_key_openssh)
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "${var.prefix}-vm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  size                = "Standard_F2"
  admin_username      = "tfadmin"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "tfadmin"
    public_key = local.ssh_key_public
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    name = "Prod"
  }
}

resource "azurerm_managed_disk" "volume1" {
  name                 = "${var.prefix}-volume1"
  location             = var.region
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 2
}


resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  managed_disk_id    = azurerm_managed_disk.volume1.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm1.id
  lun                = "2"
  caching            = "ReadWrite"
}