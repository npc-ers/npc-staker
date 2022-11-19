import brownie
import pytest
from brownie import chain


@pytest.mark.skip()
def test_cannot_withdraw_prematurely(staked_nft, tetra, thing, npc, holder):
    assert npc.balanceOf(tetra) == 0

    with brownie.reverts():
        staked_nft.withdraw({"from": tetra})


def test_balance_increases(staked_nft, tetra, thing, alice, npc, holder):
    chain.mine(5)
    assert round(staked_nft.reward_balance(tetra) * 60 * 24 / 10**18, 0) == 1000


@pytest.mark.skip_coverage
def test_withdraw_wrapped(staked_nft, tetra, npc, holder, esg_npc):
    chain.mine(5)
    assert esg_npc.balanceOf(tetra) == 0

    staked_nft.withdraw_wrapped({'from': tetra})
    assert esg_npc.balanceOf(tetra) > 0

@pytest.mark.skip_coverage
def test_withdraw_nft_balance_up(staked_nft, tetra, thing, alice, npc, holder):
    chain.mine(5)
    # staked_nft.admin_trigger_epoch(True, {"from": alice})
    thing_init = thing.balanceOf(tetra)
    assert npc.balanceOf(tetra) == 0

    staked_nft.withdraw({"from": tetra})

    assert thing.balanceOf(tetra) > thing_init
    assert npc.balanceOf(tetra) > 0


@pytest.mark.skip_coverage
def test_withdraw_works_after_transfer(staked_nft, tetra, thing, alice, npc, holder):
    chain.mine(5)
    thing.mint(staked_nft, 10**18, {"from": thing.owner()})
    # staked_nft.admin_trigger_epoch(True, {"from": alice})
    thing_init = thing.balanceOf(tetra)
    assert npc.balanceOf(tetra) == 0

    staked_nft.withdraw({"from": tetra})

    assert thing.balanceOf(tetra) > thing_init
    assert npc.balanceOf(tetra) > 0


@pytest.mark.skip_coverage
def test_withdraw_wnpc(staker, npc, esg_npc, esg_npc_holder, thing):
    thing_init = thing.balanceOf(esg_npc_holder)
    bal = esg_npc.balanceOf(esg_npc_holder)
    esg_npc.approve(staker, bal, {"from": esg_npc_holder})
    staker.stake_wnpc(bal, {"from": esg_npc_holder})
    chain.mine(5)
    staker.withdraw({"from": esg_npc_holder})
    assert thing.balanceOf(esg_npc_holder) > thing_init
    assert esg_npc.balanceOf(esg_npc_holder) == bal
