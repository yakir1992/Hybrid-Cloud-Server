provider "aws" {
  region = var.region
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "example" {
  ami           = "ami-0e872aee57663ae2d" # Example AMI ID, replace with your own
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example.id

  tags = {
    Name = "ExampleInstance"
  }
}

resource "aws_dx_gateway" "example" {
  name            = "example_dx_gateway"
  amazon_side_asn = "64512"
}

resource "aws_dx_connection" "example" {
  name          = "ExampleDirectConnect"
  bandwidth     = "1Gbps"
  location      = var.direct_connect_location
  provider_name = "aws"
}

resource "aws_dx_private_virtual_interface" "example" {
  address_family  = "ipv4"
  bgp_asn         = var.vpn_bgp_asn
  connection_id   = aws_dx_connection.example.id
  name            = "ExamplePrivateVIF"
  vlan            = 101
  dx_gateway_id   = aws_dx_gateway.example.id

  timeouts {
    create = "10m"
  }
}

resource "aws_ec2_transit_gateway" "example" {
  description = var.transit_gateway_name
}

resource "aws_ec2_transit_gateway_vpc_attachment" "example" {
  subnet_ids              = [aws_subnet.example.id]
  transit_gateway_id      = aws_ec2_transit_gateway.example.id
  vpc_id                  = aws_vpc.example.id

  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
}


resource "aws_customer_gateway" "example" {
  bgp_asn    = var.vpn_bgp_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"
}

resource "aws_vpn_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_vpn_connection" "example" {
  customer_gateway_id = aws_customer_gateway.example.id
  vpn_gateway_id      = aws_vpn_gateway.example.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr = "169.254.6.0/30"
  tunnel1_preshared_key = var.vpn_psk

  tunnel2_inside_cidr = "169.254.7.0/30"
  tunnel2_preshared_key = var.vpn_psk
}



resource "aws_route53_zone" "example" {
  name = var.domain_name
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "www"
  type    = "A"
  ttl     = 300
  records = [aws_instance.example.public_ip]
}


resource "aws_networkfirewall_firewall_policy" "example" {
  name = var.network_firewall_policy_name

  firewall_policy {
    stateless_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.example_stateless.arn
      priority     = 1
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.example_stateful.arn
    }

    stateless_default_actions = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }
}

resource "aws_networkfirewall_firewall" "example" {
  name                = "example-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.example.arn
  vpc_id              = aws_vpc.example.id

  subnet_mapping {
    subnet_id = aws_subnet.example.id
  }
}

resource "aws_networkfirewall_rule_group" "example_stateless" {
  capacity = 100
  name     = "example-stateless-rule-group"
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1

          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6]  # TCP protocol

              source {
                address_definition = "0.0.0.0/0"
              }

              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "example_stateful" {
  capacity = 100
  name     = "example-stateful-rule-group"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          destination      = "0.0.0.0/0"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "IP"
          source           = "0.0.0.0/0"
          source_port      = "ANY"
        }

        rule_option {
          keyword = "sid:1"
        }
      }
    }
  }
}
