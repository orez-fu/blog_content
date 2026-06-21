export const handler = async (event) => {
  const response = {
    service: "vpn-lambda-demo",
    status: "healthy",
    message: "Request reached Lambda through the internal ALB",
    path: event.path ?? "/",
    timestamp: new Date().toISOString(),
  };

  return {
    statusCode: 200,
    statusDescription: "200 OK",
    isBase64Encoded: false,
    headers: {
      "content-type": "application/json; charset=utf-8",
    },
    body: JSON.stringify(response),
  };
};
