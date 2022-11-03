# @version 0.3.7


from vyper.interfaces import ERC721
from vyper.interfaces import ERC20

interface ERC20Mint:
    def mint(recipient: address, amount: uint256): nonpayable

interface ERC20Epoch:
    def current_epoch() -> uint256: view


nft: public(ERC721)
wnft: public(ERC20)
coin: public(ERC20)


# Map of NFT ids
staked_nfts: public(HashMap[address, DynArray[uint256, 6000]])

# wNFT balance
staked_coin: public(HashMap[address, uint256])

inflation_rate: public(uint256) # Rewards per block

# Historical total weights
period_user_start: public( HashMap[address, uint256] ) # User -> Block Height 
finalized_rewards: public( HashMap[address, uint256] ) # Finalized rewards from prior blocks


launch_block: public(uint256)
interval: uint256

owner: address

# CONSTRUCTOR

@external
def __init__(wnft: address):
    self.nft = ERC721(0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8)
    self.coin = ERC20(0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB)
    self.wnft = ERC20(wnft)
    self.inflation_rate = 1000  * 10 ** 18 / 7200 

    self.owner = msg.sender
    self.launch_block = block.number
    self.interval = 5 * 60 * 60 


# INTERNAL

@internal
@view
def _balance_of(user: address) -> uint256:
    return(len(self.staked_nfts[user]))


@external
@view
def balanceOf(user: address) -> uint256:
    return(self._balance_of(user))


@internal
@view
def _calc_avg_multiplier(user: address, epoch: uint256) -> uint256:
    adder: uint256 = 0
    for i in range(6000):
        if i >= len(self.staked_nfts[user]):
            break
        adder += self._calc_multiplier(self.staked_nfts[user][i] , epoch)

     
    return 10 ** 18 * adder / self._balance_of(user) 


@external
@view
def calc_avg_multiplier(user: address, epoch: uint256) -> uint256:
    return self._calc_avg_multiplier(user, epoch)


@internal
@view
def _current_epoch() -> uint256:
    return ERC20Epoch(self.coin.address).current_epoch()


@internal
@view
def _recent_rewards(user: address) -> uint256:
    blocks: uint256 = block.number - self.period_user_start[user]
    weight: uint256 = self._balance_of(user) * self._calc_avg_multiplier(user, self._current_epoch()) + self.staked_coin[user]
    
    return blocks * weight * self.inflation_rate  / 10 ** 18


@external
@view
def recent_rewards(user: address) -> uint256:
    return self._recent_rewards(user)


@internal
def _add_to_stake(user: address, weight: uint256):
    if self.period_user_start[user] > 0:
        self.finalized_rewards[user] += self._recent_rewards(user) 

    # Update weights
    self.period_user_start[user] = block.number


@internal
def _clear_staking(addr: address):
    self.staked_coin[addr] = 0
    self.staked_nfts[addr] = []
    self.finalized_rewards[addr] = 0


@internal
@view
def _reward_balance(addr: address) -> uint256:
    return self.finalized_rewards[addr] + self._recent_rewards(addr)


@external
@view
def current_epoch() -> uint256:
    return self._current_epoch()

@internal
@view
def _calc_multiplier(id: uint256, epoch: uint256) -> uint256:
    hash: bytes32 = keccak256( concat(convert(id, bytes32), convert(epoch, bytes32)  ))
    return convert(slice(hash,0,1), uint256) * 10 / 256 + 1


@external
@view
def calc_multiplier(id: uint256, epoch: uint256) -> uint256:
    return self._calc_multiplier(id, epoch)

# VIEWS

@external
@view
def reward_balance(addr: address) -> uint256:
    """
    @notice Check reward balance
    @param addr Address to check
    @return Amount of $THING earned
    """
    return self._reward_balance(addr) 



# STATE MODIFYING

@external
def stake_npc(nft_ids: DynArray[uint256, 100]):
    """
    @notice Stake an NPC to earn rewards
    @param nft_ids List of NPC ids to stake
    """
    assert self.nft.isApprovedForAll(msg.sender, self)
    #assert nft_id not in self.staked_nfts[msg.sender]
    
    for id in nft_ids:
        self.nft.transferFrom(msg.sender, self, id)
        self.staked_nfts[msg.sender].append(id)

    self._add_to_stake(msg.sender, len(nft_ids) * 10 ** 18)

@external
def stake_wnpc(quantity: uint256):
    """
    @notice Stake Wrapped NPC to earn rewards
    @param quantity Amount of NPC to stake
    """
    assert self.wnft.balanceOf(msg.sender) >= quantity 
    self.wnft.transferFrom(msg.sender, self, quantity)
    self.staked_coin[msg.sender] += quantity

    self._add_to_stake(msg.sender, quantity)

@external
def withdraw():
    """
    @notice Withdraw accrued $THING / $NPC if enabled
    @dev Admin must call admin_trigger_epoch
    """
    #assert self.can_unstake == True

    qty: uint256 = self.staked_coin[msg.sender] + self._reward_balance(msg.sender)
    nfts: DynArray[uint256, 6000] = self.staked_nfts[msg.sender]

    for i in nfts:
        self.nft.transferFrom(self, msg.sender, i)

    if self.staked_coin[msg.sender] > 0:
        self.wnft.transfer(msg.sender, self.staked_coin[msg.sender])

    contract_balance : uint256 = self.coin.balanceOf(self)
    if qty < contract_balance:
        self.coin.transfer(msg.sender, qty)
    else:
        ERC20Mint(self.coin.address).mint(msg.sender, qty - contract_balance)
        self.coin.transfer(msg.sender, contract_balance)

    self._clear_staking(msg.sender)


# ADMIN

@external
def admin_trigger_epoch(unstake_type: bool):
    """
    @notice Admin function to set epoch
    """
    assert msg.sender == self.owner
    pass



