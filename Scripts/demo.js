
const { ethers } = require("hardhat");

async function main() {
  const accounts = await ethers.getSigners();

  const admin = accounts[0];
  const issuer = accounts[1];
  const registrar = accounts[2];
  const compliance = accounts[3];
  const schemeAdmin = accounts[4];
  const beneficiary = accounts[5];
  const merchant = accounts[6];

  // Connect to deployed contracts
  const token = await ethers.getContractAt(
    "RupeeToken",
    "0x5FbDB2315678afecb367f032d93F642f64180aa3"
  );

  const registry = await ethers.getContractAt(
    "ParticipantRegistry",
    "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
  );

  const vault = await ethers.getContractAt(
    "WelfareVault",
    "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
  );

  console.log("\n--- PURPOSEPAY LIVE DEMONSTRATION ---");

  // 1. Register beneficiary
  const idHash = ethers.id("DEMO-BENEFICIARY-001");

  await (await registry.connect(registrar)
    .registerBeneficiary(beneficiary.address, idHash)).wait();

  console.log("1. Beneficiary registered:", beneficiary.address);

  // 2. Register merchant for FOOD_GRAIN (category 0)
  const licenceHash = ethers.id("DEMO-MERCHANT-LICENCE");

  await (await registry.connect(registrar)
    .registerMerchant(
      merchant.address,
      "PurposePay Demo Grocery",
      1,
      licenceHash
    )).wait();

  console.log("2. Merchant registered:", merchant.address);

  // 3. Create welfare scheme
  const latestBlock = await ethers.provider.getBlock("latest");
  const expiry = latestBlock.timestamp + 7 * 24 * 60 * 60;

  await (await vault.connect(schemeAdmin).createScheme(
    "Food Security Scheme",
    0,
    0,
    expiry,
    5000
  )).wait();

  const schemeId = await vault.schemeCount();

  console.log("3. Welfare scheme created. ID:", schemeId.toString());

  // 4. Issue 10,000 simulated paise (Rs. 100)
  const allocationAmount = 10000n;

  await (await token.connect(issuer).issue(
    schemeAdmin.address,
    allocationAmount,
    ethers.id("DEMO-ISSUANCE-001")
  )).wait();

  console.log("4. Rs. 100 simulated digital rupees issued");

  // 5. Fund welfare scheme
  await (await token.connect(schemeAdmin).approve(
    await vault.getAddress(),
    allocationAmount
  )).wait();

  await (await vault.connect(schemeAdmin).fundScheme(
    schemeId,
    allocationAmount
  )).wait();

  console.log("5. Welfare scheme funded with Rs. 100");

  // 6. Allocate Rs. 100 to beneficiary
  await (await vault.connect(schemeAdmin).allocate(
    schemeId,
    beneficiary.address,
    allocationAmount
  )).wait();

  console.log("6. Rs. 100 allocated to beneficiary");

  // 7. Beneficiary spends Rs. 25 at approved merchant
  const paymentAmount = 2500n;

  await (await vault.connect(beneficiary).spend(
    schemeId,
    merchant.address,
    paymentAmount,
    ethers.id("INVOICE-001")
  )).wait();

  console.log("7. Payment of Rs. 25 successful");

  // 8. Verify balances and accounting
  const remaining = await vault.entitlementOf(
    schemeId,
    beneficiary.address
  );

  const merchantBalance = await token.balanceOf(merchant.address);
  const solvent = await vault.isSolvent();

  console.log("\n--- FINAL RESULTS ---");
  console.log("Beneficiary remaining: Rs.", ethers.formatUnits(remaining, 2));
  console.log("Merchant received: Rs.", ethers.formatUnits(merchantBalance, 2));
  console.log("Vault solvent:", solvent);
  console.log("PurposePay demonstration completed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

