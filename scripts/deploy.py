from brownie import *
user = '0xb51074Da03c55E79e3526cF6bBf31873443EfC63'        

def main():
    if network.show_active() == 'development':
	    airplane_mode = True
    else:
	    airplane_mode = False

    if airplane_mode:
        npc, thing, alice = deploy_local()
    else:
	    npc = Contract("0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8")
	    thing = Contract("0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB")
	    alice = accounts[0]

    esg_npc = ESG_NPC.deploy("ESG NPC", "esgNPC", npc, {"from": alice})
    v = OrthodoxyCamp.deploy(npc, thing, esg_npc, {"from": alice})
    if not airplane_mode:
    	thing.admin_set_minter(v, {"from": thing.owner()})

    chain.snapshot()
    print(f"export const STAKER_ADDRESS = '{v}'")
    print(f"export const NPC_ADDRESS = '{npc}'")

    #token_by = NPCByOwner.deploy(npc, {'from': a[0]})
    #print(f"export const TOKEN_BY = '{token_by}'")



def deploy_local():
    deployer = accounts[0]
    publish_flag = False

    # Deploy Token
    thing = CurrentThing.deploy({"from": deployer}, publish_source=publish_flag)

    # Deploy NFT
    nft = NPC.deploy({"from": deployer}, publish_source=publish_flag)
    thing.admin_set_npc_addr(nft, {"from": deployer})

    # Deploy Minter
    minter = Indoctrinator.deploy({"from": deployer}, publish_source=publish_flag)
    minter.admin_set_nft_addr(nft, {"from": deployer})
    minter.admin_set_token_addr(thing, {"from": deployer})
    thing.admin_set_minter(minter, {"from": deployer})
    nft.set_minter(minter, {"from": deployer})

    accounts[0].transfer(user, accounts[0].balance())
    minter.mint(10, {'from': accounts[5], 'value': minter.mint_price(10, accounts[5])})
    minter.mint(10, {'from': user, 'value': minter.mint_price(10, user)})
    return nft, thing, user
