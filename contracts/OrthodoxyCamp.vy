# @version 0.3.7


from vyper.interfaces import ERC721
from vyper.interfaces import ERC20
from ESG_NPC import ESG_NPC

interface ERC20Mint:
    def mint(recipient: address, amount: uint256): nonpayable

interface ERC20Epoch:
    def current_epoch() -> uint256: view


nft: public(ERC721)
wnft: public(ESG_NPC)
coin: public(ERC20)


# Map of NFT ids
staked_nfts: public(HashMap[address, DynArray[uint256, 6000]])

# wNFT balance
staked_coin: public(HashMap[address, uint256])

inflation_rate: public(uint256) # Rewards per block

# Historical total weights
period_user_start: public( HashMap[address, uint256] ) # User -> Block Height 
finalized_rewards: public( HashMap[address, uint256] ) # Finalized rewards from prior blocks

owner: address

# CONSTRUCTOR

@external
def __init__(wnft: address):
    self.nft = ERC721(0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8)
    self.coin = ERC20(0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB)
    self.wnft = ESG_NPC(wnft)
    self.nft.setApprovalForAll(wnft, True)
    self.inflation_rate = 1000  * 10 ** 18 / 7200 

    self.owner = msg.sender


# INTERNAL

@internal
@view
def _nft_balance_of(user: address) -> uint256:
    return(len(self.staked_nfts[user]))


@external
@view
def nft_balance(user: address) -> uint256:
    return(self._nft_balance_of(user) )


@external
@view
def balanceOf(user: address) -> uint256:
    return(self._nft_balance_of(user) + self.staked_coin[user]) 


@internal
@view
def _bulk_bonus(quantity: uint256) -> uint256:
    return isqrt(quantity * 10 ** 18 * 10 ** 18)

@external
@view
def bulk_bonus(quantity: uint256) -> uint256:
    return self._bulk_bonus(quantity)

@internal
@view
def _calc_avg_multiplier(user: address, epoch: uint256) -> uint256:
    
    adder: uint256 = 0
    for i in range(6000):
        if i >= len(self.staked_nfts[user]):
            break
        adder += self._calc_multiplier(self.staked_nfts[user][i] , epoch)
   
    retval: uint256 = 0
    if self._nft_balance_of(user) > 0:
        retval = self._bulk_bonus(self._nft_balance_of(user)) * adder / self._nft_balance_of(user) 
    return retval


@external
@view
def calc_avg_multiplier(user: address, epoch: uint256) -> uint256:
    """
    @notice Average multiplier for a staked user's NFT collection
    @dev Reverts if no balance of staked NFTs
    @param user Staked user
    @param epoch Epoch to calculate
    @return Multiplier, 18 digits
    """
    return self._calc_avg_multiplier(user, epoch)


@internal
@view
def _calc_avg_coin_multiplier(bal: uint256, epoch: uint256) -> uint256:
    adder: uint256 = 0
    for i in range(10):
        adder += self._calc_multiplier(i, epoch) 

    # Returns sqrt 10 ** 18 == 10 ** 9, times 10 iterations
    return adder * self._bulk_bonus(bal) / 10 ** 10


@external
@view
def calc_avg_coin_multiplier(bal: uint256, epoch: uint256) -> uint256:
    """
    @notice Multiplier for depositing wrapped NPC
    @dev Calculated as the average multiplier for the first 10 NPCs
    @param bal Balance affects the bulk bonus
    @param epoch Weight at epoch
    @return Multiplier, 18 digits
    """
    return self._calc_avg_coin_multiplier(bal, epoch)


@internal
@view
def _current_epoch() -> uint256:
    return ERC20Epoch(self.coin.address).current_epoch()


@internal
@view
def _recent_rewards(user: address) -> uint256:
    blocks: uint256 = block.number - self.period_user_start[user]
    _nft_weight: uint256 = 0
    if self._nft_balance_of(user) > 0:
        _nft_weight += self._nft_balance_of(user) * self._calc_avg_multiplier(user, self._current_epoch())

    _coin_weight: uint256 = self.staked_coin[user] * self._calc_avg_coin_multiplier(self.staked_coin[user], self._current_epoch()) 
    weight: uint256 = _nft_weight + _coin_weight 
    
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
    hash: bytes32 = keccak256( concat(convert(id, bytes32), convert(epoch, bytes32) ))

    ret_val: uint256 = 1
    for i in range(10):
        if convert(slice(hash,i,1), uint256) < 20:
            ret_val += 1

    return ret_val 


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

@internal
def _withdraw(user: address):
  
    

    # Withdraw NPCs
    nfts: DynArray[uint256, 6000] = self.staked_nfts[user]
    for i in nfts:
        self.nft.transferFrom(self, user, i)

    # Withdraw Wrapped NPCs
    if self.staked_coin[user] > 0:
        self.wnft.transfer(user, self.staked_coin[user])

    # Withdraw $THING
    self._withdraw_rewards(user)
    self._clear_staking(user)

@external
def withdraw():
    """
    @notice Withdraw accrued $THING and $NPC if enabled
    @dev Admin must call admin_trigger_epoch
    """
    self._withdraw(msg.sender)

@internal
def _wrap_for_user(user: address):
    _bal: uint256 = 0
    for i in range(6000):
        if i >= len(self.staked_nfts[user]):
            break
        self.wnft.wrap([i])
        _bal += 10 ** 18
    self.staked_nfts[user] = []
    self.staked_coin[user] += _bal

@external
def withdraw_wrapped():
    """
    @notice Withdraw accrued $THING and $NPC if enabled
    @dev Admin must call admin_trigger_epoch
    """
    self._wrap_for_user(msg.sender)
    self._withdraw(msg.sender)

@internal
def _withdraw_rewards(user: address):
    """
    @dev XXX Needs test to make sure rewards cannot be retriggered 
    """
    qty: uint256 = self.staked_coin[user] + self._reward_balance(user)
    contract_balance : uint256 = self.coin.balanceOf(self)
    if qty < contract_balance:
        self.coin.transfer(user, qty)
    else:
        ERC20Mint(self.coin.address).mint(user, qty - contract_balance)
        self.coin.transfer(user, contract_balance)

    self.period_user_start[user] = block.number
    self.finalized_rewards[user] = 0


@external
def withdraw_rewards():
    """
    @notice Withdraw accrued $THING 
    @dev Admin must call admin_trigger_epoch
    """
    self._withdraw_rewards(msg.sender)



# ADMIN

@external
def admin_trigger_epoch(unstake_type: bool):
    """
    @notice Admin function to set epoch
    """
    assert msg.sender == self.owner
    pass



