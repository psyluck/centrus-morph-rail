import { ethers } from "hardhat";

async function main() {
  // Generate 2 consistent mock addresses for your corporate entities
  const remitlyWallet = "0x1111111111111111111111111111111111111111";
  const coinsPhWallet = "0x2222222222222222222222222222222222222222";

  // Replace these with your actual deployed Morph Testnet contract addresses
  const SETTLEMENT_ENGINE_ADDRESS = "PASTE_YOUR_SETTLEMENT_ENGINE_ADDRESS_HERE";
  const USDC_ARC_ADDRESS = "PASTE_YOUR_USDC_ARC_ADDRESS_HERE";
  const RLUSD_ADDRESS = "PASTE_YOUR_RLUSD_ADDRESS_HERE";

  console.log("Configuring B2B Corporate Clients on Centrus Engine...");

  const engine = await ethers.getContractAt("CentrusMorphSettlement", SETTLEMENT_ENGINE_ADDRESS);
  const usdc = await ethers.getContractAt("CentrusMockStablecoin", USDC_ARC_ADDRESS);
  const rlusd = await ethers.getContractAt("CentrusMockStablecoin", RLUSD_ADDRESS);

  // 1. Register Remitly (Source Node) with an institutional risk profile limit
  const limit1 = ethers.parseUnits("5000000", 6); // $5M Daily Limit Allotment
  
  let tx = await engine.registerClient(remitlyWallet, "Remitly USA", limit1);
  await tx.wait();
  console.log("✔ Remitly Node Registered Successfully in Centrus Directory.");

  // 2. Provision Capitalization (Fund Remitly's working capital balance with USDC Arc)
  const fundingAmount = ethers.parseUnits("1000000", 6); // Send $1,000,000 to Remitly
  tx = await usdc.transfer(remitlyWallet, fundingAmount);
  await tx.wait();
  console.log("✔ Provisioned $1,000,000 USDC Arc into Remitly Operational Clearing Account.");

  // 3. Pre-approve the settlement contract to move funds when Remitly triggers a trade
  console.log("✔ Setup complete. System state primed for live settlement slicing execution.");
  console.log("\n--- READY FOR LIVE HACKATHON DEMO ---");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});