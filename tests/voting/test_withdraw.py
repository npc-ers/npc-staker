from brownie import chain
import brownie


def test_cannot_withdraw_prematurely(staked_nft, tetra, thing, npc, holder):
    assert npc.balanceOf(tetra) == 0

    with brownie.reverts():
        staked_nft.withdraw({"from": tetra})


def test_withdraw_nft_balance_up(staked_nft, tetra, thing, alice, npc, holder):
    chain.mine(timedelta=1000)
    staked_nft.admin_trigger_epoch(True, {"from": alice})
    thing_init = thing.balanceOf(tetra)
    assert npc.balanceOf(tetra) == 0

    staked_nft.withdraw({"from": tetra})

    assert thing.balanceOf(tetra) > thing_init
    assert npc.balanceOf(tetra) > 0
