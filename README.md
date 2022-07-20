# Packer Template

[Packer](https://learn.hashicorp.com/packer) is an open source tool that enables you to create identical machine images for multiple platforms from a single source template.

## How To Build Packer

### Install Packer

See [install packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli?in=packer/aws-get-started) about how to install packer.

### Build Image

We here using template in `examples/aws-ubuntu.pkr.hcl` as example

```shell
# export AWS key and secret
export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"

cd examples
packer init .
packer build aws-ubuntu.pkr.hcl
```

For more detail you can see [Build an Image](https://learn.hashicorp.com/tutorials/packer/aws-get-started-build-image?in=packer/aws-get-started)

## FAQ

### AWS AMI

#### Error: AMI Name: '<NAME-OF-YOUR-AMI>' is used by an existing AMI: '<ID-OF-YOUR-AMI>'

It means your AMI with name *'<NAME-OF-YOUR-AMI>'* already exists in your [AMIs](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Images:visibility=owned-by-me)
(some time you have your region to find the exists AMIs). In this case you should:

* Remove exists AMIs: remove exists AMI with name *'<NAME-OF-YOUR-AMI>'*
* Rename your `ami_name` attribute in your `*.pkr.hcl`: rename the attribute in your `*.pkr.hcl` file to not exists name
