

module.exports = {
  networks: {
   development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id 
      gas: 3500000,
    }, 
   ropsten: {
      host: 'localhost',
      port: 8545,
      from: "0x009393Ff2AF09d7D8e6496989Be6882e1968EA6d",
      network_id: '3', // Match any network id
      gas: 3000000,
      gasPrice: 50000000000
    },
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
