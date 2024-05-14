terraform{
    required_providers{
        azurerm = {
            source = "hashicorp/azurerm"
            version = "=3.102.0"
        }
    }

    backend "local" {
        path = "terraform.tfstate"
  }
}

provider "azurerm"{
    features{}
    subscription_id = ""
    # client_id       = ""
    # client_secret   = ""
    tenant_id       = ""