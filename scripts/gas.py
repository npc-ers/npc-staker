import warnings

from brownie import *

warnings.filterwarnings("ignore", category=DeprecationWarning)


def main():

    camp = OrthodoxyCamp.deploy(ZERO_ADDRESS, {"from": accounts[0]})
    thing = Contract("0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB")
    holder = "0x5881d9bfff787c8655a9b7f3484ae1a6f7a966e8"
    npc = Contract("0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8")
    thing.admin_set_minter(camp, {"from": thing.owner()})


    # Trial 1: Stake 1, withdraw after 10 blocks
    npc.setApprovalForAll(camp, True, {"from": holder})
    camp.stake_npc([601], {"from": holder})
    chain.mine(10)
    camp.withdraw({"from": holder})
    check_gas("\nTRIAL 1: Stake 1, withdraw quickly")
    chain.undo()
    print("Multiplier:", camp.calc_multiplier(601, 1))
    print(f"Bulk Bonus ({camp.balanceOf(holder)}):", camp.bulk_bonus(camp.balanceOf(holder)) / 10 ** 18)
    print("Rewards", camp.recent_rewards(holder) / 10**18)

    # Trial 2: Stake 2, withdraw after 10 blocks
    camp.stake_npc([4066], {"from": holder})
    chain.mine(10)
    camp.withdraw({"from": holder})
    check_gas("\nTRIAL 2: Stake 2, withdraw quickly")
    chain.undo()
    print("Avg. Multiplier:", camp.calc_avg_multiplier(holder, 1) / 10 ** 18)
    print(f"Bulk Bonus ({camp.balanceOf(holder)}):", camp.bulk_bonus(camp.balanceOf(holder)) / 10 ** 18)
    print("Rewards:", camp.recent_rewards(holder) / 10**18)

    # Trial 3: Stake 4, withdraw after 500 blocks
    camp.stake_npc([602, 599], {"from": holder})
    chain.mine(500)
    camp.withdraw({"from": holder})
    check_gas("\nTRIAL 3: Stake 3, withdraw after longer interval")
    chain.undo()
    print("Avg Multiplier:", camp.calc_avg_multiplier(holder, 1) / 10 ** 18)
    print(f"Bulk Bonus ({camp.balanceOf(holder)}):", camp.bulk_bonus(camp.balanceOf(holder)) / 10 ** 18)
    print("Rewards:", camp.recent_rewards(holder) / 10**18)

    # Trial 4: Stake several, withdraw after 500 blocks
    multisig = "0x8AaDe16ad409A19b0FF990B30a9a0E65d32DEa7D"
    npc.setApprovalForAll(camp, True, {"from": multisig})
    many_arr = [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
    camp.stake_npc(many_arr, {"from": multisig})
    chain.mine(500)
    camp.withdraw({"from": multisig})
    chain.undo()
    check_gas(f"\nTRIAL 4: Stake ({len(many_arr)}), withdraw after longer interval")
    print("Avg Multiplier:", camp.calc_avg_multiplier(multisig, 1) / 10 ** 18)
    print(f"Bulk Bonus ({camp.balanceOf(multisig)}):", camp.bulk_bonus(camp.balanceOf(multisig)) / 10 ** 18)
    print("Rewards:", camp.recent_rewards(multisig) / 10**18)


def check_gas(label=None):
    print(
        label,
        "\n",
        history[-1].gas_used,
        history[-1].gas_used * Wei("15 gwei") / 10**18,
        f"${history[-1].gas_used * Wei('15 gwei') / 10**18 * 1500}",
    )
