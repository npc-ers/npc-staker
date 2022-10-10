# @version 0.3.7


from vyper.interfaces import ERC721
from vyper.interfaces import ERC20

interface ERC20Mint:
    def mint(recipient: address, amount: uint256): nonpayable

nft: public(ERC721)
coin: public(ERC20)


staked_nfts: public(HashMap[address, DynArray[uint256, 6000]])
staked_coin: public(HashMap[address, uint256])

can_unstake: bool
owner: address

@external
def __init__():
    self.nft = ERC721(0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8)
    self.coin = ERC20(0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB)
    self.can_unstake = False
    self.owner = msg.sender

@external
def stake_npc(nft_id: uint256):
    """
    @notice Stake an NPC to earn rewards
    @param nft_id ID of NPC to stake
    """

    assert self.nft.ownerOf(nft_id) == msg.sender
    assert nft_id not in self.staked_nfts[msg.sender]

    self.nft.transferFrom(msg.sender, self, nft_id)
    self.staked_nfts[msg.sender].append(nft_id)

@external
def stake_thing(quantity: uint256):
    """
    @notice Stake $THING to earn rewards
    @param quantity Quantity of $THING to stake
    """
    assert self.coin.balanceOf(msg.sender) >= quantity 
    self.coin.transferFrom(msg.sender, self, quantity)
    self.staked_coin[msg.sender] += quantity

@internal
def _clear_staking(addr: address):
    self.staked_coin[addr] = 0
    self.staked_nfts[addr] = []


@internal
@view
def _reward_balance(addr: address) -> uint256:
    """
    @dev Whatever reward logic goes in here
    """
    return 1000 * 10 ** 18

@external
@view
def reward_balance(addr: address) -> uint256:
    """
    @notice Check reward balance
    @param addr Address to check
    @return Amount of $THING earned
    """
    return self._reward_balance(addr) 


@external
def withdraw():
    """
    @notice Withdraw accrued $THING / $NPC if enabled
    @dev Admin must call admin_trigger_epoch
    """
    assert self.can_unstake == True

    qty: uint256 = self.staked_coin[msg.sender] + self._reward_balance(msg.sender)
    nfts: DynArray[uint256, 6000] = self.staked_nfts[msg.sender]

    self._clear_staking(msg.sender)

    contract_balance : uint256 = self.coin.balanceOf(self)
    if qty < contract_balance:
        self.coin.transferFrom(self, msg.sender, qty)
    else:
        ERC20Mint(self.coin.address).mint(msg.sender, qty - contract_balance)
        self.coin.transferFrom(self, msg.sender, contract_balance)

    for i in nfts:
        self.nft.transferFrom(self, msg.sender, i)



@external
def admin_trigger_epoch(unstake_type: bool):
    """
    @notice Admin function to set epoch
    @param unstake_type Boolean, True to allow withdrawals
    """
    assert msg.sender == self.owner
    self.can_unstake = unstake_type
