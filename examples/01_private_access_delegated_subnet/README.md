# Example 01: Private MySQL Access with Delegated Subnet

In this first MySQL example, we deploy an **Azure Database for MySQL Flexible Server** using **Terraform/OpenTofu**.
The server is injected into a **delegated database subnet** created by the networking module, uses a linked **Azure Private DNS Zone**, and has public network access disabled.

This example focuses on the **private access / VNet integration** deployment path, without Private Endpoint, Bastion, or application client layers.

---

## 🧭 Architecture Overview

<img src="01_private_access_delegated_subnet_mysql_architecture.jpg" width="900"/>

This deployment creates:

- A dedicated **Azure Resource Group**
- One **Azure VNet** using `terraform-az-fk-vnet`
- One application subnet for future client workloads
- One database subnet delegated to `Microsoft.DBforMySQL/flexibleServers`
- One **Private DNS Zone** using `terraform-az-fk-private-dns`
- One **MySQL Flexible Server** using the local `terraform-az-fk-mysql` module
- One sample database named `foggydb`

This is the most direct way to understand how the MySQL module behaves when the server is deployed with delegated subnet private access.

---

## 🧱 Network Layout

- **VNet CIDR:** `10.50.0.0/16`
- **Application subnet:** `10.50.10.0/24`
- **Delegated database subnet:** `10.50.20.0/24`
- **Delegated service:** `Microsoft.DBforMySQL/flexibleServers`
- **Private DNS Zone:** `fk-mysql01.mysql.database.azure.com`

The database subnet is dedicated to Azure Database for MySQL Flexible Server private access.
The MySQL service is integrated with this subnet directly, without a Private Endpoint in this example.

---

## 🚀 Deployment Steps

Copy the example variables file and set a strong MySQL administrator password:

```bash
cp terraform.tfvars.example terraform.tfvars
```

If you reuse a shared Azure training tfvars file, make sure it also provides `mysql_admin_password`.
Values such as `my_public_ip` are not used by this private access example.

Initialize and apply the Terraform/OpenTofu configuration:

```bash
tofu init
tofu plan
tofu apply
```

After a successful deployment, OpenTofu will output:

- The MySQL Flexible Server ID
- The MySQL FQDN
- The created database IDs
- The VNet ID
- The delegated database subnet ID

---

## 🧠 Runtime Notes

After deployment, the MySQL server should:

- have public network access disabled
- be reachable through the delegated database subnet
- resolve through the linked Private DNS Zone
- expose the `foggydb` database

Use the MySQL FQDN from the outputs when building connection strings.
Avoid pinning private IP addresses because Azure can change service-assigned addresses.

---

## 🖼️ Azure Console And Runtime Verification

### MySQL Flexible Server

In the Azure portal, verify that the MySQL Flexible Server exists in the expected resource group and region.

<img src="01_private_access_delegated_subnet_mysql_overview.jpg" width="900"/>

### Networking View

Confirm that the server is integrated with the `fk-subnet-db` delegated subnet and that public network access is disabled.

<img src="01_private_access_delegated_subnet_mysql_networking.jpg" width="900"/>

### Private DNS

Confirm that the Private DNS Zone is linked to the VNet created by `terraform-az-fk-vnet`.
Name resolution should use a zone ending with `.mysql.database.azure.com` for this delegated subnet private access pattern.

<img src="01_private_access_delegated_subnet_private_dns_link.jpg" width="900"/>

---

## 🧹 Cleanup

To remove all resources created by this example:

```bash
tofu destroy
```

---

## ✅ Summary

This example demonstrates:

- How to deploy **Azure Database for MySQL Flexible Server** using Terraform/OpenTofu
- How to use the MySQL module with delegated subnet private access
- How to combine the module with `terraform-az-fk-vnet`
- How to combine the module with `terraform-az-fk-private-dns`
- How to keep MySQL networking explicit and outside the root database module

---

## 🌐 Learn More

Visit [FoggyKitchen.com](https://foggykitchen.com/) for Azure, OCI, multicloud, and Terraform/OpenTofu learning resources.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.  
See [LICENSE](../../LICENSE) for more details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
