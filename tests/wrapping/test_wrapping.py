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
