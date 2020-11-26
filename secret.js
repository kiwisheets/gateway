const fs = require('fs');

const canGetEnv = (env, defaultEnv) => {
  const v = process.env[env];
  if (v === undefined || v === null || v === '') {
    return defaultEnv;
  }
  return v;
};

const mustGetEnv = (env) => {
  const v = process.env[env];
  if (v === undefined || v === null || v === '') {
    console.error(`ENV missing, key: ${env}`);
    process.exit(1);
  }
  return v;
};

const getSecretFromFile = (file) => {
  const secret = fs.readFileSync(file);
  if (secret === undefined || secret === null || secret === '') {
    console.error(`Secret missing: ${file}`);
    process.exit(1);
  }
  return secret;
};

const getSecretFromEnv = (env) => {
  const fileEnvTag = `${env}_FILE`;

  const secret = canGetEnv(env, fileEnvTag);

  if (secret === fileEnvTag) {
    return getSecretFromFile(mustGetEnv(fileEnvTag));
  }

  return secret;
};

module.exports = {
  canGetEnv,
  mustGetEnv,
  getSecretFromEnv,
  getSecretFromFile,
};
