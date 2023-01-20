![🥩 Steak](https://media.discordapp.net/attachments/1026939736146849882/1065832061052670042/Screen_Shot_2023-01-19_at_7.15.45_PM.png)

# 🏕️ NPC Orthodoxy Camp

**🥩 Steak your NPC-er for re-education and earn worthless $THING CBDCs**

Welcome to Orthodoxy Camp!  Send your [NPC](https://etherscan.io/address/0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8) to camp, earn [$THING](https://etherscan.io/address/0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB).  Just your usual steaking, right?

Problem is, NPC allegiances are fickle.  NPCs can't stay focused on re-education when they're too busy getting outraged by the most recent post they saw on social media.  We needed to build a liquid staking mechanism for today's attention span.

### The Current Thing

The Current Thing™ changes very rapidly.  Our DAO votes on this frequently and writes this on-chain through the [$THING token](https://etherscan.io/address/0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8).

![Elon Musk and SBF previously the Current Thing](https://substackcdn.com/image/fetch/w_1456,c_limit,f_webp,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F32f5b6e5-102a-4230-83b4-389e963f26d6_492x142.png)

Whenever a new Current Thing is announced, our staker assigns a pseudorandom multiplier to each NPC.  Most are very low (1x), but some may be high as 10x.  Here's an example distribution for a collection in one epoch:

![NPC-ers distribution](https://substackcdn.com/image/fetch/w_1456,c_limit,f_webp,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F0fd03a23-ad67-4611-a358-5a1929ad4116_238x304.png)

Due to the fact the NPC multiplier is deterministic by epoch, it’s possible to collect NPCs which will have a high multiplier to collect more $THING.  This means some NPCs with more common traits may nonetheless see utility for stakers.

![NPC-ers multipliers by epoch](https://substackcdn.com/image/fetch/w_1456,c_limit,f_webp,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fadef60b6-b8ca-4e1d-9cff-446f2757aac0_746x472.png)

One final note for whales — you get an additional multiplier based on the square root of the number of NPCs staked, inspired by [Paradigm's Goo](https://www.paradigm.xyz/2022/09/goo)

Stake one NPC, and the NPC gets the exact multiplier stated on the tin.  Stake 4, and these are doubled.  Stake 9, the multipliers are tripled.  Not bad…

![Bulk Bonus](https://substackcdn.com/image/fetch/w_1456,c_limit,f_webp,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F1300ba6e-9376-4665-bcca-43e0deadf288_498x206.png)

# ESG Compatibility

Knowing that NFTs still kill trees, because NPCs don’t understand the Merge, we needed a friendly solution so as not to offend their performative gestures towards environmentalism.

For starters, all these functions have been hyper-gas optimized to ensure they run efficiently.

Just in case this is too wealthy for you liberal arts major NPCs, we also came up with the ESG-NPC — an ERC-20 wrapper for an NPC which uses way less gas.

Any NPC can be “wrapped” as an ESG-NPC, which carries a one time wrapping cost, but then can be transferred and staked in bulk.  You may unwrap at any time to receive an NFT back, but the unwrapping works on a LIFO system so you may not get your original NPC back.  However, since all NPCs are basically interchangeable, does this matter?

Wait, how do you determine a multiplier for wrapped NPCs?  Each new epoch of “Current Thing,” we average a handful of NPC multipliers and apply this to all wrapped NPCs.  If your NPC multiplier is below this amount, you may be able to obtain a higher multiplier by wrapping your NPC (with the knowledge that you may never see your NPC again).

![esgNPC](https://substackcdn.com/image/fetch/w_1456,c_limit,f_webp,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fa670a680-4f6c-47fd-b7fd-7e2f244ba37f_1210x478.png)

The benefits of a wrapped NPC, in addition to the environmental gesture, are to promote greater conformity and mass formation psychosis.  The ability to best blend into a crowd and dissolve ones opinions into the collective is truly the highest form of achievement.

# Addresses

- **Steak**: [0x9b326BC227E00d1e6D3E94e668Eea6D2349B8b31](https://etherscan.io/address/0x9b326BC227E00d1e6D3E94e668Eea6D2349B8b31)
- **esgNPC**: [0x41F2c48e901b6a0A19FEa0256826485045ce953b](https://etherscan.io/address/0x41F2c48e901b6a0A19FEa0256826485045ce953b)

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
