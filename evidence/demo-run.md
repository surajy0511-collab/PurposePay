# PurposePay demo run - on-chain evidence

Generated: 2026-11-21T11:03:03.055Z on network `hardhat` (local Hardhat chain; hashes are real for this run only).

| # | Step | Actor | Function | Result | Tx hash | Block | Gas |
|---|---|---|---|---|---|---|---|
| 1 | Register beneficiary Ravi Kumar (salted ID hash only) | Registrar | registerBeneficiary | SUCCESS | `0x7c4ef7307f59c38345798ad478c88c1575a880c4422115a274dd78fba8790e2d` | 4 | 137687 |
| 2 | Register beneficiary Meena Devi | Registrar | registerBeneficiary | SUCCESS | `0x2875c8fa03a0f0de9ccd4239281dabc32538e3c61286a2e93e2545a9404d56e2` | 5 | 120587 |
| 3 | Register merchant Sri Lakshmi Ration Store (FOOD_GRAIN + FERTILISER) | Registrar | registerMerchant | SUCCESS | `0x8c35b5f1331f46a8f4f7543fcab5a922c981ecc7fe6037cd2704ff509052319f` | 6 | 140435 |
| 4 | Register merchant Jan Aushadhi Kendra (HEALTHCARE) | Registrar | registerMerchant | SUCCESS | `0x0a12dfe70fffb3303f8f489c33d4cf05c742f4d2c6288b5bb5a47f182901ab56` | 7 | 123263 |
| 5 | Duplicate identity: same person tries a second wallet | Registrar | registerBeneficiary | REJECTED: DuplicateIdentity(0x0dad4ea80e316b556c8111812d63b362426c999dbbccf770184a71c91ddf1d7b) | - | - | - |
| 6 | Central bank issues Rs 10,00,000 simulated e-rupee to the Department | Issuer | issue | SUCCESS | `0xe19042e195bfb48b3643bd70f70e2840f2c513c966feb47cd887f65424e5417f` | 9 | 73190 |
| 7 | A non-issuer tries to create money | Department | issue | REJECTED: AccessControlUnauthorizedAccount(0x90F79bf6EB2c4f870365E785982E1f101E93b906, 0x114e74f6ea3bd819998f78687bfcb11b140da08e9b7d222fa9c1f1ba1f2aa122) | - | - | - |
| 8 | Department approves the vault to pull funds | Department | approve | SUCCESS | `0x785ea9eb544ab2aaff89c0a0094d8995bdd1d03a0f0f40908d5ed6441039ac9d` | 11 | 46708 |
| 9 | Create scheme 'PDS Food Grain Relief' (FOOD_GRAIN, cap Rs 2,000, 30 days) | Department | createScheme | SUCCESS | `0xb717ebf09e491364a0ed8e5d6d1b714c5c5ef3184f5c120eab4e0140b4a72b18` | 12 | 143912 |
| 10 | Fund scheme 1 with Rs 1,00,000 | Department | fundScheme | SUCCESS | `0xf783b0fc02b91238efade8bdfacb0315e10272071cb6579f64cda145ae88a31f` | 13 | 130427 |
| 11 | Allocate Rs 5,000 to Ravi and Rs 3,000 to Meena (batch) | Department | allocateBatch | SUCCESS | `0xcab095f9852dc75dfe946ff39d27b1dd1be7ec64f3d166d2c6143cc057c560da` | 14 | 114795 |
| 12 | Allocate to an unregistered wallet | Department | allocate | REJECTED: BeneficiaryNotActive(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f) | - | - | - |
| 13 | Ravi buys rice and dal at the ration store: Rs 1,800 | Beneficiary Ravi | spend | SUCCESS | `0x76d92c3c903367444ae0db848b943754ab154ea0634d8dd9556f9f8ef20b8fd6` | 16 | 117010 |
| 14 | Purpose lock: Ravi tries to pay the pharmacy from the FOOD scheme | Beneficiary Ravi | spend | REJECTED: MerchantNotEligible(0xBcd4042DE499D14e55001CcbB24a551F3b954096, 0) | - | - | - |
| 15 | Per-transaction cap: Ravi tries Rs 2,500 | Beneficiary Ravi | spend | REJECTED: ExceedsPerTxnCap(200000, 250000) | - | - | - |
| 16 | Unregistered merchant | Beneficiary Ravi | spend | REJECTED: MerchantNotEligible(0x71bE63f3384f5fb98995898A86B02Fb2426c5788, 0) | - | - | - |
| 17 | Meena buys grain at the ration store: Rs 2,000 (exactly the cap) | Beneficiary Meena | spend | SUCCESS | `0xc540c1e0b4814e8d45d3b159e33a90e4d04c681cc28104e14faa674ec4ef6dd5` | 20 | 82810 |
| 18 | Over-entitlement: Meena has Rs 1,000 left and tries Rs 2,000 | Beneficiary Meena | spend | REJECTED: InsufficientEntitlement(100000, 200000) | - | - | - |
| 19 | Compliance freezes Meena's wallet (suspected diversion) | Compliance | setBeneficiaryFrozen | SUCCESS | `0xdd9e647b086711999db8e06eb3a46bacc4d2e0dab03a8199c3da655ede3bf870` | 22 | 31137 |
| 20 | Frozen beneficiary cannot spend | Beneficiary Meena | spend | REJECTED: BeneficiaryNotActive(0x976EA74026E726554dB657fA54763abd0C3a0aa9) | - | - | - |
| 21 | Compliance unfreezes Meena after review | Compliance | setBeneficiaryFrozen | SUCCESS | `0x4e7a22a1816abe3b413ea8da54960c979fc454ba03250801b7149713a6dd5811` | 24 | 31125 |
| 22 | Merchant redeems Rs 3,800.00 to the bank (token burned, event for bank adapter) | Merchant | redeem | SUCCESS | `0x1b652bb306f9784d8f9a926a914b0fb67f4c8c885bd8c30673d615a32b9d4b2b` | 25 | 31233 |
| 23 | Ravi tries to spend after the scheme expired | Beneficiary Ravi | spend | REJECTED: SchemeExpired() | - | - | - |
| 24 | ANYONE (here: the registrar) returns Ravi's unspent balance to the treasury | Registrar (any caller) | reclaimExpired | SUCCESS | `0xfc81e010542fbfacdab900bf1b542d5c00d4ef168cddb1e0bd0dede2dad010d6` | 28 | 79920 |
| 25 | Return Meena's unspent balance to the treasury | Registrar (any caller) | reclaimExpired | SUCCESS | `0xed5367c93a737080fe116fedc3781a25cffec88065cc78c83357b47451c6d24b` | 29 | 58020 |

## Decoded events

- **#1 registerBeneficiary**: BeneficiaryRegistered(wallet=0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, idHash=0x0dad4ea80e316b556c8111812d63b362426c999dbbccf770184a71c91ddf1d7b)
- **#2 registerBeneficiary**: BeneficiaryRegistered(wallet=0x976EA74026E726554dB657fA54763abd0C3a0aa9, idHash=0x6928eb0ea36f3a0bcdec59b6a95a2a4f0522adf2498c65be5c8b048aacf281c0)
- **#3 registerMerchant**: MerchantRegistered(merchant=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720, name=Sri Lakshmi Ration Store, categoryMask=3, licenceHash=0x99b5e8995215dc148830a138d49ea79bc5b86b3847fa5d18cb2753019d515ceb)
- **#4 registerMerchant**: MerchantRegistered(merchant=0xBcd4042DE499D14e55001CcbB24a551F3b954096, name=Jan Aushadhi Kendra, categoryMask=4, licenceHash=0x5afa3e4e7577590ab1297e32326a2a253b79841a58a71079ea9b2a77cbb6be8e)
- **#6 issue**: Transfer(from=0x0000000000000000000000000000000000000000, to=0x90F79bf6EB2c4f870365E785982E1f101E93b906, value=100000000); Issued(to=0x90F79bf6EB2c4f870365E785982E1f101E93b906, amount=100000000, ledgerRef=0x5d670a20d11c8715d0ee0178b391e9e8a8c22e2cc0beba098a3f6bf6d9c6a7a8)
- **#8 approve**: Approval(owner=0x90F79bf6EB2c4f870365E785982E1f101E93b906, spender=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, value=115792089237316195423570985008687907853269984665640564039457584007913129639935)
- **#9 createScheme**: SchemeCreated(schemeId=1, owner=0x90F79bf6EB2c4f870365E785982E1f101E93b906, name=PDS Food Grain Relief, category=0, startTime=1795258994, expiry=1797850993, perTxnCap=200000)
- **#10 fundScheme**: Transfer(from=0x90F79bf6EB2c4f870365E785982E1f101E93b906, to=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, value=10000000); SchemeFunded(schemeId=1, from=0x90F79bf6EB2c4f870365E785982E1f101E93b906, amount=10000000)
- **#11 allocateBatch**: Allocated(schemeId=1, beneficiary=0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, amount=500000); Allocated(schemeId=1, beneficiary=0x976EA74026E726554dB657fA54763abd0C3a0aa9, amount=300000)
- **#13 spend**: Transfer(from=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, to=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720, value=180000); Spent(schemeId=1, beneficiary=0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, merchant=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720, amount=180000, category=0, invoiceRef=0x92cfb0632a76449798532cc81a5fa79317b86d35c608ccf70f27d5a7b1910638)
- **#17 spend**: Transfer(from=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, to=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720, value=200000); Spent(schemeId=1, beneficiary=0x976EA74026E726554dB657fA54763abd0C3a0aa9, merchant=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720, amount=200000, category=0, invoiceRef=0xc744566f555fdbc3c7e912f236198eb6fe8e5c53b7f4181c4ee9ad7619ab8607)
- **#19 setBeneficiaryFrozen**: BeneficiaryFreezeChanged(wallet=0x976EA74026E726554dB657fA54763abd0C3a0aa9, frozen=true)
- **#21 setBeneficiaryFrozen**: BeneficiaryFreezeChanged(wallet=0x976EA74026E726554dB657fA54763abd0C3a0aa9, frozen=false)
- **#22 redeem**: Transfer(from=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720, to=0x0000000000000000000000000000000000000000, value=380000); Redeemed(from=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720, amount=380000, bankReference=0x1b36bb1492a824370ca08a8519946ec30fe525b6e3921d638944fe9795906055)
- **#24 reclaimExpired**: Transfer(from=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, to=0x90F79bf6EB2c4f870365E785982E1f101E93b906, value=320000); Reclaimed(schemeId=1, beneficiary=0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc, caller=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, amount=320000)
- **#25 reclaimExpired**: Transfer(from=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, to=0x90F79bf6EB2c4f870365E785982E1f101E93b906, value=100000); Reclaimed(schemeId=1, beneficiary=0x976EA74026E726554dB657fA54763abd0C3a0aa9, caller=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, amount=100000)

## Reconciliation

```json
{
  "network": "hardhat",
  "scheme1": {
    "funded": "10000000",
    "spent": "380000",
    "reclaimed": "420000",
    "pool": "9200000",
    "outstanding": "0"
  },
  "totalSupplyPaise": "99620000",
  "vaultTokenBalancePaise": "9200000",
  "totalLiabilitiesPaise": "9200000",
  "solvent": true,
  "addresses": {
    "RupeeToken": "0x5FbDB2315678afecb367f032d93F642f64180aa3",
    "ParticipantRegistry": "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    "WelfareVault": "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
  }
}
```
