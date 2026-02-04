## 3 tier Architecture

This architecture is a deep dive to understanding the different independent services of AWS and how they interact to help design a highly available infrastructure.

I'd analyze the different layers of this architecture to help understand how it works.

# VPC Layer
This layer deals with the networking of the infrastructure, it comprises of private subnets, public subnets, Nat Gateways, internet gateway, route tables. The private subnets are mainly for the frontend and backend EC2 instances to protect them from being accessible to the public, they will only be only be able to communictae via the NAT gateway. The database layer for the RDS is also provided in a private subnet and it communicates via the NAT gateway.


