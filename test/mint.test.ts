import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

import { SongTrack__factory } from "../typechain/factories/SongTrack__factory";
import { SongTrack } from "../typechain/SongTrack";

import { SongMarketplace__factory } from "../typechain/factories/SongMarketplace__factory";
import { SongMarketplace } from "../typechain/SongMarketplace";

describe("Check deployment", async () => {
  let songTrack: SongTrack;
  let admin: SignerWithAddress;
  let songMarketplace: SongMarketplace;

  before(async () => {
    [admin] = await ethers.getSigners();
    songMarketplace = await new SongMarketplace__factory(admin).deploy();
    songTrack = await new SongTrack__factory(admin).deploy(
      1000,
      admin.address,
      songMarketplace.address,
      "Dua in Hamburg",
      "Dua Lipa"
    );
  });

  it("check single mint", async () => {
    let res = await songTrack.mint(admin.address, 1000, "abc", {
      value: 1000,
    });
    let res1 = await res.wait();
    let events = res1.events?.filter((el) => el.event == "URI");

    console.log(admin.address);
    let res2 = await songTrack.balanceOf(admin.address, 2);
    console.log(res2);
  });

  //   it("check batch mint", async () => {
  //     let supplys = [4, 5, 6, 7];
  //     let uris = ["abc", "def", "hef", "avd"];
  //     let res = await songTrack.mintBatch(admin.address, supplys, uris, {
  //       value: 1000,
  //     });
  //     let res1 = await res.wait();
  //     let events = res1.events?.filter((el) => el.event == "BatchMint");
  //     console.log(events ? events[0].args : "abc");
  //     //   console.log(events ? events[0].args?.ids : "abc");
  //   });
});
