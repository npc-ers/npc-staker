from brownie import *
import brownie
import pytest


def test_cannot_stake_npc_without_approval(staker, npc, tetra):
    assert npc.ownerOf(0) == tetra
    with brownie.reverts():
        staker.stake_npc([0], {"from": tetra})
    assert npc.ownerOf(0) == tetra


def test_cannot_stake_if_not_owner(staker, npc, alice, tetra):
    assert npc.ownerOf(0) != alice
    with brownie.reverts():
        staker.stake_npc([0], {"from": tetra})
    assert npc.ownerOf(0) == tetra


def test_stake_npc(staked_nft, npc, tetra):
    assert npc.ownerOf(0) == staked_nft


def test_stake_wrapped(staker, npc, esg_npc, esg_npc_holder):
    bal = esg_npc.balanceOf(esg_npc_holder)
    esg_npc.approve(staker, bal, {"from": esg_npc_holder})
    staker.stake_wnpc(bal, {"from": esg_npc_holder})

    assert esg_npc.balanceOf(esg_npc_holder) == 0
    


