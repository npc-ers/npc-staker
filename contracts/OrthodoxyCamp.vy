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
@pure
def cbrt(x: uint256) -> uint256:
    """
    @notice Calculate the cubic root of a number in 1e18 precision
    @dev Consumes around 1500 gas units
    @param x The number to calculate the cubic root of
    @return The cubic root of the number
    """

    # We artificially set a cap to the values for which we can compute the
    # cube roots safely. This is not to say that there are no values above
    # max(uint256) // 10**36 for which we cannot get good cube root estimates.
    # Beyond this point, accuracy is not guaranteed as overflows start to occur:
    assert x < 115792089237316195423570985008687907853269, "inaccurate cbrt"

    # We multiply the input `x` by 10 ** 36 to increase the precision of the
    # calculated cube root, such that: cbrt(10**18) = 10**18, cbrt(1) = 10**12
    x_squared: uint256 = unsafe_mul(x, 10**36)

    # ---- CALCULATE INITIAL GUESS FOR CUBE ROOT ---- #
    # We can guess the cube root of `x` using cheap integer operations. The guess
    # is calculated as follows:
    #    y = cbrt(a)
    # => y = cbrt(2**log2(a)) # <-- substituting `a = 2 ** log2(a)`
    # => y = 2**(log2(a) / 3) ≈ 2**|log2(a)/3|

    # Calculate log2(x). The following is inspire from:
    #
    # This was inspired from Stanford's 'Bit Twiddling Hacks' by Sean Eron Anderson:
    # https://graphics.stanford.edu/~seander/bithacks.html#IntegerLog
    #
    # More inspiration was derived from:
    # https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol

    log2x: int256 = 0
    if x_squared > 340282366920938463463374607431768211455:
        log2x = 128
    if unsafe_div(x_squared, shift(2, log2x)) > 18446744073709551615:
        log2x = log2x | 64
    if unsafe_div(x_squared, shift(2, log2x)) > 4294967295:
        log2x = log2x | 32
    if unsafe_div(x_squared, shift(2, log2x)) > 65535:
        log2x = log2x | 16
    if unsafe_div(x_squared, shift(2, log2x)) > 255:
        log2x = log2x | 8
    if unsafe_div(x_squared, shift(2, log2x)) > 15:
        log2x = log2x | 4
    if unsafe_div(x_squared, shift(2, log2x)) > 3:
        log2x = log2x | 2
    if unsafe_div(x_squared, shift(2, log2x)) > 1:
        log2x = log2x | 1

    # When we divide log2x by 3, the remainder is (log2x % 3).
    # So if we just multiply 2**(log2x/3) and discard the remainder to calculate our
    # guess, the newton method will need more iterations to converge to a solution,
    # since it is missing that precision. It's a few more calculations now to do less
    # calculations later:
    # pow = log2(x) // 3
    # remainder = log2(x) % 3
    # initial_guess = 2 ** pow * cbrt(2) ** remainder
    # substituting -> 2 = 1.26 ≈ 1260 / 1000, we get:
    #
    # initial_guess = 2 ** pow * 1260 ** remainder // 1000 ** remainder

    remainder: uint256 = convert(log2x, uint256) % 3
    cbrt_x: uint256 = unsafe_div(
        unsafe_mul(
            pow_mod256(
                2,
                unsafe_div(
                    convert(log2x, uint256), 3  # <- pow
                )
            ),
            pow_mod256(1260, remainder)
        ),
        pow_mod256(1000, remainder)
    )

    # Because we chose good initial values for cube roots, 7 newton raphson iterations
    # are just about sufficient. 6 iterations would result in non-convergences, and 8
    # would be one too many iterations. Without initial values, the iteration count
    # can go up to 20 or greater. The iterations are unrolled. This reduces gas costs
    # but takes up more bytecode:
    cbrt_x = unsafe_div(unsafe_add(unsafe_mul(2, cbrt_x), unsafe_div(x_squared, unsafe_mul(cbrt_x, cbrt_x))), 3)
    cbrt_x = unsafe_div(unsafe_add(unsafe_mul(2, cbrt_x), unsafe_div(x_squared, unsafe_mul(cbrt_x, cbrt_x))), 3)
    cbrt_x = unsafe_div(unsafe_add(unsafe_mul(2, cbrt_x), unsafe_div(x_squared, unsafe_mul(cbrt_x, cbrt_x))), 3)
    cbrt_x = unsafe_div(unsafe_add(unsafe_mul(2, cbrt_x), unsafe_div(x_squared, unsafe_mul(cbrt_x, cbrt_x))), 3)
    cbrt_x = unsafe_div(unsafe_add(unsafe_mul(2, cbrt_x), unsafe_div(x_squared, unsafe_mul(cbrt_x, cbrt_x))), 3)
    cbrt_x = unsafe_div(unsafe_add(unsafe_mul(2, cbrt_x), unsafe_div(x_squared, unsafe_mul(cbrt_x, cbrt_x))), 3)
    cbrt_x = unsafe_div(unsafe_add(unsafe_mul(2, cbrt_x), unsafe_div(x_squared, unsafe_mul(cbrt_x, cbrt_x))), 3)

    return cbrt_x


@internal
@view
def _bulk_bonus(quantity: uint256) -> uint256:
    return self.cbrt(quantity) * 10 ** 6

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

    return self._bulk_bonus(self._balance_of(user)) * adder / self._balance_of(user) 


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



