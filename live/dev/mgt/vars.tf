variable "resource_number" {
  type = number 
  description = "Two digit resource number between 10-16 to prevent resource name conflicts for multiple deployments."
  validation {
    condition = alltrue([
        var.resource_number >= 10,
        var.resource_number <= 16
    ])
    error_message = "This value must have be between 10 to 16."
  }
}
variable "series_suffix" {
  type = string
  description = "Series suffix for Azure resources."
  default = "01"
}
variable "storage_infix" {
  type = string 
  description = "Infix for storage accounts."
}

variable "region" {
  type = string
  description = "Azure region."
}

variable "tags" {
  type = map(string)
  description = "Resource tags."
}

variable "kvt_retention_days" {
  type = number
  description = "Key Vault soft delete retention days."
}

variable "kvt_sku" {
  type = string
  description = "Key vault sku name."
}

variable "tenant_id" {
    type = string
    description = "Tenant ID."
    sensitive = true
}

variable "rsv_sku" {
  type = string
  description = "SKU for recovery services vault."
}
variable "vnt" {
  type = map(string)
  description = "Virtual network object."
}

variable "resource_codes" {
  type = map(string)
  description = "Azure resource codes."
}

variable "sta" {
  type = map(string)
  description = "Azure storage resource attributes."
}