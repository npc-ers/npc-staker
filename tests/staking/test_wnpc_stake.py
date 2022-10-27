import brownie
import pytest
from brownie import *


def test_stake_wrapped(staker, npc, esg_npc, esg_npc_holder):
    bal = esg_npc.balanceOf(esg_npc_holder)
    esg_npc.approve(staker, bal, {"from": esg_npc_holder})
    staker.stake_wnpc(bal, {"from": esg_npc_holder})

    assert esg_npc.balanceOf(esg_npc_holder) == 0


def test_cannot_stake_invalid_balance(staker, npc, esg_npc, esg_npc_holder):
    bal = esg_npc.balanceOf(esg_npc_holder)
    esg_npc.approve(staker, bal, {"from": esg_npc_holder})
    with brownie.reverts():
        staker.stake_wnpc(bal + 1, {"from": esg_npc_holder})
