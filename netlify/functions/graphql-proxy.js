// GraphQL Proxy Function
// Proxies requests to your backend GraphQL API
// Access at: /.netlify/functions/graphql-proxy

const fetch = require('node-fetch');

exports.handler = async (event, context) => {
  // Only allow POST requests
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  const BACKEND_URL = process.env.BACKEND_GRAPHQL_URL || 'http://localhost:8080/graphql';

  try {
    const response = await fetch(BACKEND_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...event.headers,
      },
      body: event.body,
    });

    const data = await response.text();

    return {
      statusCode: response.status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
      body: data,
    };
  } catch (error) {
    console.error('GraphQL proxy error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Failed to proxy request to backend',
        message: error.message,
      }),
    };
  }
};
