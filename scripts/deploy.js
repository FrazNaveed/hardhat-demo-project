const { ethers, upgrades } = require("hardhat");

async function main() {
  // Deploy the contract
  const TokenClaim = await ethers.getContractFactory("MyGovernor");
  const _token = "0x5F2090A425687E4951fd87D424724Ef1E33c24F3"; // Replace with the actual token address
  const tokenClaim = await TokenClaim.deploy(
    "0x04e4836764589753df408bE28e8D29da3B075dEC",
    "0x0302123C94cA1cB4B7AcA57a555f9A94A8523715"
  );

  await tokenClaim.deployed();

  console.log("TokenClaim deployed to:", tokenClaim.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
