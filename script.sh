#!/bin/bash
set -e

echo "=== MuleSoft CloudHub 2.0 Deployment Script ==="

# Configuration
ENVIRONMENT="<+stage.variables.environment>"
APP_NAME="<+stage.variables.app_name>"
REGION="<+stage.variables.region>"
REPLICAS="<+stage.variables.replicas>"
VCORES="<+stage.variables.vcores>"

# Anypoint Platform credentials (use Harness secrets)
ANYPOINT_USERNAME="<+secrets.getValue('anypoint_username')>"
ANYPOINT_PASSWORD="<+secrets.getValue('anypoint_password')>"
ANYPOINT_ORG_ID="<+secrets.getValue('anypoint_org_id')>"
ANYPOINT_ENV_ID="<+secrets.getValue('anypoint_dev_env_id')>"

echo "Authenticating with Anypoint Platform..."
ACCESS_TOKEN=$(curl -s -X POST https://anypoint.mulesoft.com/accounts/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$ANYPOINT_USERNAME\",\"password\":\"$ANYPOINT_PASSWORD\"}" \
  | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
  echo "ERROR: Failed to authenticate with Anypoint Platform"
  exit 1
fi

echo "Authentication successful"

# Check if application exists
echo "Checking if application '$APP_NAME' exists..."
APP_EXISTS=$(curl -s -X GET \
  "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/$APP_NAME" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-ANYPNT-ENV-ID: $ANYPOINT_ENV_ID" \
  -H "X-ANYPNT-ORG-ID: $ANYPOINT_ORG_ID" \
  -o /dev/null -w '%{http_code}')

# Prepare deployment payload
DEPLOYMENT_PAYLOAD=$(cat <<EOF
{
  "target": {
    "provider": "MC",
    "targetId": "$ENVIRONMENT",
    "replicas": $REPLICAS,
    "deploymentSettings": {
      "resources": {
        "cpu": {
          "reserved": "${VCORES}00m",
          "limit": "${VCORES}000m"
        },
        "memory": {
          "reserved": "${VCORES}Gi",
          "limit": "$((VCORES * 2))Gi"
        }
      },
      "http": {
        "inbound": {
          "publicUrl": "$APP_NAME.${REGION}.cloudhub.io"
        }
      },
      "jvm": {
        "args": "-XX:MaxRAMPercentage=80.0"
      }
    }
  },
  "application": {
    "ref": {
      "groupId": "<+stage.variables.groupId>",
      "artifactId": "<+stage.variables.artifactId>",
      "version": "<+stage.variables.version>",
      "packaging": "jar"
    },
    "configuration": {
      "mule.agent.application.properties.service": {
        "properties": {
          "env": "dev",
          "encryption.key": "<+secrets.getValue('mule_encryption_key')>"
        }
      }
    }
  }
}
EOF
)

if [ "$APP_EXISTS" == "200" ]; then
  echo "Application exists. Updating deployment..."
  RESPONSE=$(curl -s -X PUT \
    "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/$APP_NAME" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-ANYPNT-ENV-ID: $ANYPOINT_ENV_ID" \
    -H "X-ANYPNT-ORG-ID: $ANYPOINT_ORG_ID" \
    -H "Content-Type: application/json" \
    -d "$DEPLOYMENT_PAYLOAD")
else
  echo "Application does not exist. Creating new deployment..."
  RESPONSE=$(curl -s -X POST \
    "https://anypoint.mulesoft.com/cloudhub/api/v2/applications" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-ANYPNT-ENV-ID: $ANYPOINT_ENV_ID" \
    -H "X-ANYPNT-ORG-ID: $ANYPOINT_ORG_ID" \
    -H "Content-Type: application/json" \
    -d "$DEPLOYMENT_PAYLOAD")
fi

echo "Deployment Response:"
echo "$RESPONSE" | jq '.'

# Check deployment status
echo "Waiting for deployment to complete..."
MAX_WAIT=600  # 10 minutes
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  STATUS=$(curl -s -X GET \
    "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/$APP_NAME" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-ANYPNT-ENV-ID: $ANYPOINT_ENV_ID" \
    -H "X-ANYPNT-ORG-ID: $ANYPOINT_ORG_ID" \
    | jq -r '.status')
  
  echo "Current status: $STATUS"
  
  if [ "$STATUS" == "RUNNING" ]; then
    echo "✓ Deployment successful! Application is running."
    exit 0
  elif [ "$STATUS" == "FAILED" ]; then
    echo "✗ Deployment failed!"
    exit 1
  fi
  
  sleep 30
  ELAPSED=$((ELAPSED + 30))
done

echo "Deployment timeout. Please check Anypoint Platform for status."
exit 1
