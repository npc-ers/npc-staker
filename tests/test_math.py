import brownie
import pytest
from brownie import *


def test_wrapping_within_same_scale(staked_nft, tetra):
    init_rate = staked_nft.current_rate_for_user(tetra)
    staked_nft.wrap({'from': tetra})
    final_rate = staked_nft.current_rate_for_user(tetra)
    assert final_rate / init_rate < 10

