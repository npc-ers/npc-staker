import brownie
import pytest
from brownie import *


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


def test_stake_list_with_one_bogus(staker, npc, multiholder, multiholder_portfolio):
    npc.setApprovalForAll(staker, True, {"from": multiholder})
    init_bal = npc.balanceOf(multiholder)
    with brownie.reverts():
        staker.stake_npc(multiholder_portfolio + [0], {"from": multiholder})
    assert npc.balanceOf(multiholder) == init_bal


def test_can_stake_consecutive(staker, npc, multiholder, multiholder_portfolio):
    npc.setApprovalForAll(staker, True, {"from": multiholder})
    init_bal = npc.balanceOf(multiholder)
    for i in multiholder_portfolio:
        staker.stake_npc([i], {"from": multiholder})
