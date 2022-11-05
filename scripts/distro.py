import warnings

from brownie import *

warnings.filterwarnings("ignore", category=DeprecationWarning)


def main():

    camp = OrthodoxyCamp.deploy(ZERO_ADDRESS, {"from": accounts[0]})
    thing = Contract("0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB")
    holder = "0x5881d9bfff787c8655a9b7f3484ae1a6f7a966e8"
    npc = Contract("0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8")
    thing.admin_set_minter(camp, {"from": thing.owner()})

    multisig = "0x8AaDe16ad409A19b0FF990B30a9a0E65d32DEa7D"

    many_arr= range(13,42)

    for i in many_arr:
        if npc.ownerOf(i) != multisig:
            print(i)

    npc.setApprovalForAll(camp, True, {"from": multisig})
    camp.stake_npc(list(many_arr), {"from": multisig})

    mults = {}
    for i in range(10):
        mults[i] = 0

    for i in many_arr:
        mults[camp.calc_multiplier(i, 3)] += 1

    for i in range(10):
        print(i, "X" * mults[i])
    assert False
