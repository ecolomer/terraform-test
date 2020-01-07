package test

import (
	"fmt"
	"testing"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/iam"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Testing AWS EC2 instance module.
func TestTerraformAwsEc2Instance(t *testing.T) {
	t.Parallel()

	// The folder where we have our Terraform code
	workingDir := "../examples"

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer test_structure.RunTestStage(t, "destroy_stack", func() {
		logger.Log(t, "################## Destroying Stack ##################")
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
	})

	// Setup and Deploy. Define Terraform options to be used and deploy infrastructure
	test_structure.RunTestStage(t, "setup", func() {
		logger.Log(t, "################## Setting up TF Options ###################")
		terraformVars := getTerraformVars(t)
		terraformOptions := &terraform.Options{TerraformDir: workingDir, Vars: terraformVars}
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		logger.Log(t, "################## Deploying Stack ##################")
		terraform.InitAndApply(t, terraformOptions)
	})

	// Perform testing
	test_structure.RunTestStage(t, "testing", func() {
		logger.Log(t, "################## Testing Stack ##################")
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)

		// Validate infrastructure
		validateInstanceTags(t, terraformOptions)
		validateInstanceBaseOptions(t, terraformOptions)
		validateElasticAddress(t, terraformOptions)
		validateSecurityGroups(t, terraformOptions)
		validateIamRoles(t, terraformOptions)
	})
}

func getTerraformVars(t *testing.T) map[string]interface{} {
	// Generate unique ID to avoid clashes with other resources already deployed in the AWS account
	// or being created by parallel tests running at the same time
	uniqueID := random.UniqueId()

	// Define variables to use when deploying infrastructure using Terraform
	awsRegion := "eu-west-1"
	instanceName := fmt.Sprintf("terratest-%s", uniqueID)
	amiID := aws.GetAmazonLinuxAmi(t, awsRegion)
	inboundRules := `[{"port":80,"protocol":"tcp","source":["0.0.0.0/0"],"description":"Allow all HTTP traffic"}]`
	outboundRules := `[{"port":0,"protocol":"-1","destination":["0.0.0.0/0"],"description":"Allow all egress traffic"}]`
	managedPolicies := `[ "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess" ]`
	tags := `{"project": "terratest"}`

	// VPC is an optional argument for all resources created. But, if no VPC is supplied, some resources will not be
	// created correctly. So, we need to select a VPC to provide as a parameter.
	vpcs, err := aws.GetVpcsE(t, nil, awsRegion)
	require.NoError(t, err)
	subnets := aws.GetSubnetsForVpc(t, vpcs[0].Id, awsRegion)

	return map[string]interface{}{
		"aws_region":              awsRegion,
		"instance_name":           instanceName,
		"ami":                     amiID,
		"vpc":                     vpcs[0].Id,
		"subnet":                  subnets[0].Id,
		"volume_size":             8,
		"elastic_ip":              true,
		"inbound_security_rules":  inboundRules,
		"outbound_security_rules": outboundRules,
		"managed_policies":        managedPolicies,
		"custom_tags":             tags,
	}
}

func validateInstanceTags(t *testing.T, terraformOptions *terraform.Options) {
	logger.Log(t, "################## Testing Instance Tags ##################")

	// Run `terraform output` to get the value of an output variable
	instanceID := terraform.Output(t, terraformOptions, "instance_id")

	// Look up the tags for the given Instance ID
	instanceTags := aws.GetTagsForEc2Instance(t, terraformOptions.Vars["aws_region"].(string), instanceID)

	// Verify that expected name tag is one of the tags
	nameTag, containsNameTag := instanceTags["Name"]
	assert.True(t, containsNameTag)
	assert.Equal(t, terraformOptions.Vars["instance_name"].(string), nameTag)

	// Verify that expected project tag is one of the tags
	projectTag, containsProjectTag := instanceTags["project"]
	assert.True(t, containsProjectTag)
	assert.Equal(t, "terratest", projectTag)

	// Verify that expected owner tag is one of the tags
	ownerTag, containsOwnerTag := instanceTags["owner"]
	assert.True(t, containsOwnerTag)
	assert.Equal(t, terraformOptions.Vars["instance_name"].(string), ownerTag)

	// Verify that expected env tag is one of the tags
	envTag, containsEnvTag := instanceTags["env"]
	assert.True(t, containsEnvTag)
	assert.Equal(t, "dev", envTag)

	// Verify that expected owner tag is one of the tags
	builtUsingTag, containsBuiltUsingTag := instanceTags["built-using"]
	assert.True(t, containsBuiltUsingTag)
	assert.Equal(t, "terraform", builtUsingTag)
}

func validateInstanceBaseOptions(t *testing.T, terraformOptions *terraform.Options) {
	logger.Log(t, "################## Testing Instance AMI / VPC / Subnet / EBS ##################")

	// Run `terraform output` to get the value of an output variable
	instanceID := terraform.Output(t, terraformOptions, "instance_id")

	// Get EC2 instance attributes
	ec2Client := aws.NewEc2Client(t, terraformOptions.Vars["aws_region"].(string))
	instanceInput := ec2.DescribeInstancesInput{InstanceIds: []*string{aws_sdk.String(instanceID)}}
	instanceOutput, err := ec2Client.DescribeInstances(&instanceInput)
	require.NoError(t, err)

	assert.Equal(t, terraformOptions.Vars["ami"].(string), aws_sdk.StringValue(instanceOutput.Reservations[0].Instances[0].ImageId))
	assert.Equal(t, terraformOptions.Vars["vpc"].(string), aws_sdk.StringValue(instanceOutput.Reservations[0].Instances[0].VpcId))
	assert.Equal(t, terraformOptions.Vars["subnet"].(string), aws_sdk.StringValue(instanceOutput.Reservations[0].Instances[0].SubnetId))

	// Get EBS volume attributes
	volumeInput := ec2.DescribeVolumesInput{
		Filters: []*ec2.Filter{{Name: aws_sdk.String("attachment.instance-id"), Values: []*string{aws_sdk.String(instanceID)}}},
	}

	volumeOutput, err := ec2Client.DescribeVolumes(&volumeInput)
	require.NoError(t, err)
	assert.Equal(t, terraformOptions.Vars["volume_size"].(float64), float64(aws_sdk.Int64Value(volumeOutput.Volumes[0].Size)))
}

func validateElasticAddress(t *testing.T, terraformOptions *terraform.Options) {
	logger.Log(t, "################## Testing Elastic IP address ##################")

	// Run `terraform output` to get the value of an output variable
	instanceID := terraform.Output(t, terraformOptions, "instance_id")
	elasticIP := terraform.Output(t, terraformOptions, "elastic_ip")

	// Get EC2 instance attributes
	ec2Client := aws.NewEc2Client(t, terraformOptions.Vars["aws_region"].(string))

	// Get Elastic IP addresses
	addressesInput := ec2.DescribeAddressesInput{
		Filters: []*ec2.Filter{{Name: aws_sdk.String("instance-id"), Values: []*string{aws_sdk.String(instanceID)}}},
	}

	addressesOutput, err := ec2Client.DescribeAddresses(&addressesInput)
	require.NoError(t, err)
	assert.Equal(t, elasticIP, aws_sdk.StringValue(addressesOutput.Addresses[0].PublicIp))
}

func validateSecurityGroups(t *testing.T, terraformOptions *terraform.Options) {
	logger.Log(t, "################## Testing Instance Security Groups ##################")

	// Run `terraform output` to get the value of an output variable
	instanceID := terraform.Output(t, terraformOptions, "instance_id")

	// Get EC2 instance attributes
	ec2Client := aws.NewEc2Client(t, terraformOptions.Vars["aws_region"].(string))
	instanceInput := ec2.DescribeInstancesInput{InstanceIds: []*string{aws_sdk.String(instanceID)}}
	instanceOutput, err := ec2Client.DescribeInstances(&instanceInput)
	require.NoError(t, err)

	groupID := aws_sdk.StringValue(instanceOutput.Reservations[0].Instances[0].NetworkInterfaces[0].Groups[0].GroupId)

	// Get security group attributes
	groupsInput := ec2.DescribeSecurityGroupsInput{
		Filters: []*ec2.Filter{{Name: aws_sdk.String("group-id"), Values: []*string{aws_sdk.String(groupID)}}},
	}

	groupsOutput, err := ec2Client.DescribeSecurityGroups(&groupsInput)
	require.NoError(t, err)
	assert.Equal(t, int64(80), aws_sdk.Int64Value(groupsOutput.SecurityGroups[0].IpPermissions[0].FromPort))
	assert.Equal(t, int64(80), aws_sdk.Int64Value(groupsOutput.SecurityGroups[0].IpPermissions[0].ToPort))
	assert.Equal(t, "tcp", aws_sdk.StringValue(groupsOutput.SecurityGroups[0].IpPermissions[0].IpProtocol))
	assert.Equal(t, "0.0.0.0/0", aws_sdk.StringValue(groupsOutput.SecurityGroups[0].IpPermissions[0].IpRanges[0].CidrIp))
	assert.Equal(t, int64(0), aws_sdk.Int64Value(groupsOutput.SecurityGroups[0].IpPermissionsEgress[0].FromPort))
	assert.Equal(t, int64(0), aws_sdk.Int64Value(groupsOutput.SecurityGroups[0].IpPermissionsEgress[0].ToPort))
	assert.Equal(t, "-1", aws_sdk.StringValue(groupsOutput.SecurityGroups[0].IpPermissionsEgress[0].IpProtocol))
	assert.Equal(t, "0.0.0.0/0", aws_sdk.StringValue(groupsOutput.SecurityGroups[0].IpPermissionsEgress[0].IpRanges[0].CidrIp))
}

func validateIamRoles(t *testing.T, terraformOptions *terraform.Options) {
	logger.Log(t, "################## Testing Instance IAM Roles ##################")

	// Run `terraform output` to get the value of an output variable
	roleName := terraform.Output(t, terraformOptions, "iam_role_name")

	// Get IAM role managed policies
	sess, err := aws.NewAuthenticatedSession(terraformOptions.Vars["aws_region"].(string))
	require.NoError(t, err)
	iamClient := iam.New(sess)
	policiesInput := iam.ListAttachedRolePoliciesInput{RoleName: aws_sdk.String(roleName)}
	policiesOutput, err := iamClient.ListAttachedRolePolicies(&policiesInput)
	require.NoError(t, err)
	assert.Equal(t, "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess", aws_sdk.StringValue(policiesOutput.AttachedPolicies[0].PolicyArn))
}
