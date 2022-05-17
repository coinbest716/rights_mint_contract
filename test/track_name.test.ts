import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

import { SongTrack__factory } from '../typechain/factories/SongTrack__factory';
import { SongTrack } from '../typechain/SongTrack';

import { SongMarketplace__factory } from '../typechain/factories/SongMarketplace__factory';
import { SongMarketplace } from '../typechain/SongMarketplace';

describe('Check deployment', async () => {
  let songTrack: SongTrack;
  let admin: SignerWithAddress;  
  let songMarketplace: SongMarketplace;

    before(async () => {
        [admin] = await ethers.getSigners();
        songMarketplace = await new SongMarketplace__factory(admin).deploy();
        songTrack = await new SongTrack__factory(admin).deploy(1000, admin.address, songMarketplace.address, "Dua in Hamburg", "Dua Lipa");           
    });

    it('check track name on single mint', async () => {
        let res = await songTrack.mint(admin.address, 1000, "abc", "0000", {value:1000});
        let res1 = await res.wait();
        let events = res1.events?.filter((el) => (el.event == "URI"))
        // console.log(events);

        console.log(await songTrack.getTrackNameOfNFT(1));
    });

    it('check track name on batch mint', async () => {
        let supplys = [4,5,6,7];
        let uris = ["abc", "def", "hef", "avd"];
        let trackNames = ["1111", "2222", "3333", "4444"];
        let res = await songTrack.mintBatch(admin.address, supplys, uris, trackNames, {value:1000});
        let res1 = await res.wait();
        let events = res1.events?.filter((el) => (el.event == "BatchMint"))

        // console.log(events ? events[0].args?.ids: "abc");
        console.log(await songTrack.getTrackNameOfNFT(1));
        console.log(await songTrack.getTrackNameOfNFT(2));
        console.log(await songTrack.getTrackNameOfNFT(3));
        console.log(await songTrack.getTrackNameOfNFT(4));
    });
});