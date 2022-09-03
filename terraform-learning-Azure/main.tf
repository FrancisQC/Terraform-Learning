# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "0f2bc3ae-4338-419d-a374-a7734942d2e5"
}

# Create a resource group
resource "azurerm_resource_group" "Terraform-Learning-rg" {
  name     = "Terraform-Learning-resources"
  location = "australiaeast"
  tags = {
    environment = "Dev"
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "Terraform-vn" {
  name                = "Terraform-Learning-network"
  resource_group_name = azurerm_resource_group.Terraform-Learning-rg.name
  location            = azurerm_resource_group.Terraform-Learning-rg.location
  address_space = ["10.0.0.0/16",
  "192.168.0.0/16"]

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_subnet" "Terraform-sn1" {
  name                 = "Terraform-Learning-sn1"
  resource_group_name  = azurerm_resource_group.Terraform-Learning-rg.name
  virtual_network_name = azurerm_virtual_network.Terraform-vn.name
  address_prefixes     = ["10.0.1.0/24"]
  #   tags = {
  #     environment = "Dev"
  #   }
}

resource "azurerm_network_security_group" "Terraform-nsg1" {
  name                = "Terraform-Learning-nsg1"
  resource_group_name = azurerm_resource_group.Terraform-Learning-rg.name
  location            = azurerm_resource_group.Terraform-Learning-rg.location

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_network_security_rule" "Terraform-nsr1" {
  name                        = "Terraform-Learning-allow-inbound-all"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "14.202.238.18/32"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.Terraform-Learning-rg.name
  network_security_group_name = azurerm_network_security_group.Terraform-nsg1.name
  #Doesn't support tags
}

resource "azurerm_subnet_network_security_group_association" "Terraform-snsga" {
  subnet_id                 = azurerm_subnet.Terraform-sn1.id
  network_security_group_id = azurerm_network_security_group.Terraform-nsg1.id
}


resource "azurerm_public_ip" "Terraform-PIP1" {
  name                = "Terraform-Learning-PublicIP"
  resource_group_name = azurerm_resource_group.Terraform-Learning-rg.name
  location            = azurerm_resource_group.Terraform-Learning-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_network_interface" "Terraform-nic1" {
  name                = "Terraform-Learning-nic1"
  location            = azurerm_resource_group.Terraform-Learning-rg.location
  resource_group_name = azurerm_resource_group.Terraform-Learning-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Terraform-sn1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Terraform-PIP1.id
  }
  tags = {
    environment = "Dev"
  }
}

resource "azurerm_windows_virtual_machine" "Terraform-AD" {
  name                = "TFL-DC01"
  location            = azurerm_resource_group.Terraform-Learning-rg.location
  resource_group_name = azurerm_resource_group.Terraform-Learning-rg.name
  size                = "Standard_DC2s_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.Terraform-nic1.id,
  ]

  # custom_data = filebase64("customdata.tpl")

  admin_password = var.admin_password
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition" #Before 2022 it's 2019-datacenter
    version   = "latest"
  }


  tags = {
    environment = "Dev"
  }
}

resource "azurerm_virtual_machine_extension" "Terraform-AD-Extension" {
  # https://www.reddit.com/r/Terraform/comments/mgobi8/run_powershell_script_on_azure_vm_creation/
  name                 = "${azurerm_windows_virtual_machine.Terraform-AD.name}-extension-name"
  virtual_machine_id   = azurerm_windows_virtual_machine.Terraform-AD.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {
   "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${local.base64EncodedScript}')) | Out-File -filepath postBuild.ps1\" && powershell -ExecutionPolicy Unrestricted -File postBuild.ps1"
  }
  SETTINGS

  depends_on = [
    azurerm_windows_virtual_machine.Terraform-AD
  ]
  # What the settings mean: https://docs.microsoft.com/en-us/windows/desktop/api/lmjoin/nf-lmjoin-netjoindomain


  #JOIN PC TO DOMAIN
  #   settings = <<SETTINGS
  #     {
  #         "Name": "JACKSTROMBERG.COM",
  #         "OUPath": "OU=Users,OU=CustomOU,DC=jackstromberg,DC=com",
  #         "User": "JACKSTROMBERG.COM\\jack",
  #         "Restart": "true",
  #         "Options": "3"
  #     }
  # SETTINGS
  #   protected_settings = <<PROTECTED_SETTINGS
  #     {
  #       "Password": "SecretPassword!"
  #     }
  #   PROTECTED_SETTINGS
  #   depends_on = ["azurerm_virtual_machine.MYADJOINEDVM"]
}

locals {
  yourPowerShellScript = try(file("create-newForestAndDomain.ps1"), null)
  base64EncodedScript  = base64encode(local.yourPowerShellScript)
}

data "azurerm_public_ip" "Terraform-PIP1-data" {
  name                = azurerm_public_ip.Terraform-PIP1.name
  resource_group_name = azurerm_resource_group.Terraform-Learning-rg.name
  # ip_address          = azurerm_public_ip.Terraform-PIP1.ip_address
}


output "public_ip_address_of_windows_vm" {
  value = "${azurerm_windows_virtual_machine.Terraform-AD.name}: ${data.azurerm_public_ip.Terraform-PIP1-data.ip_address}"
}

#terraform apply --refresh-only