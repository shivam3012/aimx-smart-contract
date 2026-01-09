const { ethers } = require("ethers");

async function main() {
//   const [signer] = await ethers.getSigners();

  // ---- generate 40 wallets off chain ----
  const recipients = [];
  for (let i = 0; i < 40; i++) {
    const w = ethers.Wallet.createRandom();
    recipients.push(w.address);       // ✔ checksum valid
  }

  console.log("Generated Addresses:");
  console.log(recipients)
}

main()