# DolphinScheduler AWS AMI Builder

Build [Apache DolphinScheduler](https://github.com/apache/dolphinscheduler) AMI with [Packer](https://learn.hashicorp.com/packer)

## How to Build It

You can see more detail about how to build AMI in [AMI build](../../../README.md#how-to-build-with-packer)

## How to Launch EC2 Instance from AMI

<!-- TODO -->
Currently, you have to build this AMI by yourself and then launch new EC2 instance from `EC2 -> Images -> AMIs` sidebar path.

### What Should I Do after EC2 Instance Launch

After you launch the instance, you should add one new [inbound rules](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules-reference.html#sg-rules-web-server) and change the port value `12345`, which it is the default port
for DolphinScheduler. After that, you can login DolphinScheduler service with **admin/dolphinscheduler123** as default username/password via instance's **<Public-IPv4-address>:12345/dolphinscheduler/ui** or **<Public-IPv4-DNS>:123456/dolphinscheduler/ui**.
For about how to use DolphinScheduler you view detail in [functions of DolphinScheduler](https://dolphinscheduler.apache.org/en-us/docs/dev/user_doc/guide/homepage.html).

## Launch AMI Instance Type Requests

The minimum required instance type to launch this AMI is **t2.micro**(it is free if your account qualify under the [AWS free-tier][2], but if your account doesn't qualify under it, we're not responsible for any charges that you may incur),
and with this type you can start DolphinScheduler service and run some easy workflow, but the web UI may be a little stuck. The **t2.small** or above instance type is be recommended if you want a better experience, an with that type you can
run some middle scale workflow and have a smooth web UI experience. ref [AWS EC2 Instance Type][1]

## REF

* [AWS EC2 Instance Type][1]

[1]: https://aws.amazon.com/ec2/instance-types/
[2]: https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=*all