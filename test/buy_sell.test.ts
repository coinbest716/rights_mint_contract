import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import chai, {expect} from 'chai'
import { BigNumber } from 'ethers';

import { SongTrack__factory } from '../typechain/factories/SongTrack__factory';
import { SongTrack } from '../typechain/SongTrack';

import { SongMarketplace__factory } from '../typechain/factories/SongMarketplace__factory';
import { SongMarketplace } from '../typechain/SongMarketplace';

describe('Check deployment', async () => {
  let songTrack: SongTrack;
  let songMarketplace: SongMarketplace;
  let admin: SignerWithAddress;  
  let tester: SignerWithAddress;  
    beforeEach(async () => {
        [admin, tester] = await ethers.getSigners();
        
        songMarketplace = await new SongMarketplace__factory(admin).deploy();
        songTrack = await new SongTrack__factory(admin).deploy(1000, admin.address, songMarketplace.address, "Dua in Hamburg", "Dua Lipa");        
        await songTrack.mint(admin.address, 1000, "abc", {value:1000});           
        
    });

    it('check fetch active items', async () => {        
        let activeItems =await songMarketplace.fetchActiveItems();
        console.log(activeItems);        
    });

    it('buy item', async () => {        
        await songMarketplace.fetchActiveItems();
        let quantity = 10;
        let unit_price = await songTrack.nftPrice();
        await songMarketplace.connect(tester).createMarketSale(songTrack.address, 1, 10, {value: unit_price.mul(quantity)})
        expect(await songTrack.balanceOf(tester.address, 1), "Correct Number").equal(10);    
    });
});