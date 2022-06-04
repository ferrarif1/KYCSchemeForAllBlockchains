
/*
npx hardhat run --network localhost migrations/deployKYCManager.js

KYCManager deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
KYCNFT deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
*/
async function main() {
  // 获得将要部署的合约
  const KYCManager = await ethers.getContractFactory("KYCManager");
  const KYCNFT = await ethers.getContractFactory("KYCNFT");
  const kycManager = await KYCManager.deploy();
  const kycNFT = await KYCNFT.deploy();

  console.log("KYCManager deployed to:", kycManager.address);
  console.log("KYCNFT deployed to:", kycNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });