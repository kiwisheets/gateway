const express = require('express');
const { ApolloServer } = require('apollo-server-express');
const { ApolloGateway, RemoteGraphQLDataSource } = require('@apollo/gateway');
const jwt = require('express-jwt');
const cors = require('cors');
require('dotenv').config();

const port = 4000;
const app = express();

const jwtSecret = process.env.JWT_SECRET_KEY;
if (jwtSecret === undefined || jwtSecret === null || jwtSecret === '') {
  console.error('ENV JWT_SECRET_KEY not defined');
  process.exit(1);
}

const isTokenRevokedCallback = (req, payload, done) => {
  const issuer = payload.iss;
  const tokenId = payload.jti;

  return done(null);
};

const corsOptions = {
  origin: [
    'http://localhost:3000',

  ],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'client-name',
    'client-version',
  ],
  optionsSuccessStatus: 200,
  credentials: true,
};

app.use(jwt({
  secret: jwtSecret,
  credentialsRequired: false,
  algorithms: ['HS384'],
  isRevoked: isTokenRevokedCallback,
}));

const gateway = new ApolloGateway({
  serviceList: [
    { name: 'User', url: 'http://localhost:5000/graphql' },
    { name: 'Invoicing', url: 'http://localhost:5001/graphql' },
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
