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
  //   address: contractRegistry.address,
  //   constructorArguments: [owner.address]
  // });

  // 2. Domain Contract Deployment
  await hre.run("verify:verify", {
    address: domain.address,
    constructorArguments: [
      "Ethereum Name Service",
      "WENS",
      "https://ethereum-domain-api.herokuapp.com/api/token/",
      contractRegistry.address
    ],
    contract: "contracts/Domain.sol:Domain"
  });

  // 3. EVMReverseResolver Contract Deployment
  await hre.run("verify:verify", {
    address: _EVMReverseResolver.address,
    constructorArguments: [contractRegistry.address]
  });

  // 4. LeasingAgent Contract Deployment
  await hre.run("verify:verify", {
    address: leasingAgent.address,
    constructorArguments: [
      contractRegistry.address,
      "17816229075993215846759527713510517151474369758522418446609974478566370969911"
    ]
  });

  // 5. PublicResolver Contract Deployment
  await hre.run("verify:verify", {
    address: publicResolver.address,
    constructorArguments: [contractRegistry.address]
  });

  // 6. RainbowTable Contract Deployment
  await hre.run("verify:verify", {
    address: rainbowTable.address,
    constructorArguments: [contractRegistry.address]
  });

  // 7. ResolverRegistry Contract Deployment
  await hre.run("verify:verify", {
    address: resolverRegistry.address,
    constructorArguments: [contractRegistry.address]
  });

  // 8. ReverseResolverRegistry Contract Deployment
  await hre.run("verify:verify", {
    address: reverseResolverRegistry.address,
    constructorArguments: [contractRegistry.address]
  });

  // 9. PricingOracle Contract Deployment
  await hre.run("verify:verify", {
    address: pricingOracle.address
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
