import brownie
from brownie import *


def test_new_epoch(staker, alice, thing):
    cur_epoch = thing.current_epoch()
    staker.admin_trigger_epoch("New Thing", {"from": alice})
    assert thing.current_epoch() == cur_epoch + 1


def test_trigger_epoch_only_admin(staker, bob):
    with brownie.reverts():
        staker.admin_trigger_epoch("Hack Thing", {"from": bob})


def test_kill_switch_disables_inflation():
    pass
#OrthodoxyCamp.admin_force_withdraw - 0.0%
#    OrthodoxyCamp.admin_set_inflation - 0.0%
#    OrthodoxyCamp.admin_shutdown - 0.0%
#    OrthodoxyCamp.admin_transfer_owner - 0.0

#def test_

