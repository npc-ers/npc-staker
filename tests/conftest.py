#!/usr/bin/python3

import pytest
from brownie import ESG_NPC, Contract, OrthodoxyCamp, accounts


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass


@pytest.fixture(scope="function")
def alice():
    return accounts[0]


@pytest.fixture(scope="function")
def npc():
    return Contract("0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8")


@pytest.fixture(scope="function")
def tetra(npc):
    return npc.ownerOf(0)


@pytest.fixture(scope="function")
def thing():
    return Contract("0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB")


@pytest.fixture(scope="function")
def esg_npc(npc):
    return ESG_NPC.deploy("ESG NPC", "esgNPC", npc, {"from": accounts[0]})


@pytest.fixture(scope="function")
def staker(alice, thing, esg_npc):
    v = OrthodoxyCamp.deploy(esg_npc, {"from": alice})
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
    return staker


# Wrapped ERC


@pytest.fixture(scope="function")
def multiholder():
    return "0x8AaDe16ad409A19b0FF990B30a9a0E65d32DEa7D"


@pytest.fixture(scope="function")
def multiholder_portfolio():
    return [1451, 1450, 1449, 3892, 1138]


@pytest.fixture(scope="function")
def esg_npc_holder(multiholder, multiholder_portfolio, npc, esg_npc):
    npc.setApprovalForAll(esg_npc, True, {"from": multiholder})
    esg_npc.wrap(multiholder_portfolio, {"from": multiholder})
    return multiholder
