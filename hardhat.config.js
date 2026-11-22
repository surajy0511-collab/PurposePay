require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomicfoundation/hardhat-network-helpers");
const { subtask } = require("hardhat/config");
const { TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD } = require("hardhat/builtin-tasks/task-names");

// Compile with the solc-js compiler that ships inside the npm package "solc".
// This avoids a download from binaries.soliditylang.org, so `npm install && npm test`
// works on locked-down networks as well as on a normal laptop.
const solcPkg = require("solc/package.json");
subtask(TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD, async (args, hre, runSuper) => {
  if (args.solcVersion === solcPkg.version) {
    return {
      compilerPath: require.resolve("solc/soljson.js"),
      isSolcJs: true,
      version: solcPkg.version,
      longVersion: require("solc").version().replace(/\.Emscripten.*$/, ""),
    };
  }
  return runSuper();
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: solcPkg.version, // 0.8.28
    settings: { optimizer: { enabled: true, runs: 200 }, evmVersion: "cancun" },
  },
  networks: {
    hardhat: { chainId: 31337, hardfork: "cancun" },
    localhost: { url: "http://127.0.0.1:8545", chainId: 31337 },
  },
  paths: { sources: "./contracts", tests: "./test", artifacts: "./artifacts", cache: "./cache" },
  mocha: { timeout: 120000 },
};
