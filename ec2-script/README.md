# EC2 Instance Launcher

This Python script interactively launches an EC2 instance within a specified VPC using AWS boto3. It dynamically retrieves available subnets and security groups from your target VPC, prompts for configuration parameters, and launches the instance with default values stored in a `.env` file if no custom input is provided.

## Features

- **Interactive Input with Defaults:**  
  Prompts for AWS region, VPC ID, subnet, security groups, OS type (Linux or Windows), instance type, and instance name. Defaults are used if the user presses Enter.

- **Dynamic Resource Discovery:**  
  - Retrieves available subnets in the specified VPC.
  - Lists security groups in the VPC for interactive selection.

- **OS and AMI Selection:**  
  Prompts the user to choose between **Linux** and **Windows**.  
  - If **Linux** is selected, the script uses the Linux AMI (`LINUX_AMI`) from the `.env` file.
  - If **Windows** is selected, it uses the Windows AMI (`WINDOWS_AMI`) from the `.env` file.

- **Tagging and Instance Waiter:**  
  Applies tags (including a mandatory "Name" tag) based on values from the `.env` file and waits until the instance is running before final confirmation.

## Prerequisites

- Python 3.x  
- AWS credentials configured via environment variables, AWS CLI, or IAM role  
- Python packages: `boto3`, `python-dotenv`

Install dependencies with:
```bash
pip install -r requirements.txt
