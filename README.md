# Create EC2 instance with load balancer and persistence layer using IAC (Terraform)
![image](https://user-images.githubusercontent.com/40290711/158039580-67cf7632-d3b5-4d59-b1a5-88a51214bb94.png)

### Table of Content
1. Create a VPC which should have a public and private subnet
2. Create a role with s3 access.
3. Launch an ec2 instance with the role created in step 1, inside the private subnet of VPC, and
install apache through bootstrapping. (You need to have your NAT gateway attached to your
private subnet)
4. Create a load balancer in public subnet.
5. Add the ec2 instance, under the load balancer
6. Create an auto scaling group with minimum size of 1 and maximum size of 3 with load balancer
created in step 3.
7. Add the created instances under the auto scaling group.
8. Write a life cycle policy with the following parameters:
a. scale in : CPU utilization > 80%
b. scale out : CPU Utilization < 60%
9. Create a persistence layer of your choice and ensure that the ec2 instance can access it

### Prerequisites:
1. Basic knowledge of aws is required
2. Basic knowledge of terraform is required
3. AWS CLI (Install AWS CLI)
4. Terraform (Install Terraform)

#### Project Structure

![image](https://user-images.githubusercontent.com/40290711/158039960-a40a5c71-e0ea-48e5-85ef-9dcd16013ae8.png)


### Let get Started!!!!

#### Step 1
- aws configure

We have to create a new profile using aws configure command. This require access key and secret key to make profile and this profile will be used in terraform 
provider for authentication.

$ aws configure --profile yourProfilename

![image](https://user-images.githubusercontent.com/40290711/158039874-f1c6186d-7ce6-410d-a0e7-47ea2a827a90.png)

#### Step 2
- Providers (terraform and aws) and profile

main.tf

![image](https://user-images.githubusercontent.com/40290711/158040058-1a320520-cb1d-40ae-b681-2f2e0894d8c7.png)

#### Step 3
- VPC (creating a VPC)

main.tf

![image](https://user-images.githubusercontent.com/40290711/158040282-6619f5b8-940f-4c13-bbed-53c0987b09ad.png)

#### Step 4
- Subnets (Private & Public)

main.tf

![image](https://user-images.githubusercontent.com/40290711/158040355-600d48db-08b3-4ff0-82d0-db3f920c558f.png)

#### Step 5
- Internal Gateway for VPC (Create a internal gateway for VPC)

main.tf

![image](https://user-images.githubusercontent.com/40290711/158040500-8c557031-7e1d-46e5-b63b-74790cc5ab10.png)

#### Step 6 
- Elastic IP (Create a Elastic IP)

main.tf

![image](https://user-images.githubusercontent.com/40290711/158040594-c80980ea-846a-4fd8-8796-a2db5b15e6c9.png)

#### Step 7
- Route Table and Association for Public and Private Subnets 

main.tf

![image](https://user-images.githubusercontent.com/40290711/158040780-1678b937-189d-4264-9d4c-4689f2cef0c2.png)

![image](https://user-images.githubusercontent.com/40290711/158040808-a94ec66d-7710-48cd-b14e-825abe9be2eb.png)

#### Step 8
- Create an S3 bucket and make it Private

main.tf

![image](https://user-images.githubusercontent.com/40290711/158040959-36f5900b-ab1d-4e1b-b688-04b84dfdd415.png)

#### Step 9
- Create a policy that will give access to the S3 bucket

allowaccess.json

![image](https://user-images.githubusercontent.com/40290711/158041089-f4a04f93-6ee6-4109-92df-2c31588dccfd.png)

main.tf

![image](https://user-images.githubusercontent.com/40290711/158041156-b891097b-73fe-4c14-a472-123b72fe3edb.png)

#### Step 10
- Create an IAM role

ec2-assume-policy.json

![image](https://user-images.githubusercontent.com/40290711/158041239-cbbb9571-7a11-4ccd-ad8d-caf0d5563121.png)

main.tf

![image](https://user-images.githubusercontent.com/40290711/158041257-52ff9e9e-9aa6-438f-a7e4-7c7447bdcb8d.png)

#### Step 11
- Policy Attachment (Attach the policy to the role)

main.tf

![image](https://user-images.githubusercontent.com/40290711/158041347-7614edda-a1b6-4ae7-bf20-7e4c3404ebf5.png)


#### Step 12
- Create Security Group 

main.tf

![image](https://user-images.githubusercontent.com/40290711/158041555-3a0d0a35-58f2-4706-873a-b5c554bf501e.png)

![image](https://user-images.githubusercontent.com/40290711/158041573-11943c91-cc9e-4465-9a0a-e7c9d7496c2a.png)

#### Step 13
- Create apache launch configuration

ec2.tf

![image](https://user-images.githubusercontent.com/40290711/158041700-f474e629-8bc8-4045-a13d-6f974362feae.png)

#### Step 14 
- Create Apache web instance EC2

ec2.tf

![image](https://user-images.githubusercontent.com/40290711/158041781-e64b7eb7-0680-4fc7-9cdc-00eac2a6b10b.png)

#### Step 15
- Create IAM instance profile

main.tf

![image](https://user-images.githubusercontent.com/40290711/158041874-8a44988e-eed6-4894-b184-6ad9d1c6adf5.png)

#### Step 16
- Create an application load balancer security group

main.tf

![image](https://user-images.githubusercontent.com/40290711/158041950-7ef719df-dd17-4336-b7b7-f4a3dbf1be14.png)


#### Step 17
- Create a new application load balancer in public subnet

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042017-857d58c8-2905-45f1-929b-3b232ce2cd7a.png)

#### Step 18
- Create a new target group for the application load balancer

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042059-66b6fcd5-d53a-476e-8a3d-cc41f203bab4.png)

#### Step 19 
- Create a listener 

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042104-8a5c1c51-ed7e-4500-a20f-5d95c4a2f7b7.png)


#### Step 20 
- Creating a target group attachment for the target group

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042157-6b0e1a48-2139-4f72-91b9-f5280c5b7421.png)

#### Step 21 
- Create a new ALB Target Group Attachment

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042281-ae1d644d-9319-491f-8bb5-aa4bda2e7c52.png)

#### Step 22 
- Create an auto scaling group

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042337-e14c4237-73c5-4105-84f5-3c4617452385.png)

![image](https://user-images.githubusercontent.com/40290711/158042356-6511a7cd-0b71-4e9e-867c-1d3434d9781e.png)

#### Step 23
- Write a life cycle policy to scale up and down

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042450-6489c3ec-7881-4b21-b31f-2ad5d2cb6a77.png)

#### Step 24 
- Write a trigger using a CloudWatch alarm

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042514-a6d94d46-f31d-4d89-9782-3059598e0cad.png)

![image](https://user-images.githubusercontent.com/40290711/158042555-c4fc6010-e048-4f9e-9a78-c8083c2b3e11.png)

#### Step 25
- Create Elastic Block Storage for our second EC2 instance 

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042647-08be6fcb-7a11-48c7-a821-37714eb011ff.png)

#### Step 26 
- Create a volume attachment for our second EC2 instance

main.tf

![image](https://user-images.githubusercontent.com/40290711/158042708-6aba2f9f-af7e-45e4-ac7f-265e9f321377.png)

#### Step 27
- Login into your AWS Console and click on the autoscaling EC2. Then copy the Public IPv4 address to your web browser:

![image](https://user-images.githubusercontent.com/40290711/158042904-4c977784-c4b0-4e7b-aeb0-cac75423c670.png)




#### The End
