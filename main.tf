terraform {
  required_providers {
    fly = {
      source = "fly-apps/fly"
      version = "0.0.6"
    }
    dnsimple = {
      source = "dnsimple/dnsimple"
      version = "0.11.3"
    }
  }
}

variable dnsimple_token {}
variable dnsimple_account {}
variable fly_api_token {}

variable domain {
  default = "flyio.global"
}

variable app_name {
  default = "js-man-machine"
}

variable fly_org {
  default = "fly-ephemeral"
}

variable regions {
  default = ["mad", "syd", "iad"]
}
provider "fly" {
  fly_api_token = var.fly_api_token
}

provider "dnsimple" {
  account = var.dnsimple_account
  token = var.dnsimple_token
}

resource "fly_app" "app" {
  name = var.app_name
  org = var.fly_org
}

resource "fly_ip" "ip" {
  app = fly_app.app.name
  type = "v4"
}

resource "fly_cert" "root_domain" {
  app = fly_app.app.name
  hostname = var.domain
  depends_on = [
    fly_ip.ip
  ]
}

resource "dnsimple_zone_record" "verify_root_cert" {
  zone_name = var.domain
  name = replace(fly_cert.root_domain.dnsvalidationhostname, ".${var.domain}", "")
  value = fly_cert.root_domain.dnsvalidationtarget
  type = "CNAME"
}


resource "dnsimple_zone_record" "root_hostname" {
  zone_name = var.domain
  name = ""
  value = fly_ip.ip.address
  type = "A"
}

resource "fly_volume" "data" {
  for_each = toset( var.regions )
  app = fly_app.app.name
  region = each.key
  name = "data"
  size =  1
}
resource "fly_machine" "nginx" {
  for_each = toset( var.regions )
  app = fly_app.app.name
  name = "nginx-${each.key}"
  region = each.key
  image  = "nginx"
  env = {
    MODE = "production"
  }
  mounts = [
    {
      volume = fly_volume.data[each.key].id,
      path = "/data"
      # These options have no effect yet
      encrypted = true
      size_gb = 1
    }
  ]

  services = [
    {
      ports = [
        {
          port     = 443
          handlers = ["tls", "http"]
        },
        {
          port     = 80
          handlers = ["http"]
        }
      ]
      "protocol" : "tcp",
      "internal_port" : 80
    }
 ]
}
