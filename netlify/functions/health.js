// Health Check Function
// Access at: /.netlify/functions/health

exports.handler = async (event, context) => {
  const BACKEND_URL = process.env.BACKEND_GRAPHQL_URL;

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      status: 'healthy',
      service: 'egg-shop-frontend',
      timestamp: new Date().toISOString(),
      backend: BACKEND_URL || 'not configured',
      environment: process.env.CONTEXT || 'unknown',
    }),
  };
};
