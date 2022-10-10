#!/usr/bin/python3

import pytest
from brownie import (
    Vote, accounts, Contract
)


@pytest.fixture(scope="module")
def alice():
    return accounts[0]

@pytest.fixture(scope="module")
def npc():
    return Contract('0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8')

@pytest.fixture(scope="module")
def tetra(npc):
    return npc.ownerOf(0)

@pytest.fixture(scope="module")
def thing(): 
    return Contract('0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB')

@pytest.fixture(scope="module")
def staker(alice, thing):
    v = Vote.deploy({'from': alice})
    thing.admin_set_minter(v, {'from': thing.owner()})
    return v 


@pytest.fixture(scope="module")
def holder():
    return '0x5881d9bfff787c8655a9b7f3484ae1a6f7a966e8'


@pytest.fixture(scope="module")
def holder_bal():
    return '0x5881d9bfff787c8655a9b7f3484ae1a6f7a966e8'



@pytest.fixture(scope="module")
def staked_nft(staker, tetra, npc):
    assert npc.ownerOf(0) == tetra
    npc.approve(staker, 0, {'from': tetra})
    staker.stake_npc(0, {'from': tetra})
    return staker
