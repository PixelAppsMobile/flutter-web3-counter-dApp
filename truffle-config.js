module.exports = {
  contracts_build_directory: './src/contracts',
  networks: {
    development: {
      host: "0.0.0.0",
      port: 7545,
      network_id: "*",
    },
    advanced: {
      websocket: true
    },
  },
  compilers: {
    solc: {
      version: "0.8.14",
      settings: {
        optimizer: {
          enabled: false,
          runs: 200
        },
        evmVersion: "byzantium"
      }
    }
  },
};
