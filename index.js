const express = require('express');
const { ApolloServer } = require('apollo-server-express');
const { ApolloGateway, RemoteGraphQLDataSource } = require('@apollo/gateway');
const jwt = require('express-jwt');
require('dotenv').config();

const { getSecretFromEnv } = require('./secret.js');

const port = process.env.PORT || 4000;
const app = express();

const jwtSecret = getSecretFromEnv('JWT_SECRET_KEY');

const isTokenRevokedCallback = (req, payload, done) => {
  const issuer = payload.iss;
  const tokenId = payload.jti;

  return done(null);
};

const corsOptions = {
  origin: [
    process.env.ALLOWED_ORIGIN,
  ],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'client-name',
    'client-version',
  ],
  optionsSuccessStatus: 200,
  credentials: true,
  maxAge: 600,
};

app.use(jwt({
  secret: jwtSecret,
  credentialsRequired: false,
  algorithms: ['HS384'],
  isRevoked: isTokenRevokedCallback,
}));

app.get('/health', (req, res) => {
  res.status(200);
  res.end();
});

const gateway = new ApolloGateway({
  serviceList: [
    { name: 'User', url: process.env.USER_SERVICE_ADDR },
    // { name: 'Invoicing', url: process.env.INVOICING_SERVICE_ADDR },
  ],
  buildService({ url }) {
    return new RemoteGraphQLDataSource({
      url,
      apq: true,
      willSendRequest({ request, context }) {
        request.http.headers.set(
          'Authorization',
          context.token,
        );
        request.http.headers.set(
          'User',
          JSON.stringify(context.user),
        );
      },
    });
  },
});

(async () => {
  const { schema, executor } = await gateway.load();

  const server = new ApolloServer({
    schema,
    executor,
    tracing: true,
    subscriptions: false,
    context: ({ req }) => {
      const token = req.headers.authorization || '';
      const { user } = req;
      return {
        token,
        user,
      };
    },
  });

  server.applyMiddleware({ app, cors: corsOptions });

  app.listen({
    port,
  }, () => {
    console.log(`Server ready at http://*:${port}${server.graphqlPath}`);
  });
})();
