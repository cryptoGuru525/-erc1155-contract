// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();

  // 1. ContractRegistry Contract Deployment
  const ContractRegistry = await hre.ethers.getContractFactory(
    "ContractRegistry"
  );
  const contractRegistry = await ContractRegistry.deploy(owner.address);
  await contractRegistry.deployed();
  console.log(`ContractRegistry deployed to ${contractRegistry.address}`);

  await hre.run("verify:verify", {
    address: contractRegistry.address,
    constructorArguments: [owner.address]
  });

  // 2. Domain Contract Deployment
  const Domain = await hre.ethers.getContractFactory(
    "contracts/Domain.sol:Domain"
  );
  const domain = await Domain.deploy(
    "Ethereum Name Service",
    "WENS",
    "https://ethereum-domain-api.herokuapp.com/api/token/",
    contractRegistry.address
  );
  await domain.deployed();
  console.log(`Domain deployed to ${domain.address}`);

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
  const EVMReverseResolver = await hre.ethers.getContractFactory(
    "EVMReverseResolver"
  );
  const _EVMReverseResolver = await EVMReverseResolver.deploy(
    contractRegistry.address
  );
  await _EVMReverseResolver.deployed();
  console.log(`EVMReverseResolver deployed to ${_EVMReverseResolver.address}`);
  await hre.run("verify:verify", {
    address: _EVMReverseResolver.address,
    constructorArguments: [contractRegistry.address]
  });

  // 4. LeasingAgent Contract Deployment
  const LeasingAgent = await hre.ethers.getContractFactory("LeasingAgent");
  const leasingAgent = await LeasingAgent.deploy(
    contractRegistry.address,
    "17816229075993215846759527713510517151474369758522418446609974478566370969911"
  );
  await leasingAgent.deployed();
  console.log(`LeasingAgent deployed to ${leasingAgent.address}`);

  await hre.run("verify:verify", {
    address: leasingAgent.address,
    constructorArguments: [
      contractRegistry.address,
      "17816229075993215846759527713510517151474369758522418446609974478566370969911"
    ]
  });

  // 5. PublicResolver Contract Deployment
  const PublicResolver = await hre.ethers.getContractFactory("PublicResolver");
  const publicResolver = await PublicResolver.deploy(contractRegistry.address);
  await publicResolver.deployed();
  console.log(`PublicResolver deployed to ${publicResolver.address}`);

  await hre.run("verify:verify", {
    address: publicResolver.address,
    constructorArguments: [contractRegistry.address]
  });

  // 6. RainbowTable Contract Deployment
  const RainbowTable = await hre.ethers.getContractFactory("RainbowTable");
  const rainbowTable = await RainbowTable.deploy(contractRegistry.address);
  await rainbowTable.deployed();
  console.log(`RainbowTable deployed to ${rainbowTable.address}`);

  await hre.run("verify:verify", {
    address: rainbowTable.address,
    constructorArguments: [contractRegistry.address]
  });

  // 7. ResolverRegistry Contract Deployment
  const ResolverRegistry = await hre.ethers.getContractFactory(
    "ResolverRegistry"
  );
  const resolverRegistry = await ResolverRegistry.deploy(
    contractRegistry.address
  );
  await resolverRegistry.deployed();
  console.log(`ResolverRegistry deployed to ${resolverRegistry.address}`);

  await hre.run("verify:verify", {
    address: resolverRegistry.address,
    constructorArguments: [contractRegistry.address]
  });

  // 8. ReverseResolverRegistry Contract Deployment
  const ReverseResolverRegistry = await hre.ethers.getContractFactory(
    "ReverseResolverRegistry"
  );
  const reverseResolverRegistry = await ReverseResolverRegistry.deploy(
    contractRegistry.address
  );
  await reverseResolverRegistry.deployed();
  console.log(
    `ReverseResolverRegistry deployed to ${reverseResolverRegistry.address}`
  );
  await hre.run("verify:verify", {
    address: reverseResolverRegistry.address,
    constructorArguments: [contractRegistry.address]
  });

  // 9. PricingOracle Contract Deployment
  const PricingOracle = await hre.ethers.getContractFactory("PricingOracle");
  const pricingOracle = await PricingOracle.deploy();
  await pricingOracle.deployed();
  console.log(`PricingOracle deployed to ${pricingOracle.address}`);

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
