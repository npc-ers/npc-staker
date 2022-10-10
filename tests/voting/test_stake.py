from brownie import *
import brownie
import pytest


def test_cannot_stake_npc_without_approval(staker, npc, tetra):
    assert npc.ownerOf(0) == tetra
    with brownie.reverts():
        staker.stake_npc(0, {'from': tetra}) 
    assert npc.ownerOf(0) == tetra


def test_cannot_stake_if_not_owner(staker, npc, alice, tetra):
    assert npc.ownerOf(0) != alice
    with brownie.reverts():
        staker.stake_npc(0, {'from': tetra}) 
    assert npc.ownerOf(0) == tetra


def test_stake_npc(staked_nft, npc, tetra):
    assert npc.ownerOf(0) == staked_nft


def test_stake_thing(staker, thing, holder):
    bal = thing.balanceOf(holder)
    assert bal > 0
   
    thing.approve(staker, bal, {'from': holder})
    staker.stake_thing(bal, {'from': holder})

    assert thing.balanceOf(holder) == 0


