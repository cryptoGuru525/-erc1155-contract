// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();

  // // 1. ContractRegistry Contract Deployment
  // await hre.run("verify:verify", {
  //   address: "0x16dCfF55D6fb94B31709A63a27ac0918D72A4D12",
  //   constructorArguments: [owner.address]
  // });

  // 2. Domain Contract Deployment
  await hre.run("verify:verify", {
    address: "0xf90bd756cC3673d29f1A011fd0BdF4EC2b8e5828",
    constructorArguments: [
      "Ethereum Name Service",
      "WENS",
      "https://ethereum-domain-api.herokuapp.com/api/token/",
      "0x16dCfF55D6fb94B31709A63a27ac0918D72A4D12"
    ],
    contract: "contracts/Domain.sol:Domain"
  });

  // 3. EVMReverseResolver Contract Deployment
  await hre.run("verify:verify", {
    address: "0x54F0543C7908B4F3450487D566A75c4eF6D0cB96",
    constructorArguments: ["0x16dCfF55D6fb94B31709A63a27ac0918D72A4D12"]
  });

  // 4. LeasingAgent Contract Deployment
  await hre.run("verify:verify", {
    address: "0xA5ED011059184F8FfBc1152DaD45947Dc4ACf487",
    constructorArguments: [
      "0x16dCfF55D6fb94B31709A63a27ac0918D72A4D12",
      "17816229075993215846759527713510517151474369758522418446609974478566370969911"
    ]
  });

  // 5. PublicResolver Contract Deployment
  await hre.run("verify:verify", {
    address: "0xCcdF521fD9Cab73cA42674F2B86E1C330eBf2F85",
    constructorArguments: ["0x16dCfF55D6fb94B31709A63a27ac0918D72A4D12"]
  });

  // 6. RainbowTable Contract Deployment
  await hre.run("verify:verify", {
    address: "0x24349D07c0EaD3e37bb84c768A7668170b054E73",
    constructorArguments: ["0x16dCfF55D6fb94B31709A63a27ac0918D72A4D12"]
  });

  // 7. ResolverRegistry Contract Deployment
  await hre.run("verify:verify", {
    address: "0xCC9a5bE98358400A56FDF3DF75119471421DBd76",
    constructorArguments: ["0x16dCfF55D6fb94B31709A63a27ac0918D72A4D12"]
  });

  // 8. ReverseResolverRegistry Contract Deployment
  await hre.run("verify:verify", {
    address: "0xA8283b5E322dDFF506A81BBc917f7a703738f108",
    constructorArguments: ["0x16dCfF55D6fb94B31709A63a27ac0918D72A4D12"]
  });

  // 9. PricingOracle Contract Deployment
  await hre.run("verify:verify", {
    address: "0x8B3948241692aA851a3d9B14B7Be5aFe11D9Feb9"
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
