packer {
  required_plugins {
    azure = {
      version = ">= 2.5.1"
      source  = "github.com/hashicorp/azure"
    }
  }
}

source "azure-arm" "basic-example" {
  client_id           = "543c2581-dd7f-406f-b108-40a932c"
  client_secret       = "Rtz8Q~v8LOE5OF5dzPJ4mjG6KiAssn"
  resource_group_name = "packerdemo"
  subscription_id     = "d6648ae8-3690-454e-ab03-88b7483d3"
  tenant_id           = "964c8d5d-5d50-4ef0-8220-46a5be85e"


  capture_name_prefix               = "packer"
  managed_image_name                = "nginx-custom-image"
  managed_image_resource_group_name = "packerdemo"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"


  azure_tags = {
    dept = "engineering"
  }

  location = "West US"
  vm_size  = "Standard_D2s_v3"
}

build {
  sources = ["sources.azure-arm.basic-example"]
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline          = ["apt-get update", "apt-get upgrade -y", "apt-get -y install nginx", "cd /tmp", "git clone https://github.com/devopsinsiders/StreamFlix.git", "cp -r /tmp/StreamFlix/* /var/www/html", "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"]
    inline_shebang  = "/bin/sh -x"
  }
}



