# MuleSoft CloudHub 2.0 Deployment - Configuration Guide

## Overview
This deployment template provides a complete CI/CD pipeline for deploying MuleSoft applications to CloudHub 2.0 using Harness.

## Prerequisites

### 1. Harness Setup
- Harness account with CI/CD modules enabled
- Project and Organization configured
- Delegate installed and running

### 2. MuleSoft/Anypoint Platform
- Anypoint Platform account
- CloudHub 2.0 environments configured (Development, Production)
- Organization ID and Environment IDs

### 3. Source Control
- Git repository with MuleSoft application code
- Code repository connector configured in Harness

## Required Harness Secrets

Create the following secrets in your Harness project:

### Anypoint Platform Credentials
```
Secret Name: anypoint_username
Type: Text
Value: Your Anypoint Platform username/email

Secret Name: anypoint_password
Type: Text
Value: Your Anypoint Platform password

Secret Name: anypoint_org_id
Type: Text
Value: Your Anypoint Organization ID

Secret Name: anypoint_dev_env_id
Type: Text
Value: Development Environment ID

Secret Name: anypoint_prod_env_id
Type: Text
Value: Production Environment ID
```

### Encryption Keys
```
Secret Name: mule_encryption_key
Type: Text
Value: Encryption key for dev environment

Secret Name: mule_encryption_key_prod
Type: Text
Value: Encryption key for production environment
```

## How to Find Your Anypoint Platform IDs

### Organization ID
1. Log in to Anypoint Platform
2. Click on your profile icon (top right)
3. Go to "Organization"
4. Copy the Organization ID from the URL or page

### Environment IDs
1. In Anypoint Platform, go to "Access Management"
2. Click on "Environments"
3. Click on each environment (Dev, Prod)
4. Copy the Environment ID from the URL

## Pipeline Configuration

### Stage 1: Build MuleSoft Application
- Clones your repository
- Runs Maven build with `mvn clean package`
- Executes MUnit tests
- Publishes artifact

**Required Inputs:**
- Connector Reference: Your Docker connector for build images
- Maven cache is enabled for faster builds

### Stage 2: Deploy to Development
- Authenticates with Anypoint Platform
- Deploys or updates application in CloudHub 2.0
- Monitors deployment status
- Performs health check

**Required Variables:**
- `environment`: CloudHub 2.0 environment name (e.g., "dev")
- `app_name`: Your application name (must be unique)
- `region`: CloudHub 2.0 region
- `replicas`: Number of replicas (1 for dev)
- `vcores`: vCores per replica (0.1-4)
- `groupId`: Maven groupId
- `artifactId`: Maven artifactId
- `version`: Application version

### Stage 3: Deploy to Production
- Requires manual approval
- Deploys to production environment
- Uses higher replica count for HA
- Comprehensive health checks
- Sends deployment notification

**Recommended Production Settings:**
- `replicas`: 2 or more
- `vcores`: 1 or higher
- Approval required before deployment

## MuleSoft Application Structure

Your MuleSoft application should have the following structure:

```
my-mulesoft-app/
├── src/
│   ├── main/
│   │   ├── mule/
│   │   │   └── implementation.xml
│   │   └── resources/
│   │       ├── properties/
│   │       │   ├── dev.yaml
│   │       │   └── prod.yaml
│   │       └── application-types/
│   └── test/
│       └── munit/
│           └── test-suite.xml
├── pom.xml
└── mule-artifact.json
```

### Sample pom.xml Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.mycompany</groupId>
    <artifactId>my-mulesoft-app</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>mule-application</packaging>

    <name>My MuleSoft Application</name>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <mule.version>4.6.0</mule.version>
        <munit.version>3.1.0</munit.version>
    </properties>

    <build>
        <plugins>
            <plugin>
                <groupId>org.mule.tools.maven</groupId>
                <artifactId>mule-maven-plugin</artifactId>
                <version>4.1.0</version>
                <extensions>true</extensions>
                <configuration>
                    <cloudHubDeployment>
                        <uri>https://anypoint.mulesoft.com</uri>
                        <muleVersion>4.6.0</muleVersion>
                        <applicationName>${app.name}</applicationName>
                        <environment>${env}</environment>
                        <region>${region}</region>
                        <workers>1</workers>
                        <workerSize>0.1</workerSize>
                    </cloudHubDeployment>
                </configuration>
            </plugin>
            <plugin>
                <groupId>com.mulesoft.munit.tools</groupId>
                <artifactId>munit-maven-plugin</artifactId>
                <version>${munit.version}</version>
                <executions>
                    <execution>
                        <id>test</id>
                        <phase>test</phase>
                        <goals>
                            <goal>test</goal>
                            <goal>coverage-report</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>

    <dependencies>
        <dependency>
            <groupId>org.mule.connectors</groupId>
            <artifactId>mule-http-connector</artifactId>
            <version>1.9.0</version>
            <classifier>mule-plugin</classifier>
        </dependency>
        <dependency>
            <groupId>com.mulesoft.munit</groupId>
            <artifactId>munit-runner</artifactId>
            <version>${munit.version}</version>
            <classifier>mule-plugin</classifier>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <repositories>
        <repository>
            <id>anypoint-exchange-v3</id>
            <name>Anypoint Exchange</name>
            <url>https://maven.anypoint.mulesoft.com/api/v3/maven</url>
            <snapshots>
                <enabled>true</enabled>
            </snapshots>
        </repository>
        <repository>
            <id>mulesoft-releases</id>
            <name>MuleSoft Releases Repository</name>
            <url>https://repository.mulesoft.org/releases/</url>
        </repository>
    </repositories>

    <pluginRepositories>
        <pluginRepository>
            <id>mulesoft-releases</id>
            <name>MuleSoft Releases Repository</name>
            <url>https://repository.mulesoft.org/releases/</url>
        </pluginRepository>
    </pluginRepositories>
</project>
```

### Sample mule-artifact.json

```json
{
  "minMuleVersion": "4.6.0",
  "requiredProduct": "MULE_EE",
  "classLoaderModelLoaderDescriptor": {
    "id": "mule",
    "attributes": {
      "exportedResources": []
    }
  },
  "bundleDescriptorLoader": {
    "id": "mule",
    "attributes": {}
  }
}
```

## CloudHub 2.0 Regions

Available regions:
- `us-east-1` - US East (N. Virginia)
- `us-east-2` - US East (Ohio)
- `us-west-2` - US West (Oregon)
- `eu-central-1` - Europe (Frankfurt)
- `ap-southeast-1` - Asia Pacific (Singapore)
- `ap-southeast-2` - Asia Pacific (Sydney)

## vCore Sizing Guide

| vCores | CPU | Memory | Use Case |
|--------|-----|--------|----------|
| 0.1    | 100m | 1 GB   | Development/Testing |
| 0.2    | 200m | 2 GB   | Small workloads |
| 0.5    | 500m | 4 GB   | Light production |
| 1.0    | 1000m | 8 GB  | Standard production |
| 1.5    | 1500m | 12 GB | Medium workloads |
| 2.0    | 2000m | 16 GB | Heavy workloads |

## Health Check Endpoint

Your MuleSoft application should expose a health check endpoint:

```xml
<http:listener-config name="HTTP_Listener_config">
    <http:listener-connection host="0.0.0.0" port="8081" />
</http:listener-config>

<flow name="health-check-flow">
    <http:listener config-ref="HTTP_Listener_config" path="/health"/>
    <set-payload value='{"status": "UP"}' />
</flow>
```

## Running the Pipeline

### Option 1: Manual Trigger
1. Go to Harness UI
2. Navigate to Pipelines
3. Select "MuleSoft CloudHub 2.0 Deployment"
4. Click "Run"
5. Provide required inputs
6. Execute

### Option 2: Git Trigger
Add a trigger to run on Git push:
```yaml
triggers:
  - name: On Push to Main
    identifier: on_push_main
    enabled: true
    source:
      type: Webhook
      spec:
        type: Github
        spec:
          type: Push
          spec:
            connectorRef: <your_github_connector>
            autoAbortPreviousExecutions: true
            payloadConditions:
              - key: targetBranch
                operator: Equals
                value: main
```

## Troubleshooting

### Build Failures
- Check Maven dependencies in pom.xml
- Verify MuleSoft credentials in settings.xml
- Review build logs for compilation errors

### Deployment Failures
- Verify Anypoint Platform credentials
- Check Environment IDs are correct
- Ensure application name is unique
- Verify vCore quota is available

### Health Check Failures
- Confirm health endpoint is implemented
- Check application logs in Anypoint Platform
- Verify application is fully started

## Best Practices

1. **Version Control**: Use semantic versioning (e.g., 1.0.0)
2. **Environment Properties**: Use separate property files for each environment
3. **Secrets Management**: Never commit credentials to Git
4. **Testing**: Always run MUnit tests before deployment
5. **Monitoring**: Set up CloudHub alerts and logging
6. **High Availability**: Use 2+ replicas in production
7. **Blue-Green Deployment**: Consider implementing for zero-downtime

## Additional Resources

- [MuleSoft CloudHub 2.0 Documentation](https://docs.mulesoft.com/cloudhub-2/)
- [Anypoint Platform REST APIs](https://anypoint.mulesoft.com/exchange/portals/anypoint-platform/)
- [Harness Documentation](https://docs.harness.io/)

## Support

For issues or questions:
1. Check Harness execution logs
2. Review CloudHub 2.0 application logs
3. Contact your DevOps team
4. Reach out to MuleSoft support if needed


# Sample Environment Configuration Files for MuleSoft Application

## File: src/main/resources/properties/dev.yaml

```yaml
# Development Environment Configuration

# HTTP Configuration
http:
  host: "0.0.0.0"
  port: "8081"
  basePath: "/api"

# Anypoint Platform
anypoint:
  environment: "Development"
  
# Application Settings
app:
  name: "my-mulesoft-app-dev"
  version: "${project.version}"
  
# Database Configuration (example)
database:
  host: "dev-db.example.com"
  port: "3306"
  name: "dev_database"
  username: "dev_user"
  password: "${secure::db.password}"
  
# External API Configuration
external:
  api:
    baseUrl: "https://dev-api.example.com"
    timeout: "30000"
    apiKey: "${secure::external.api.key}"
    
# Logging
logging:
  level: "DEBUG"
  
# Rate Limiting
ratelimit:
  requests: "1000"
  period: "60000"
  
# Retry Policy
retry:
  maxAttempts: "3"
  initialDelay: "1000"
  multiplier: "2"
```

## File: src/main/resources/properties/prod.yaml

```yaml
# Production Environment Configuration

# HTTP Configuration
http:
  host: "0.0.0.0"
  port: "8081"
  basePath: "/api"

# Anypoint Platform
anypoint:
  environment: "Production"
  
# Application Settings
app:
  name: "my-mulesoft-app-prod"
  version: "${project.version}"
  
# Database Configuration (example)
database:
  host: "prod-db.example.com"
  port: "3306"
  name: "prod_database"
  username: "prod_user"
  password: "${secure::db.password.prod}"
  
# External API Configuration
external:
  api:
    baseUrl: "https://api.example.com"
    timeout: "30000"
    apiKey: "${secure::external.api.key.prod}"
    
# Logging
logging:
  level: "INFO"
  
# Rate Limiting
ratelimit:
  requests: "10000"
  period: "60000"
  
# Retry Policy
retry:
  maxAttempts: "5"
  initialDelay: "2000"
  multiplier: "2"
```

## Usage in Mule Configuration

### Example: Using properties in your Mule flow

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mule xmlns="http://www.mulesoft.org/schema/mule/core"
      xmlns:http="http://www.mulesoft.org/schema/mule/http"
      xmlns:db="http://www.mulesoft.org/schema/mule/db"
      xmlns:doc="http://www.mulesoft.org/schema/mule/documentation"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.mulesoft.org/schema/mule/core 
                          http://www.mulesoft.org/schema/mule/core/current/mule.xsd
                          http://www.mulesoft.org/schema/mule/http 
                          http://www.mulesoft.org/schema/mule/http/current/mule-http.xsd
                          http://www.mulesoft.org/schema/mule/db 
                          http://www.mulesoft.org/schema/mule/db/current/mule-db.xsd">

    <!-- Configuration Properties -->
    <configuration-properties file="properties/${env}.yaml" />

    <!-- HTTP Listener Configuration -->
    <http:listener-config name="HTTP_Listener_config" doc:name="HTTP Listener config">
        <http:listener-connection host="${http.host}" port="${http.port}" />
    </http:listener-config>

    <!-- Database Configuration -->
    <db:config name="Database_Config" doc:name="Database Config">
        <db:my-sql-connection 
            host="${database.host}" 
            port="${database.port}" 
            user="${database.username}" 
            password="${database.password}" 
            database="${database.name}" />
    </db:config>

    <!-- HTTP Request Configuration for External API -->
    <http:request-config name="External_API_Config" doc:name="External API Config">
        <http:request-connection host="${external.api.baseUrl}" />
    </http:request-config>

    <!-- Health Check Flow -->
    <flow name="health-check-flow" doc:name="health-check-flow">
        <http:listener 
            config-ref="HTTP_Listener_config" 
            path="/health"
            doc:name="Health Check Listener"/>
        <set-payload 
            value='#[output application/json --- { "status": "UP", "application": "${app.name}", "version": "${app.version}", "environment": "${anypoint.environment}" }]'
            doc:name="Set Health Response"/>
    </flow>

    <!-- Main API Flow -->
    <flow name="main-api-flow" doc:name="main-api-flow">
        <http:listener 
            config-ref="HTTP_Listener_config" 
            path="${http.basePath}/*"
            doc:name="API Listener"/>
        
        <logger 
            level="${logging.level}" 
            message="Received request: #[attributes.requestPath]"
            doc:name="Log Request"/>
        
        <!-- Your API logic here -->
        
    </flow>

</mule>
```

## Environment Variable Override

You can override properties using environment variables in CloudHub 2.0:

### In the deployment script, add environment-specific properties:

```json
{
  "application": {
    "configuration": {
      "mule.agent.application.properties.service": {
        "properties": {
          "env": "prod",
          "encryption.key": "${ENCRYPTION_KEY}",
          "database.password": "${DB_PASSWORD}",
          "external.api.key": "${API_KEY}",
          "http.port": "8081"
        }
      }
    }
  }
}
```

## Secure Properties

For sensitive data, use Mule's secure properties:

### Create a secure properties file:

```properties
# File: src/main/resources/secure.properties
db.password=![encrypted_value_here]
external.api.key=![encrypted_value_here]
```

### Reference in your configuration:

```xml
<secure-properties:config 
    name="Secure_Properties_Config" 
    file="secure.properties" 
    key="${encryption.key}"
    doc:name="Secure Properties Config">
    <secure-properties:encrypt algorithm="Blowfish" />
</secure-properties:config>
```

## CloudHub 2.0 Deployment Properties

When deploying via the pipeline, these properties are automatically set:

- `cloudhub.environment`: The environment name
- `cloudhub.application.name`: Your application name
- `cloudhub.region`: The deployment region
- `cloudhub.worker.count`: Number of workers/replicas

## Best Practices

1. **Never commit secrets**: Use secure properties or Harness secrets
2. **Environment-specific files**: Maintain separate configs for each environment
3. **Default values**: Always provide sensible defaults
4. **Documentation**: Document all configuration properties
5. **Validation**: Validate critical properties at startup
6. **Externalization**: Keep configuration outside the code where possible
