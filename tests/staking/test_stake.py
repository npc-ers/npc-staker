import brownie
import pytest
from brownie import *


def test_cannot_stake_npc_without_approval(staker, npc, tetra):
    assert npc.ownerOf(0) == tetra
    with brownie.reverts():
        staker.stake_npc([0], {"from": tetra})
    assert False
    assert npc.ownerOf(0) == tetra


def test_cannot_stake_if_not_owner(staker, npc, alice, tetra):
    assert npc.ownerOf(0) != alice
    with brownie.reverts():
        staker.stake_npc([0], {"from": tetra})
    assert npc.ownerOf(0) == tetra


def test_stake_npc(staked_nft, npc, tetra):
    assert npc.ownerOf(0) == staked_nft


def test_initial_rate_is_zero(staker, npc, tetra):
    assert staker.current_rate_for_user(tetra) == 0


def test_staked_rate_is_positive(staked_nft, npc, tetra):
    assert staked_nft.current_rate_for_user(tetra) > 0


def test_staked_rate_matches(staked_nft, npc, tetra):
    staker = staked_nft
    rate = staker.current_rate_for_user(tetra)

    # Conftest mines 5 blocks
    assert staker.reward_balance(tetra) == rate * 5

    # Check another
    chain.mine(1)
    assert staker.reward_balance(tetra) == rate * 6


def test_stake_rate_changes_on_wrap(staked_nft, npc, tetra):
    rate = staked_nft.current_rate_for_user(tetra)
    staked_nft.wrap({"from": tetra})
    assert staked_nft.current_rate_for_user(tetra) != rate


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


def test_multiplier_changes_in_new_epoch(
    staker, npc, multiholder, multiholder_portfolio
):
    npc.setApprovalForAll(staker, True, {"from": multiholder})
    staker.stake_npc(multiholder_portfolio, {"from": multiholder})
    init_multiplier = staker.calc_avg_multiplier(multiholder, staker.current_epoch())

    staker.admin_trigger_epoch("New thing", {"from": staker.owner()})
    assert init_multiplier != staker.calc_avg_multiplier(
        multiholder, staker.current_epoch()
    )


def test_wrap_via_staker(multistaked_nft, multiholder):
    assert multistaked_nft.nft_balance(multiholder) > 0
    init_bal = multistaked_nft.balanceOf(multiholder)

    multistaked_nft.wrap({"from": multiholder})
    assert multistaked_nft.nft_balance(multiholder) == 0
    assert init_bal == multistaked_nft.balanceOf(multiholder)


def test_multistaked_rate_constant(multistaked_nft, multiholder):
    rew_0 = multistaked_nft.reward_balance(multiholder)
    chain.mine(100)
    rew_1 = multistaked_nft.reward_balance(multiholder)
    chain.mine(100)
    rew_2 = multistaked_nft.reward_balance(multiholder)
    assert rew_2 - rew_1 == rew_1 - rew_0


def test_multistaked_rate_diff_on_new_epoch(multistaked_nft, multiholder):
    rew_0 = multistaked_nft.reward_balance(multiholder)
    chain.mine(100)
    rew_1 = multistaked_nft.reward_balance(multiholder)
    multistaked_nft.admin_trigger_epoch("New Epoch", {"from": multistaked_nft.owner()})

    chain.mine(100)
    rew_2 = multistaked_nft.reward_balance(multiholder)
    assert rew_2 - rew_1 != rew_1 - rew_0


def test_accrual_doesnt_reset_on_new_epoch(multistaked_nft, multiholder):
    first_rate = multistaked_nft.current_rate_for_user(multiholder)
    rew_0 = multistaked_nft.reward_balance(multiholder)
    chain.mine(100)
    rew_1 = multistaked_nft.reward_balance(multiholder)
    multistaked_nft.admin_trigger_epoch("New Epoch", {"from": multistaked_nft.owner()})
    rew_2 = multistaked_nft.reward_balance(multiholder)

    chain.mine(100)
    rew_3 = multistaked_nft.reward_balance(multiholder)

    assert rew_3 > rew_2
    assert rew_2 == rew_1 + first_rate
    assert rew_1 > rew_0
