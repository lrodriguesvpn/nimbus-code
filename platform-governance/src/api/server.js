const { startGovernanceServer } = require('../runtime/platform-governance');

function start(port = process.env.PORT || 3000) {
  const { server } = startGovernanceServer({});
  return new Promise((resolve) => {
    server.listen(port, () => resolve(server));
  });
}

if (require.main === module) {
  start().then((server) => {
    const address = server.address();
    const value = typeof address === 'string' ? address : address.port;
    console.log(`Platform Governance API listening on ${value}`);
  });
}

module.exports = { start };
