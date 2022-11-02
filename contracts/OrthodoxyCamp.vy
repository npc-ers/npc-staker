# @version 0.3.7


from vyper.interfaces import ERC721
from vyper.interfaces import ERC20

interface ERC20Mint:
    def mint(recipient: address, amount: uint256): nonpayable

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

    self.inflation_rate = 1000  * 10 ** 18 / 7200    # aka 1000 per day
    self.interval = 1 # 5 * 60 * 60 * 24                 # aka 1 day

    self.owner = msg.sender
    self.launch_block = block.number


# INTERNAL

@internal
@view
def _current_epoch() -> uint256:
    return (block.number - self.launch_block) / self.interval


@internal
@view
def _epoch_at(block_height: uint256) -> uint256:
    return (block_height - self.launch_block) / self.interval 

@external
@view
def epoch_at(block_height: uint256) -> uint256:
    return self._epoch_at(block_height) 

@internal
@view
def _calc_avg_multiplier(user: address, epoch: uint256) -> uint256:
    adder: uint256 = 0
    for i in range(6000):
        if i >= len(self.staked_nfts[user]):
            break
        adder += self._calc_multiplier(self.staked_nfts[user][i] , epoch)
    return 10 ** 18 * adder / len(self.staked_nfts[user])

@internal
@view
def _recent_rewards(user: address) -> uint256:
    blocks: uint256 = block.number - self.period_user_start[user]
    weight: uint256 = len(self.staked_nfts[user]) * 10 ** 18 + self.staked_coin[user]
   
    nft_id: uint256 = self.staked_nfts[user][0] # <--- just do the math for one for now
    start_block: uint256 = self.period_user_start[user]
    this_epoch: uint256 = self._epoch_at(start_block)

    weight_tot: uint256 = 10 ** 18 * (start_block - this_epoch * self.interval) / self.interval # <-- Partial weight for first block
    multiplier_tot: uint256 = weight_tot * self._calc_avg_multiplier(user, this_epoch) / 10 ** 18

    this_epoch += 1
    end_epoch: uint256 = self._current_epoch()
    
    for i in range(52):              # Max at a year
        if this_epoch == end_epoch:
            break
        multiplier_tot += self._calc_avg_multiplier(user, this_epoch) # <--- Full weight
        weight_tot += 10 ** 18
        this_epoch += 1

    if this_epoch <= end_epoch:
        weight_tot += 10 ** 18 * (block.number - this_epoch * self.interval) / self.interval # <-- Partial weight for final block
        multiplier_tot += self._calc_avg_multiplier(user, this_epoch) * (block.number - this_epoch * self.interval) / self.interval / 10 ** 18

    base: uint256 = blocks * weight * self.inflation_rate / 10 ** 18 # <-- Unweighted val
    return base * multiplier_tot / weight_tot # <--- Weighted val


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
    """
    @dev Calc gas
    """
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

#@external
#def admin_trigger_epoch(unstake_type: bool):
#    """
#    @notice Admin function to set epoch
#    @param unstake_type Boolean, True to allow withdrawals
#    """
#    assert msg.sender == self.owner
#    self.can_unstake = unstake_type


