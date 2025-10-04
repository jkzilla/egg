# Netlify Functions

This directory contains serverless functions that run on Netlify's edge network.

## Available Functions

### 1. Hello Function (`hello.js`)

Simple example function to test Netlify Functions setup.

**Endpoint:** `/.netlify/functions/hello`

**Example:**
```bash
curl https://your-site.netlify.app/.netlify/functions/hello
```

**Response:**
```json
{
  "message": "Hello from Netlify Functions!",
  "timestamp": "2025-10-04T23:33:40.000Z"
}
```

### 2. GraphQL Proxy (`graphql-proxy.js`)

Proxies GraphQL requests to your backend API. Useful for:
- Hiding backend URL from client
- Adding authentication headers
- Rate limiting
- Request logging

**Endpoint:** `/.netlify/functions/graphql-proxy`

**Setup:**
```bash
# Set backend URL in Netlify
netlify env:set BACKEND_GRAPHQL_URL "https://your-backend.com/graphql"
```

**Usage in Frontend:**
```typescript
// Update frontend/src/main.tsx
const client = new ApolloClient({
  uri: '/.netlify/functions/graphql-proxy',  // Use proxy instead of direct backend
  cache: new InMemoryCache(),
})
```

**Example:**
```bash
curl -X POST https://your-site.netlify.app/.netlify/functions/graphql-proxy \
  -H "Content-Type: application/json" \
  -d '{"query":"{ eggs { id type price } }"}'
```

### 3. Health Check (`health.js`)

Returns service health status and configuration info.

**Endpoint:** `/.netlify/functions/health`

**Example:**
```bash
curl https://your-site.netlify.app/.netlify/functions/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "egg-shop-frontend",
  "timestamp": "2025-10-04T23:33:40.000Z",
  "backend": "https://your-backend.com/graphql",
  "environment": "production"
}
```

## Local Development

### Install Netlify CLI

```bash
npm install -g netlify-cli
```

### Run Functions Locally

```bash
# From project root
netlify dev

# Functions available at:
# http://localhost:8888/.netlify/functions/hello
# http://localhost:8888/.netlify/functions/graphql-proxy
# http://localhost:8888/.netlify/functions/health
```

### Test Functions

```bash
# Test hello function
curl http://localhost:8888/.netlify/functions/hello

# Test GraphQL proxy
curl -X POST http://localhost:8888/.netlify/functions/graphql-proxy \
  -H "Content-Type: application/json" \
  -d '{"query":"{ eggs { id } }"}'

# Test health check
curl http://localhost:8888/.netlify/functions/health
```

## Creating New Functions

### Basic Function Template

```javascript
// netlify/functions/my-function.js
exports.handler = async (event, context) => {
  // event.httpMethod - GET, POST, etc.
  // event.body - Request body
  // event.headers - Request headers
  // event.queryStringParameters - Query params

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: 'Success',
    }),
  };
};
```

### Function with Environment Variables

```javascript
exports.handler = async (event, context) => {
  const apiKey = process.env.MY_API_KEY;

  return {
    statusCode: 200,
    body: JSON.stringify({ apiKey: apiKey ? 'Set' : 'Not set' }),
  };
};
```

### Function with External Dependencies

```bash
# Create package.json in functions directory
cd netlify/functions
npm init -y
npm install axios
```

```javascript
// netlify/functions/fetch-data.js
const axios = require('axios');

exports.handler = async (event, context) => {
  try {
    const response = await axios.get('https://api.example.com/data');
    return {
      statusCode: 200,
      body: JSON.stringify(response.data),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
```

## Environment Variables

Set environment variables in Netlify:

```bash
# Via CLI
netlify env:set BACKEND_GRAPHQL_URL "https://backend.com/graphql"
netlify env:set MY_API_KEY "secret-key"

# Via Netlify UI
# Site settings → Environment variables → Add variable
```

## Function Limits

### Free Tier
- 125,000 requests/month
- 100 hours runtime/month
- 10 second timeout
- 1024 MB memory

### Pro Tier
- 2,000,000 requests/month
- 1,000 hours runtime/month
- 26 second timeout
- 3008 MB memory

## Common Use Cases

### 1. API Proxy (Hide Backend URL)

```javascript
// Proxy all API requests through Netlify
exports.handler = async (event) => {
  const response = await fetch(process.env.BACKEND_URL + event.path, {
    method: event.httpMethod,
    headers: event.headers,
    body: event.body,
  });
  return {
    statusCode: response.status,
    body: await response.text(),
  };
};
```

### 2. Authentication

```javascript
// Add authentication to requests
exports.handler = async (event) => {
  const token = event.headers.authorization;

  if (!token) {
    return { statusCode: 401, body: 'Unauthorized' };
  }

  // Verify token and proxy request
  // ...
};
```

### 3. Rate Limiting

```javascript
// Simple rate limiting
const requests = new Map();

exports.handler = async (event) => {
  const ip = event.headers['x-nf-client-connection-ip'];
  const count = requests.get(ip) || 0;

  if (count > 100) {
    return { statusCode: 429, body: 'Too many requests' };
  }

  requests.set(ip, count + 1);
  // Handle request...
};
```

### 4. Form Submission

```javascript
// Handle form submissions
exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  const data = JSON.parse(event.body);

  // Send email, save to database, etc.
  // ...

  return {
    statusCode: 200,
    body: JSON.stringify({ success: true }),
  };
};
```

## Debugging

### View Function Logs

```bash
# Real-time logs
netlify functions:log

# Or view in Netlify UI
# Functions tab → Select function → View logs
```

### Common Issues

**Function not found:**
- Check `netlify.toml` functions directory path
- Ensure function file exports `handler`
- Redeploy site

**Timeout errors:**
- Optimize function code
- Use async/await properly
- Consider background functions for long tasks

**Environment variables not working:**
- Verify variables are set in Netlify
- Redeploy after setting new variables
- Check variable names (case-sensitive)

## Resources

- [Netlify Functions Docs](https://docs.netlify.com/functions/overview/)
- [Function Examples](https://functions.netlify.com/examples/)
- [Netlify CLI Docs](https://docs.netlify.com/cli/get-started/)

## Next Steps

1. Test functions locally with `netlify dev`
2. Deploy to Netlify
3. Test functions in production
4. Monitor function logs and usage
5. Add custom functions as needed
