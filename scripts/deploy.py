from brownie import *

def main():
    npc = Contract("0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8")
    thing = Contract("0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB")
    alice = accounts[0]
    esg_npc = ESG_NPC.deploy("ESG NPC", "esgNPC", npc, {"from": alice})
    v = OrthodoxyCamp.deploy(npc, thing, esg_npc, {"from": alice})
    thing.admin_set_minter(v, {"from": thing.owner()})
