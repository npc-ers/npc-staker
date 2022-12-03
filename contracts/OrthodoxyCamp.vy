# @version 0.3.7


from vyper.interfaces import ERC721
from vyper.interfaces import ERC20
from ESG_NPC import ESG_NPC
from tests.CurrentThing import CurrentThing


##############################################################################
# INTERFACES
##############################################################################

interface ERC20Mint:
    def mint(recipient: address, amount: uint256): nonpayable

interface ERC20Epoch:
    def current_epoch() -> uint256: view


##############################################################################
# STATE VARIABLES
##############################################################################

nft: public(ERC721)
wnft: public(ESG_NPC)
coin: public(CurrentThing)


# Map of NFT ids
staked_nfts: public(HashMap[address, DynArray[uint256, 6000]])

# wNFT balance
staked_coin: public(HashMap[address, uint256])

inflation_rate: public(uint256) # Rewards per block

# Historical total weights
period_user_start: public( HashMap[address, uint256] ) # User -> Block Height 
finalized_rewards: public( HashMap[address, uint256] ) # Finalized rewards from prior blocks

owner: public(address)

# Staked users
staked_users: public(DynArray[address, 6000])


##############################################################################
# INITIALIZATION
##############################################################################

@external
def __init__(nft: address, coin: address, wnft: address):
    #self.nft = ERC721(0xa5ea010a46EaE77bD20EEE754f6D15320358dfD8)
    #self.coin = ERC20(0x2c9084E65D046146d6CFc26Bf45F5b80042b90EB)
    self.nft = ERC721(nft)
    self.coin = ERC20(coin)
    self.wnft = ESG_NPC(wnft)
    self.nft.setApprovalForAll(wnft, True)
    self.inflation_rate = 1000  * 10 ** 18 / 7200 

    self.owner = msg.sender


##############################################################################
# VIEW FUNCTIONS
##############################################################################

@external
@view
def nft_balance(user: address) -> uint256:
    """
    @notice Check balance of NFTs (not wrapped NFTs) user has staked
    @param user Address of user
    @return User balance
    """
    return(self._nft_balance_of(user) )


@external
@view
def balanceOf(user: address) -> uint256:
    """
    @notice Check balance of NFTs + Wrapped NFTs user has staked
    @param user Address of user
    @return Total balance
    """
    return(self._nft_balance_of(user) * 10 ** 18 + self.staked_coin[user]) 


@external
@view
def bulk_bonus(quantity: uint256) -> uint256:
    """
    @notice Calculate bonus multiplier applied for staking several NFTs
    @param quantity Balance of NFTs to stake
    @return Multiplier, 18 digits
    """
    return self._bulk_bonus(quantity)


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


@external
@view
def recent_rewards(user: address) -> uint256:
    """
    @notice Rewards earned this epoch
    @param user Address of user
    @return Rewards accumulated just this epoch
    """
    return self._recent_rewards(user)


@external
@view
def current_epoch() -> uint256:
    """
    @notice Calculate the current epoch number
    @return Epoch number
    """
    return self._current_epoch()


@external
@view
def calc_multiplier(id: uint256, epoch: uint256) -> uint256:
    """
    @notice Calculate the multiplier for a single NFT in a single epoch
    @param id NFT identifier
    @param epoch Epoch number
    @return Multiplier for staking single NFT, 18 digits
    """
    return self._calc_multiplier(id, epoch)


@external
@view
def reward_balance(addr: address) -> uint256:
    """
    @notice Check reward balance
    @param addr Address to check
    @return Amount of $THING available to claim
    """
    return self._reward_balance(addr) 


@external
@view
def current_rate_for_user(addr: address) -> uint256:
    """
    @notice Earnings per block for user
    """
    return self._curr_weight_for_user(addr) * self.inflation_rate / 10 ** 18


##############################################################################
# STATE MODIFYING FUNCTIONS
##############################################################################

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
    
    self._add_to_staked_users(msg.sender)
    self._store_recent_rewards(msg.sender)


@external
def stake_wnpc(quantity: uint256):
    """
    @notice Stake Wrapped NPC to earn rewards
    @param quantity Amount of NPC to stake
    """
    assert self.wnft.balanceOf(msg.sender) >= quantity 
    # Staking minimum
    assert quantity > 10 ** 18 

    self.wnft.transferFrom(msg.sender, self, quantity)
    self.staked_coin[msg.sender] += quantity

    self._add_to_staked_users(msg.sender)
    self._store_recent_rewards(msg.sender)


@external
def withdraw():
    """
    @notice Withdraw accrued $THING and $NPC if enabled
    """
    self._withdraw(msg.sender)


@external
def wrap():
    """
    @notice Wrap all staked NFTs into Wrapped NFTs
    """
    self._wrap_for_user(msg.sender)
    self._store_recent_rewards(msg.sender)


@external
def withdraw_wrapped():
    """
    @notice Wrap, then withdraw all accrued $THING and wrapped NFTs
    """
    self._wrap_for_user(msg.sender)
    self._withdraw(msg.sender)


@external
def withdraw_rewards():
    """
    @notice Withdraw accrued $THING rewards
    """
    self._withdraw_rewards(msg.sender)



##############################################################################
# ADMIN FUNCTIONS
##############################################################################


@external
def admin_trigger_epoch(current_thing: String[256]):
    """
    @notice Admin function to set epoch
    """
    assert msg.sender == self.owner
    self._close_epoch_rewards()
    self.coin.new_current_thing(current_thing)


##############################################################################
# INTERNAL FUNCTIONS
##############################################################################

@internal
@view
def _nft_balance_of(user: address) -> uint256:
    return(len(self.staked_nfts[user]))


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


@internal
@view
def _calc_avg_coin_multiplier(bal: uint256, epoch: uint256) -> uint256:
    adder: uint256 = 0
    for i in range(10):
        adder += self._calc_multiplier(i, epoch) 

    # Returns sqrt 10 ** 18 == 10 ** 9, times 10 iterations
    return adder * self._bulk_bonus(bal) / 10 ** 10


@internal
@view
def _bulk_bonus(quantity: uint256) -> uint256:
    return isqrt(quantity * 10 ** 18 * 10 ** 18)


@internal
@view
def _current_epoch() -> uint256:
    return ERC20Epoch(self.coin.address).current_epoch()


@internal
@view
def _curr_weight_for_user(user: address) -> uint256:
    _nft_weight: uint256 = 0
    if self._nft_balance_of(user) > 0:
        _nft_weight += self._nft_balance_of(user) * self._calc_avg_multiplier(user, self._current_epoch())

    _coin_weight: uint256 = self.staked_coin[user] * self._calc_avg_coin_multiplier(self.staked_coin[user], self._current_epoch()) 
    return _nft_weight + _coin_weight    


@internal
@view
def _recent_rewards(user: address) -> uint256:
    blocks: uint256 = block.number - self.period_user_start[user]
    return blocks * self._curr_weight_for_user(user) * self.inflation_rate  / 10 ** 18


@internal
def _store_recent_rewards(user: address):
    if self.period_user_start[user] > 0:
        self.finalized_rewards[user] += self._recent_rewards(user) 

    # Update weights
    self.period_user_start[user] = block.number


@internal
def _close_epoch_rewards():
    for i in self.staked_users: 
        self._store_recent_rewards(i)


@internal
def _clear_staking(addr: address):
    self.staked_coin[addr] = 0
    self.staked_nfts[addr] = []
    self._remove_from_staked_users(addr)


@internal
@view
def _reward_balance(addr: address) -> uint256:
    return self.finalized_rewards[addr] + self._recent_rewards(addr)


@internal
@view
def _calc_multiplier(id: uint256, epoch: uint256) -> uint256:
    hash: bytes32 = keccak256( concat(convert(id, bytes32), convert(epoch, bytes32) ))

    ret_val: uint256 = 1
    for i in range(10):
        if convert(slice(hash,i,1), uint256) < 20:
            ret_val += 1

    return ret_val 

@internal
def _withdraw(user: address):

    # Withdraw NPCs
    if len(self.staked_nfts[user]) > 0:
        nfts: DynArray[uint256, 6000] = self.staked_nfts[user]
        for i in nfts:
            self.nft.transferFrom(self, user, i)

    # Withdraw Wrapped NPCs
    if self.staked_coin[user] > 0:
        self.wnft.transfer(user, self.staked_coin[user])

    # Withdraw $THING
    self._withdraw_rewards(user)
    self._clear_staking(user)


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


@internal
def _add_to_staked_users(user: address):
    if user not in self.staked_users:
        self.staked_users.append(user)


@internal
def _remove_from_staked_users(user: address):
    assert user != empty(address)
    assert user in self.staked_users

    temp_array: DynArray[address, 6000] = []

    for cur_user in self.staked_users:
        if cur_user != user:
            temp_array.append(cur_user)

    self.staked_users = temp_array




