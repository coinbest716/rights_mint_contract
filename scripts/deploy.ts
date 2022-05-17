import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

import { SongTrack__factory } from '../typechain/factories/SongTrack__factory';
import { SongTrack } from '../typechain/SongTrack';

import { SongMarketplace__factory } from '../typechain/factories/SongMarketplace__factory';
import { SongMarketplace } from '../typechain/SongMarketplace';

async function main():Promise<void> {
  let songTrack: SongTrack;
  let songMarketplace: SongMarketplace;
  let admin: SignerWithAddress;

  [admin] = await ethers.getSigners();
  songMarketplace = await new SongMarketplace__factory(admin).deploy();
  songTrack = await new SongTrack__factory(admin).deploy(1000, admin.address, songMarketplace.address, "Dua in Hamburg", "Dua Lipa");          
  console.log("SongTrack:", songTrack.address);
  console.log("SongMarketPlace:", songMarketplace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
