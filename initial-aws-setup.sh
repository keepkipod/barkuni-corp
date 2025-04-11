#!/bin/bash
set -euo pipefail

# -----------------------------------------------
# Configuration variables – adjust as needed.
# -----------------------------------------------
ROLE_NAME="terraform"
REGION="us-east-1"
# In this example, we attach the AdministratorAccess policy.
# In production, consider using more restrictive policies.
ROLE_POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"

# -----------------------------------------------
# Create the IAM role for Terraform if missing.
# -----------------------------------------------
echo "Checking if IAM role '${ROLE_NAME}' exists..."
if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "IAM role '${ROLE_NAME}' already exists."
else
  echo "IAM role '${ROLE_NAME}' not found. Creating the role..."

  # Get the current AWS account id.
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

  # Create a temporary file for the trust policy.
  TRUST_POLICY_FILE=$(mktemp)
  cat > "${TRUST_POLICY_FILE}" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT_ID}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  # Create the role using the trust policy.
  aws iam create-role --role-name "${ROLE_NAME}" \
    --assume-role-policy-document "file://${TRUST_POLICY_FILE}" \
    --description "Role assumed by Terraform for managing AWS resources"

  # Clean up the temporary file.
  rm "${TRUST_POLICY_FILE}"

  echo "Attaching policy ${ROLE_POLICY_ARN} to IAM role '${ROLE_NAME}'..."
  aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${ROLE_POLICY_ARN}"
  echo "IAM role '${ROLE_NAME}' created and policy attached successfully."
fi

# -----------------------------------------------
# Retrieve and print the ARN of the IAM role.
# -----------------------------------------------
ROLE_ARN=$(aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.Arn' --output text)
echo "The ARN of the '${ROLE_NAME}' role is: ${ROLE_ARN}"
echo "Prerequisites are set up. You can now run 'terragrunt apply-all' with local state!"
