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
