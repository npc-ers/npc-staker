#!/usr/bin/python3

import pytest
from brownie import (ESG_NPC, NPC, Contract, CurrentThing, OrthodoxyCamp,
                     accounts, chain, network)


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass


@pytest.fixture(scope="function")
def alice():
    return accounts[0]


@pytest.fixture(scope="function")
def bob():
    return accounts[1]


@pytest.fixture(scope="function")
def npc(alice):
    if "fork" in network.show_active():
        return Contract("0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8")
    else:
        npc = NPC.deploy({"from": alice})
        return npc


@pytest.fixture(scope="function")
def tetra(npc, alice):
    if "fork" in network.show_active():
        return npc.ownerOf(0)
    else:
        npc.mint(accounts[9], {"from": alice})
        return npc.ownerOf(0)


@pytest.fixture(scope="function")
def thing(alice):
    if "fork" in network.show_active():
        thing = Contract("0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB")
    else:
        thing = CurrentThing.deploy({"from": alice})
    return thing


@pytest.fixture(scope="function")
def esg_npc(npc):
    esg_npc = ESG_NPC.deploy("ESG NPC", "esgNPC", npc, {"from": accounts[0]})
    return esg_npc


@pytest.fixture(scope="function")
def staker(alice, thing, esg_npc, npc):
    v = OrthodoxyCamp.deploy(npc, esg_npc, thing, {"from": alice})
    thing.admin_set_minter(v, {"from": thing.owner()})
    return v


@pytest.fixture(scope="function")
def holder():
    return "0x5881d9bfff787c8655a9b7f3484ae1a6f7a966e8"


@pytest.fixture(scope="function")
def holder_bal():
    return "0x5881d9bfff787c8655a9b7f3484ae1a6f7a966e8"


@pytest.fixture(scope="function")
def staked_nft(staker, tetra, npc):
    assert npc.ownerOf(0) == tetra
    # npc.approve(staker, 0, {"from": tetra})
    npc.setApprovalForAll(staker, True, {"from": tetra})
    staker.stake_npc([0], {"from": tetra})
    chain.mine(5)
    return staker


@pytest.fixture(scope="function")
def multistaked_nft(staker, tetra, npc, multiholder, multiholder_portfolio):
    npc.setApprovalForAll(staker, True, {"from": multiholder})
    staker.stake_npc(multiholder_portfolio, {"from": multiholder})
    return staker


# Wrapped ERC


@pytest.fixture(scope="function")
def multiholder():
    if "fork" in network.show_active():
        return "0x8AaDe16ad409A19b0FF990B30a9a0E65d32DEa7D"
    else:
        return accounts[9]


@pytest.fixture(scope="function")
def multiholder_portfolio(multiholder, npc, alice):
    if "fork" in network.show_active():
        return [1451, 1450, 1449, 3892, 1138]
    else:
        ret_arr = []
        for i in range(5):
            npc.mint(multiholder, {"from": alice})
            ret_arr.append(npc.tokenOfOwnerByIndex(multiholder, i))
        return ret_arr


@pytest.fixture(scope="function")
def esg_npc_holder(multiholder, multiholder_portfolio, npc, esg_npc):
    npc.setApprovalForAll(esg_npc, True, {"from": multiholder})
    esg_npc.wrap(multiholder_portfolio, {"from": multiholder})
    return multiholder
