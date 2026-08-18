const fs = require('node:fs');
const path = require('node:path');

const ALLOWED_PROVIDERS = new Set(['azure', 'aws', 'gcp']);
const SCOPE_FILE = path.resolve(__dirname, '../../../.state/execution-scope.json');

function parseProviders(value) {
  const providers = String(value || '')
    .split(',')
    .map((item) => item.trim().toLowerCase())
    .filter(Boolean);
  if (providers.length === 0) {
    throw new Error('providers list is empty');
  }
  const unique = [...new Set(providers)];
  for (const provider of unique) {
    if (!ALLOWED_PROVIDERS.has(provider)) {
      throw new Error(`unsupported provider: ${provider}`);
    }
  }
  return unique;
}

function getArgValue(argv, name) {
  const index = argv.findIndex((item) => item === name);
  if (index === -1 || index + 1 >= argv.length) {
    return null;
  }
  return argv[index + 1];
}

function loadScope() {
  if (!fs.existsSync(SCOPE_FILE)) {
    return null;
  }
  return JSON.parse(fs.readFileSync(SCOPE_FILE, 'utf8'));
}

function saveScope(scope) {
  fs.mkdirSync(path.dirname(SCOPE_FILE), { recursive: true });
  fs.writeFileSync(SCOPE_FILE, `${JSON.stringify(scope, null, 2)}\n`, 'utf8');
  return scope;
}

function initializeScope(argv = [], env = process.env) {
  const providersArg = getArgValue(argv, '--providers') || env.INITIAL_PROVIDERS || env.SUPPORTED_PROVIDERS || 'azure';
  const tenantId = getArgValue(argv, '--tenant') || env.TENANT_ID || 'tenant-1';
  const scope = {
    tenantId,
    targetPlatforms: parseProviders(providersArg),
    initializedAt: new Date().toISOString(),
  };
  return saveScope(scope);
}

function resolveScope(argv = [], env = process.env) {
  const providersArg = getArgValue(argv, '--providers');
  if (providersArg) {
    return {
      tenantId: getArgValue(argv, '--tenant') || env.TENANT_ID || 'tenant-1',
      targetPlatforms: parseProviders(providersArg),
    };
  }
  const stored = loadScope();
  if (stored && Array.isArray(stored.targetPlatforms) && stored.targetPlatforms.length > 0) {
    return {
      tenantId: stored.tenantId || env.TENANT_ID || 'tenant-1',
      targetPlatforms: stored.targetPlatforms,
    };
  }
  return initializeScope(argv, env);
}

module.exports = {
  initializeScope,
  resolveScope,
  parseProviders,
};
