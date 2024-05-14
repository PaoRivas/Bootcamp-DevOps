resource "azurerm_resource_group" "devops_bootcamp_rg" {
  name     = "DevopsBootcamp_Lab"
  location = var.location
}

resource "azurerm_virtual_network" "devops_bootcamp_vnet" {
  name                = "DevopsVNet_Lab"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
}

resource "azurerm_subnet" "public_subnet" {
  name                 = "PublicSubnet"
  resource_group_name  = azurerm_resource_group.devops_bootcamp_rg.name
  virtual_network_name = azurerm_virtual_network.devops_bootcamp_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "PrivateSubnet"
  resource_group_name  = azurerm_resource_group.devops_bootcamp_rg.name
  virtual_network_name = azurerm_virtual_network.devops_bootcamp_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "PublicIP_Lab"
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
  location            = azurerm_resource_group.devops_bootcamp_rg.location
  allocation_method   = "Static"
  sku                 = "Basic"

  tags = {
    environment = var.env
  }
}

resource "azurerm_network_security_group" "general_security" {
  name                = "${var.env}-${var.product}-linux-vm-nsg"
  location            = azurerm_resource_group.devops_bootcamp_rg.location
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.sourceip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "public_nic" {
  name                = "PublicNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name

  ip_configuration {
    name                          = "publicConfig"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_network_interface_security_group_association" "public_nic_nsg" {
  network_interface_id      = azurerm_network_interface.public_nic.id
  network_security_group_id = azurerm_network_security_group.general_security.id
}

resource "azurerm_network_interface" "private_nic" {
  name                = "PrivateNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name

  ip_configuration {
    name                          = "privateConfig"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "private_nic_nsg" {
  network_interface_id      = azurerm_network_interface.private_nic.id
  network_security_group_id = azurerm_network_security_group.general_security.id
}

data "template_file" "docker_install" {
  template = file("docker_install.cfg")
}

resource "azurerm_linux_virtual_machine" "vm_with_public_ip" {
  name                  = "VMwithPublicIP"
  resource_group_name   = azurerm_resource_group.devops_bootcamp_rg.name
  location              = var.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.public_nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  custom_data = base64encode(data.template_file.docker_install.rendered)
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "vm_with_private_ip" {
  name                  = "VMwithPrivateIP"
  resource_group_name   = azurerm_resource_group.devops_bootcamp_rg.name
  location              = var.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.private_nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  custom_data = base64encode(data.template_file.docker_install.rendered)
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
