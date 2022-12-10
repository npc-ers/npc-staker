import brownie
import pytest
from brownie import *


def test_wrap_several(npc, esg_npc, multiholder, multiholder_portfolio):
    assert esg_npc.balanceOf(multiholder) == 0
    npc.setApprovalForAll(esg_npc, True, {"from": multiholder})
    esg_npc.wrap(multiholder_portfolio, {"from": multiholder})
    assert esg_npc.balanceOf(multiholder) > 0


def test_unwrap_succeeds(npc, esg_npc, multiholder, multiholder_portfolio):
    assert esg_npc.balanceOf(multiholder) == 0
    npc.setApprovalForAll(esg_npc, True, {"from": multiholder})
    esg_npc.wrap(multiholder_portfolio, {"from": multiholder})
    assert esg_npc.balanceOf(multiholder) > 0

    cur_bal = npc.balanceOf(multiholder)
    esg_npc.unwrap(1, {"from": multiholder})

    assert cur_bal + 1 == npc.balanceOf(multiholder)

def test_can_retrieve_wrapped_from_staker(staker, multiholder, multiholder_portfolio, esg_npc, npc):
    init_bal = npc.balanceOf(multiholder)
    assert init_bal > 0

    npc.setApprovalForAll(staker, True, {"from": multiholder})
    staker.stake_npc(multiholder_portfolio, {'from': multiholder})
    staker.wrap({'from': multiholder})
    staker.withdraw({'from': multiholder})

    assert npc.balanceOf(multiholder) == init_bal - len(multiholder_portfolio)
    assert esg_npc.balanceOf(multiholder) > 0
    esg_npc.unwrap(esg_npc.balanceOf(multiholder) // 10 ** 18, {'from': multiholder})
    assert npc.balanceOf(multiholder) == init_bal
    assert esg_npc.balanceOf(multiholder) == 0
