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


def test_wrapped_multiplier_in_bounds(staker, npc, esg_npc, esg_npc_holder):
    assert staker.calc_avg_coin_multiplier(10 ** 18, 0) > 0
    assert staker.calc_avg_coin_multiplier(10 ** 18, 0) / 10 ** 18 < 10 


def test_wrapping_internally_works(npc, esg_npc, multistaked_nft, multiholder):
    init_count = multistaked_nft.nft_balance(multiholder) 
    assert init_count > 0
    assert multistaked_nft.balanceOf(multiholder) == init_count * 10 ** 18
    
    multistaked_nft.wrap({'from': multiholder})

    assert multistaked_nft.nft_balance(multiholder) ==  0
    assert multistaked_nft.balanceOf(multiholder) == init_count * 10 ** 18 
 
    init_nft = npc.balanceOf(multiholder) 
    assert esg_npc.balanceOf(multiholder) == 0

    multistaked_nft.withdraw({'from': multiholder})
    assert npc.balanceOf(multiholder) == init_nft
    assert esg_npc.balanceOf(multiholder) == init_count * 10 ** 18 


