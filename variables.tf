variable "region" {
  default = "eu-central-1"
}

variable "direct_connect_location" {
  default = "EqFra"
}

variable "vpn_bgp_asn" {
  default = 65000
}

variable "customer_gateway_ip" {
  description = "The IP address of the customer gateway"
  type = string
  default = "109.186.2.9"
}

variable "vpn_psk" {
  description = "The pre-shared key for the VPN connection"
  type = string
  default = "My_VPN_PSK_2024"
}

variable "domain_name" {
  description = "The domain name for the Route 53 zone"
  type = string
  default = "https://www.bhdevs.net"
}

variable "transit_gateway_name" {
  description = "The name for the transit gateway"
  default     = "example-transit-gateway"
}

variable "network_firewall_policy_name" {
  description = "The name of the network firewall policy"
  default     = "example-firewall-policy"
}
