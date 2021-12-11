resource_number = 10
series_suffix = "01"
storage_infix = "sta"
region = "eastus2"
tags = {
  "environment" = "dev"
}
kvt_retention_days = 7
kvt_sku = "standard"
tenant_id = "72f988bf-86f1-41af-91ab-2d7cd011db47"
rsv_sku = "Standard"
vnt = {
  addr_space_prefix = "10.20"
  addr_space_suffix = "0/26"
  web_sub_name_prefix = "web-snt"
  web_sub_range_suffix = "0/29"
  sql_sub_name_prefix = "sql-snt"
  sql_sub_range_suffix = "8/29"
  dev_sub_name_prefix = "dev-snt"
  dev_sub_range_suffix = "16/29"
  bas_sub_name = "AzureBastionSubnet"
  bas_sub_range_suffix = "32/27"
}

resource_codes = {
  prefix = "azr"
  resource_group = "rgp"
  key_vault = "kvt"
  recovery_vault = "rsv"
  storage = "sta"
  ext_load_balancer = "elb"
  web = "web"
  development = "dev"
  subnet = "snt"
  sql = "sql" 
  vnet = "vnt"
  net_sec_grp = "nsg"
  public_ip = "pip"
  bastion = "bas"
  availaiblity_set = "avs"
}

sta = {
  tier = "Standard"
  replication = "LRS"  
}