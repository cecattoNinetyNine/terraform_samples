terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

provider "oci" {
  region              = var.region
  auth                = "SecurityToken"
  config_file_profile = "DEFAULT"
}

##### CORE VCN #####
#	<tipo do recuros> <nome do recurso>
resource "oci_core_vcn" "vcn-terraform" {
  dns_label      = "internal"
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_id
  display_name   = "VCN Terraform"
}
##### SECURITY LIST PRIVATE #####
resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn-terraform.id
  display_name   = "private security list"
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  ingress_security_rules {
    stateless   = false
    protocol    = "all"
    source      = "10.0.0.0/24"
    description = "Subnet interna"
  }
  ingress_security_rules {
    stateless   = false
    protocol    = "all"
    source      = "10.0.0.0/16"
    description = ""
  }
}
##### SECURITY LIST PUBLIC #####
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn-terraform.id
  display_name   = "private security list"
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  ingress_security_rules {
    stateless   = false
    protocol    = "all"
    source      = "10.0.0.0/24"
    description = "Subnet interna"
  }
  ingress_security_rules {
    stateless   = false
    protocol    = "all"
    source      = "10.0.0.0/16"
    description = ""
  }
}
##### NAT GATEWAY ######
resource "oci_core_nat_gateway" "vcn-terraform-nat" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn-terraform.id
  display_name   = "vcn-terraform NAT"
}
##### INTERNET GATEWAY #####
resource "oci_core_internet_gateway" "vcn-terraform-internet-gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn-terraform.id
  display_name   = "vcn-terraform Internet Gateway"
}
##### SERVICE GATEWAY #####
resource "oci_core_service_gateway" "vcn-terraform-service-gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn-terraform.id
  display_name   = "vcn-terraform Service Gateway"
  services {
    service_id = data.oci_core_services.all_services.services[0].id #todos os servicos
  }
}
data "oci_core_services" "all_services" {
  # This data source fetches details of all services that can be accessed through a service gateway
}
##### ROUTE TABLE ######
resource "oci_core_route_table" "private-route-table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn-terraform.id
  display_name   = "Private Subnet Route"
  route_rules {
    destination_type  = "CIDR_BLOCK"
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.vcn-terraform-nat.id
    description       = "Saida"
  }
}
resource "oci_core_route_table" "public-route-table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn-terraform.id
  display_name   = "Public Subnet Route"
  route_rules {
    destination_type  = "CIDR_BLOCK"
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.vcn-terraform-internet-gateway.id
    description       = "Saida"
  }
}
##### SUBNET PRIVADA #####
resource "oci_core_subnet" "private" {
  vcn_id                     = oci_core_vcn.vcn-terraform.id
  cidr_block                 = "10.0.0.0/24"
  compartment_id             = var.compartment_id
  display_name               = "Private subnet 1"
  prohibit_public_ip_on_vnic = true
  dns_label                  = "private"
  route_table_id             = oci_core_route_table.private-route-table.id
  security_list_ids          = [oci_core_security_list.private.id]
}
##### SUBNET PUBLICA #####
resource "oci_core_subnet" "publica" {
  vcn_id                     = oci_core_vcn.vcn-terraform.id
  cidr_block                 = "10.0.1.0/24"
  compartment_id             = var.compartment_id
  display_name               = "Public subnet 1"
  prohibit_public_ip_on_vnic = false
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public-route-table.id
  security_list_ids          = [oci_core_security_list.public.id]
}
