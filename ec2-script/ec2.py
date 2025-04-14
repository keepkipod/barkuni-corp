import os
import boto3
from dotenv import load_dotenv

def validate_env_param(var_name):
    """
    Retrieve and validate that an environment variable is set.
    Raises a ValueError if the variable is missing or empty.
    """
    value = os.getenv(var_name)
    if value is None or value.strip() == "":
        raise ValueError(f"Environment variable '{var_name}' is required but not set.")
    return value.strip()

def list_subnets(vpc_id, region):
    """
    List all subnets associated with the given VPC ID in the specified region.
    
    Returns:
        A list of subnet dictionaries.
    """
    ec2_client = boto3.client('ec2', region_name=region)
    response = ec2_client.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    return response.get('Subnets', [])

def choose_subnet(subnets):
    """
    Interactively prompt the user to select a subnet from the provided list.
    
    Returns:
        The chosen Subnet ID as a string.
    """
    print("\nAvailable Subnets in the provided VPC:")
    for idx, subnet in enumerate(subnets):
        subnet_id = subnet.get('SubnetId')
        az = subnet.get('AvailabilityZone')
        cidr = subnet.get('CidrBlock')
        print(f"{idx+1}. Subnet ID: {subnet_id} | Availability Zone: {az} | CIDR: {cidr}")
    
    while True:
        try:
            selection = int(input("Select a subnet by entering its number: "))
            if 1 <= selection <= len(subnets):
                chosen_subnet = subnets[selection-1]['SubnetId']
                print(f"Chosen Subnet: {chosen_subnet}\n")
                return chosen_subnet
            else:
                print("Invalid selection, please choose a number from the list.")
        except ValueError:
            print("Invalid input, please enter a valid number.")

def list_security_groups(vpc_id, region):
    """
    List all security groups associated with the given VPC ID in the specified region.
    
    Returns:
        A list of security group dictionaries.
    """
    ec2_client = boto3.client('ec2', region_name=region)
    response = ec2_client.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    return response.get('SecurityGroups', [])

def choose_security_groups(sg_list):
    """
    Interactively prompt the user to select one or more security groups from the provided list.
    
    Returns:
        A list of chosen security group IDs.
    """
    print("\nAvailable Security Groups in the provided VPC:")
    for idx, sg in enumerate(sg_list):
        print(f"{idx+1}. {sg.get('GroupName')} (ID: {sg.get('GroupId')})")
    
    while True:
        try:
            input_str = input("Select one or more security groups by entering their numbers (comma-separated): ")
            choices = [int(x.strip()) for x in input_str.split(',') if x.strip().isdigit()]
            if not choices:
                print("No valid selection made, please try again.")
                continue

            selected = []
            for num in choices:
                if 1 <= num <= len(sg_list):
                    selected.append(sg_list[num-1]['GroupId'])
                else:
                    print(f"Choice {num} is out of range. Please try again.")
                    selected = []
                    break
            if selected:
                print(f"Selected Security Groups: {selected}\n")
                return selected
        except ValueError:
            print("Invalid input. Please enter valid numbers separated by commas.")

def parse_tags(tag_str, instance_name):
    """
    Parse a comma-separated tag string in the format "Key:Value,Key:Value" into
    a list of tag dictionaries. Ensures that a 'Name' tag is present.
    """
    tags = []
    if tag_str:
        for entry in tag_str.split(","):
            entry = entry.strip()
            if not entry:
                continue
            if ":" in entry:
                key, value = entry.split(":", 1)
                tags.append({"Key": key.strip(), "Value": value.strip()})
    if not any(tag["Key"] == "Name" for tag in tags):
        tags.append({"Key": "Name", "Value": instance_name})
    return tags

def launch_ec2_instance(params, region, subnet_id, security_groups, tags):
    """
    Launch an EC2 instance using the provided parameters.
    
    Parameters:
      params (dict): Contains keys for "AMI_ID" and "INSTANCE_TYPE".
      region (str): AWS region where the instance is launched.
      subnet_id (str): The subnet ID where the instance will reside.
      security_groups (list): The list of security group IDs to assign.
      tags (list): A list of tag dictionaries.
      
    Returns:
      The launched instance ID as a string, or None if launching fails.
    """
    ec2_client = boto3.client('ec2', region_name=region)
    try:
        response = ec2_client.run_instances(
            ImageId=params['AMI_ID'],
            InstanceType=params['INSTANCE_TYPE'],
            MaxCount=1,
            MinCount=1,
            NetworkInterfaces=[
                {
                    'SubnetId': subnet_id,
                    'DeviceIndex': 0,
                    'AssociatePublicIpAddress': True,
                    'Groups': security_groups
                }
            ],
            TagSpecifications=[
                {
                    'ResourceType': 'instance',
                    'Tags': tags
                }
            ]
        )
        instance_id = response['Instances'][0]['InstanceId']
        print(f"Successfully launched instance with ID: {instance_id}")
        
        waiter = ec2_client.get_waiter('instance_running')
        print("Waiting for instance to be in 'running' state...")
        waiter.wait(InstanceIds=[instance_id])
        print("Instance is now running.")
        
        return instance_id
    except Exception as e:
        print(f"Error launching instance: {e}")
        return None

def main():
    load_dotenv()

    region_input = input("Enter AWS region (or press Enter to use REGION from .env): ").strip()
    try:
        region = region_input if region_input else validate_env_param("REGION")
    except ValueError as e:
        print(f"Configuration error: {e}")
        return

    vpc_id = input("Enter the VPC ID: ").strip()
    if not vpc_id:
        print("VPC ID is required. Exiting.")
        return

    subnets = list_subnets(vpc_id, region)
    if not subnets:
        print("No subnets found for the provided VPC ID.")
        return

    chosen_subnet = choose_subnet(subnets)

    sg_list = list_security_groups(vpc_id, region)
    if not sg_list:
        print("No security groups found for the provided VPC.")
        return
    selected_sgs = choose_security_groups(sg_list)

    os_choice = input("Enter OS type [Linux/Windows] (default: Linux): ").strip().lower()
    if os_choice == "windows":
        os_type = "windows"
        ami_id = validate_env_param("WINDOWS_AMI")
    else:
        os_type = "linux"
        ami_id = validate_env_param("LINUX_AMI")

    default_instance_type = validate_env_param("INSTANCE_TYPE")
    instance_type_input = input(f"Enter the instance type (default: {default_instance_type}): ").strip()
    instance_type = instance_type_input if instance_type_input else default_instance_type

    default_instance_name = os.getenv("INSTANCE_NAME", "DefaultInstance")
    instance_name_input = input(f"Enter the instance name (default: {default_instance_name}): ").strip()
    instance_name = instance_name_input if instance_name_input else default_instance_name

    default_tags_str = os.getenv("INSTANCE_TAGS", "")
    tags = parse_tags(default_tags_str, instance_name)

    print(f"\nLaunching a {os_type} instance using AMI {ami_id} in region {region} on subnet {chosen_subnet}...")
    
    params = {
        "AMI_ID": ami_id,
        "INSTANCE_TYPE": instance_type
    }
    
    launch_ec2_instance(params, region, chosen_subnet, selected_sgs, tags)

if __name__ == '__main__':
    main()
