
const { ethers } = require("hardhat");

async function main() {
  const accounts = await ethers.getSigners();

  const admin = accounts[0];
  const issuer = accounts[1];
  const registrar = accounts[2];
  const compliance = accounts[3];
  const schemeAdmin = accounts[4];

  console.log("Deploying PurposePay contracts...");

  const RupeeToken = await ethers.getContractFactory("RupeeToken");
  const token = await RupeeToken.deploy(
    admin.address,
    issuer.address
  );
  await token.waitForDeployment();

  console.log("RupeeToken:", await token.getAddress());

  const ParticipantRegistry =
    await ethers.getContractFactory("ParticipantRegistry");

  const registry = await ParticipantRegistry.deploy(
    admin.address,
    registrar.address,
    compliance.address
  );
  await registry.waitForDeployment();

  console.log("ParticipantRegistry:", await registry.getAddress());

  const WelfareVault =
    await ethers.getContractFactory("WelfareVault");

  const vault = await WelfareVault.deploy(
    await token.getAddress(),
    await registry.getAddress(),
    admin.address,
    schemeAdmin.address,
    compliance.address
  );
  await vault.waitForDeployment();

  console.log("WelfareVault:", await vault.getAddress());

  console.log("\nPurposePay deployment successful!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
