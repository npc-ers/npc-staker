# 🏕️ NPC Orthodoxy Camp

**🥩 Steak your NPC-er for re-education and earn worthless $THING CBDCs**


After the NPC NFT sold out in record time, we fielded a lot of questions.  Mostly around our native $THING toiken.

As of today, you can enlist your NPCs into Orthodoxy Camp.

Orthodoxy Camp works like liquid staking.  For however long your NPC stays interned learning about the benefits of the Current Thing, you earn $THING.

But, we had to adjust this to make it closer to NPC lore.  We know all NPC allegiances are fickle, and twist rapidly in the wind.

Built into our original architectures is the capability of updating to reflect a new “Current Thing,” we have done this three times and varied the artwork each time:

* Original Launch
* Elon Musk era
* SBF era
* YOU DECIDE?

Whenever a new Current Thing is announced, each NPC has a pseudorandom new multiplier assigned for this era.  Most are very low (1x), but some may be high as 10x, and earn $THING rewards at this rate.

Due to the fact the NPC multiplier is deterministic by epoch, it’s possible to collect NPCs which will have a high multiplier to collect more $THING.  This means some NPCs with more common traits may nonetheless see utility for stakers.


One final note for whales — you get an additional multiplier based on the square root of the number of NPCs staked.   (c/f https://www.paradigm.xyz/2022/09/goo)

Stake one NPC, and the NPC gets the exact multiplier stated on the tin.  Stake 4, and these are doubled.  Stake 9, the multipliers are tripled.  Not bad…


# ESG Compatibility

Knowing that NFTs still kill trees, because NPCs don’t understand the Merge, we needed a friendly solution so as not to offend their performative gestures towards environmentalism.

For starters, all these functions have been hyper-gas optimized to ensure they run efficiently.

Just in case this is too wealthy for you liberal arts major NPCs, we also came up with the ESG-NPC — an ERC-20 wrapper for an NPC which uses way less gas.

Any NPC can be “wrapped” as an ESG-NPC, which carries a one time wrapping cost, but then can be transferred and staked in bulk.  You may unwrap at any time to receive an NFT back, but the unwrapping works on a LIFO system so you may not get your original NPC back.  However, since all NPCs are basically interchangeable, does this matter?

Wait, how do you determine a multiplier for wrapped NPCs?  Each new epoch of “Current Thing,” we average a handful of NPC multipliers and apply this to all wrapped NPCs.  If your NPC multiplier is below this amount, you may be able to obtain a higher multiplier by wrapping your NPC (with the knowledge that you may never see your NPC again).

The benefits of a wrapped NPC, in addition to the environmental gesture, are to promote greater conformity and mass formation psychosis.  The ability to best blend into a crowd and dissolve ones opinions into the collective is truly the highest form of achievement.


## Setup Notes

- Add WEB3_INFURA_PROJECT_ID to your env
- Follow setup instructions for brownie

### Tests
- Run `brownie test --network mainnet-fork`

### Troubleshooting
`Unknown contract address` and/or Brownie does not autofetch Contract sources`

- Replace `Contract("CANT_FIND")` with `Contract.from_explorer(`
- Run once to download all contracts
- Will likely hit rate limiting error
- Revert changes using `from_explorer`
- Profit
