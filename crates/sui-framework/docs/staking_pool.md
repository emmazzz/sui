
<a name="0x2_staking_pool"></a>

# Module `0x2::staking_pool`



-  [Struct `StakingPool`](#0x2_staking_pool_StakingPool)
-  [Struct `PoolTokenExchangeRate`](#0x2_staking_pool_PoolTokenExchangeRate)
-  [Resource `InactiveStakingPool`](#0x2_staking_pool_InactiveStakingPool)
-  [Struct `PendingWithdrawEntry`](#0x2_staking_pool_PendingWithdrawEntry)
-  [Resource `StakedSui`](#0x2_staking_pool_StakedSui)
-  [Constants](#@Constants_0)
-  [Function `new`](#0x2_staking_pool_new)
-  [Function `request_add_delegation`](#0x2_staking_pool_request_add_delegation)
-  [Function `request_withdraw_delegation`](#0x2_staking_pool_request_withdraw_delegation)
-  [Function `claim_rewards`](#0x2_staking_pool_claim_rewards)
-  [Function `unwrap_staked_sui`](#0x2_staking_pool_unwrap_staked_sui)
-  [Function `deposit_rewards`](#0x2_staking_pool_deposit_rewards)
-  [Function `process_pending_delegation_withdraws`](#0x2_staking_pool_process_pending_delegation_withdraws)
-  [Function `process_pending_delegation`](#0x2_staking_pool_process_pending_delegation)
-  [Function `deactivate_staking_pool`](#0x2_staking_pool_deactivate_staking_pool)
-  [Function `sui_balance`](#0x2_staking_pool_sui_balance)
-  [Function `validator_address`](#0x2_staking_pool_validator_address)
-  [Function `staked_sui_amount`](#0x2_staking_pool_staked_sui_amount)
-  [Function `delegation_activation_epoch`](#0x2_staking_pool_delegation_activation_epoch)
-  [Function `delegation_deactivation_epoch`](#0x2_staking_pool_delegation_deactivation_epoch)
-  [Function `delegation_status`](#0x2_staking_pool_delegation_status)
-  [Function `pool_token_exchange_rate_at_epoch`](#0x2_staking_pool_pool_token_exchange_rate_at_epoch)
-  [Function `get_sui_amount`](#0x2_staking_pool_get_sui_amount)
-  [Function `get_token_amount`](#0x2_staking_pool_get_token_amount)
-  [Function `increment_or_insert_pending_withdraw`](#0x2_staking_pool_increment_or_insert_pending_withdraw)
-  [Function `diff_if_greater`](#0x2_staking_pool_diff_if_greater)


<pre><code><b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="balance.md#0x2_balance">0x2::balance</a>;
<b>use</b> <a href="coin.md#0x2_coin">0x2::coin</a>;
<b>use</b> <a href="epoch_time_lock.md#0x2_epoch_time_lock">0x2::epoch_time_lock</a>;
<b>use</b> <a href="locked_coin.md#0x2_locked_coin">0x2::locked_coin</a>;
<b>use</b> <a href="math.md#0x2_math">0x2::math</a>;
<b>use</b> <a href="object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="sui.md#0x2_sui">0x2::sui</a>;
<b>use</b> <a href="table.md#0x2_table">0x2::table</a>;
<b>use</b> <a href="transfer.md#0x2_transfer">0x2::transfer</a>;
<b>use</b> <a href="tx_context.md#0x2_tx_context">0x2::tx_context</a>;
</code></pre>



<a name="0x2_staking_pool_StakingPool"></a>

## Struct `StakingPool`

A staking pool embedded in each validator struct in the system state object.


<pre><code><b>struct</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>validator_address: <b>address</b></code>
</dt>
<dd>
 The sui address of the validator associated with this pool.
</dd>
<dt>
<code>starting_epoch: u64</code>
</dt>
<dd>
 The epoch at which this pool started operating. Should be the epoch at which the validator became active.
</dd>
<dt>
<code>sui_balance: u64</code>
</dt>
<dd>
 The total number of SUI tokens in this pool, including the SUI in the rewards_pool, as well as in all the principal
 in the <code><a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a></code> object, updated at epoch boundaries.
</dd>
<dt>
<code>rewards_pool: <a href="balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="sui.md#0x2_sui_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>
 The epoch delegation rewards will be added here at the end of each epoch.
</dd>
<dt>
<code>pool_token_balance: u64</code>
</dt>
<dd>
 Total number of pool tokens issued by the pool.
</dd>
<dt>
<code>exchange_rates: <a href="table.md#0x2_table_Table">table::Table</a>&lt;u64, <a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">staking_pool::PoolTokenExchangeRate</a>&gt;</code>
</dt>
<dd>
 Exchange rate history of previous epochs. Key is the epoch number.
</dd>
<dt>
<code>pending_delegation: u64</code>
</dt>
<dd>
 Pending delegation amount for this epoch.
</dd>
<dt>
<code>pending_withdraws: <a href="table.md#0x2_table_Table">table::Table</a>&lt;u64, <a href="staking_pool.md#0x2_staking_pool_PendingWithdrawEntry">staking_pool::PendingWithdrawEntry</a>&gt;</code>
</dt>
<dd>
 Cumulated delegation withdraws where the key is the epoch at which the withdraws should be processed.
</dd>
<dt>
<code>unclaimed_rewards: <a href="balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="sui.md#0x2_sui_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>
 Stores the rewards that are ready to be claimed. This doesn't count towards the stake distribution.
</dd>
</dl>


</details>

<a name="0x2_staking_pool_PoolTokenExchangeRate"></a>

## Struct `PoolTokenExchangeRate`

Struct representing the exchange rate of the delegation pool token to SUI.


<pre><code><b>struct</b> <a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">PoolTokenExchangeRate</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>sui_amount: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>pool_token_amount: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x2_staking_pool_InactiveStakingPool"></a>

## Resource `InactiveStakingPool`

An inactive staking pool associated with an inactive validator.
Only withdraws can be made from this pool.


<pre><code><b>struct</b> <a href="staking_pool.md#0x2_staking_pool_InactiveStakingPool">InactiveStakingPool</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="object.md#0x2_object_UID">object::UID</a></code>
</dt>
<dd>

</dd>
<dt>
<code>pool: <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x2_staking_pool_PendingWithdrawEntry"></a>

## Struct `PendingWithdrawEntry`

Struct representing a pending delegation withdraw.


<pre><code><b>struct</b> <a href="staking_pool.md#0x2_staking_pool_PendingWithdrawEntry">PendingWithdrawEntry</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>total_principal_withdraw_amount: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>total_pool_token_withdraw_amount: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x2_staking_pool_StakedSui"></a>

## Resource `StakedSui`

A self-custodial object holding the staked SUI tokens.


<pre><code><b>struct</b> <a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="object.md#0x2_object_UID">object::UID</a></code>
</dt>
<dd>

</dd>
<dt>
<code>validator_address: <b>address</b></code>
</dt>
<dd>
 The validator we are staking with.
</dd>
<dt>
<code>pool_starting_epoch: u64</code>
</dt>
<dd>
 The epoch at which the staking pool started operating.
</dd>
<dt>
<code>delegation_activation_epoch: u64</code>
</dt>
<dd>
 The epoch at which the delegation becomes active.
</dd>
<dt>
<code>delegation_deactivation_epoch: <a href="_Option">option::Option</a>&lt;u64&gt;</code>
</dt>
<dd>
 The epoch at which the delegation becomes deactive.
 This field is none if the delegation is still active.
</dd>
<dt>
<code>principal: <a href="balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="sui.md#0x2_sui_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>
 The staked SUI tokens.
</dd>
<dt>
<code>sui_token_lock: <a href="_Option">option::Option</a>&lt;<a href="epoch_time_lock.md#0x2_epoch_time_lock_EpochTimeLock">epoch_time_lock::EpochTimeLock</a>&gt;</code>
</dt>
<dd>
 If the stake comes from a Coin<SUI>, this field is None. If it comes from a LockedCoin<SUI>, this
 field will record the original lock expiration epoch, to be used when unstaking.
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x2_staking_pool_ACTIVE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_ACTIVE">ACTIVE</a>: u64 = 1;
</code></pre>



<a name="0x2_staking_pool_DEACTIVE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_DEACTIVE">DEACTIVE</a>: u64 = 3;
</code></pre>



<a name="0x2_staking_pool_EDESTROY_NON_ZERO_BALANCE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_EDESTROY_NON_ZERO_BALANCE">EDESTROY_NON_ZERO_BALANCE</a>: u64 = 5;
</code></pre>



<a name="0x2_staking_pool_EINSUFFICIENT_POOL_TOKEN_BALANCE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_EINSUFFICIENT_POOL_TOKEN_BALANCE">EINSUFFICIENT_POOL_TOKEN_BALANCE</a>: u64 = 0;
</code></pre>



<a name="0x2_staking_pool_EINSUFFICIENT_REWARDS_POOL_BALANCE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_EINSUFFICIENT_REWARDS_POOL_BALANCE">EINSUFFICIENT_REWARDS_POOL_BALANCE</a>: u64 = 4;
</code></pre>



<a name="0x2_staking_pool_EINSUFFICIENT_SUI_TOKEN_BALANCE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_EINSUFFICIENT_SUI_TOKEN_BALANCE">EINSUFFICIENT_SUI_TOKEN_BALANCE</a>: u64 = 3;
</code></pre>



<a name="0x2_staking_pool_EPENDING_DELEGATION_DOES_NOT_EXIST"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_EPENDING_DELEGATION_DOES_NOT_EXIST">EPENDING_DELEGATION_DOES_NOT_EXIST</a>: u64 = 8;
</code></pre>



<a name="0x2_staking_pool_ESTATUS_NOT_ACTIVE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_ESTATUS_NOT_ACTIVE">ESTATUS_NOT_ACTIVE</a>: u64 = 9;
</code></pre>



<a name="0x2_staking_pool_ESTATUS_NOT_DEACTIVE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_ESTATUS_NOT_DEACTIVE">ESTATUS_NOT_DEACTIVE</a>: u64 = 10;
</code></pre>



<a name="0x2_staking_pool_ETOKEN_TIME_LOCK_IS_SOME"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_ETOKEN_TIME_LOCK_IS_SOME">ETOKEN_TIME_LOCK_IS_SOME</a>: u64 = 6;
</code></pre>



<a name="0x2_staking_pool_EWITHDRAW_AMOUNT_CANNOT_BE_ZERO"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_EWITHDRAW_AMOUNT_CANNOT_BE_ZERO">EWITHDRAW_AMOUNT_CANNOT_BE_ZERO</a>: u64 = 2;
</code></pre>



<a name="0x2_staking_pool_EWRONG_DELEGATION"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_EWRONG_DELEGATION">EWRONG_DELEGATION</a>: u64 = 7;
</code></pre>



<a name="0x2_staking_pool_EWRONG_POOL"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_EWRONG_POOL">EWRONG_POOL</a>: u64 = 1;
</code></pre>



<a name="0x2_staking_pool_PENDING_ACTIVE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_PENDING_ACTIVE">PENDING_ACTIVE</a>: u64 = 0;
</code></pre>



<a name="0x2_staking_pool_PENDING_DEACTIVE"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_PENDING_DEACTIVE">PENDING_DEACTIVE</a>: u64 = 2;
</code></pre>



<a name="0x2_staking_pool_UNBONDING_PERIOD_LENGTH"></a>



<pre><code><b>const</b> <a href="staking_pool.md#0x2_staking_pool_UNBONDING_PERIOD_LENGTH">UNBONDING_PERIOD_LENGTH</a>: u64 = 0;
</code></pre>



<a name="0x2_staking_pool_new"></a>

## Function `new`

Create a new, empty staking pool.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_new">new</a>(validator_address: <b>address</b>, starting_epoch: u64, ctx: &<b>mut</b> <a href="tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_new">new</a>(validator_address: <b>address</b>, starting_epoch: u64, ctx: &<b>mut</b> TxContext) : <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a> {
    <b>let</b> exchange_rates = <a href="table.md#0x2_table_new">table::new</a>(ctx);
    <a href="table.md#0x2_table_add">table::add</a>(
        &<b>mut</b> exchange_rates,
        <a href="tx_context.md#0x2_tx_context_epoch">tx_context::epoch</a>(ctx),
        <a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">PoolTokenExchangeRate</a> { sui_amount: 0, pool_token_amount: 0 }
    );
    <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a> {
        validator_address,
        starting_epoch,
        sui_balance: 0,
        rewards_pool: <a href="balance.md#0x2_balance_zero">balance::zero</a>(),
        pool_token_balance: 0,
        exchange_rates,
        pending_delegation: 0,
        pending_withdraws: <a href="table.md#0x2_table_new">table::new</a>(ctx),
        unclaimed_rewards: <a href="balance.md#0x2_balance_zero">balance::zero</a>(),
    }
}
</code></pre>



</details>

<a name="0x2_staking_pool_request_add_delegation"></a>

## Function `request_add_delegation`

Request to delegate to a staking pool. The delegation gets counted at the beginning of the next epoch,
when the delegation object containing the pool tokens is distributed to the delegator.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_request_add_delegation">request_add_delegation</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>, <a href="stake.md#0x2_stake">stake</a>: <a href="balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, sui_token_lock: <a href="_Option">option::Option</a>&lt;<a href="epoch_time_lock.md#0x2_epoch_time_lock_EpochTimeLock">epoch_time_lock::EpochTimeLock</a>&gt;, delegator: <b>address</b>, ctx: &<b>mut</b> <a href="tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_request_add_delegation">request_add_delegation</a>(
    pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>,
    <a href="stake.md#0x2_stake">stake</a>: Balance&lt;SUI&gt;,
    sui_token_lock: Option&lt;EpochTimeLock&gt;,
    delegator: <b>address</b>,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> sui_amount = <a href="balance.md#0x2_balance_value">balance::value</a>(&<a href="stake.md#0x2_stake">stake</a>);
    <b>assert</b>!(sui_amount &gt; 0, 0);
    <b>let</b> staked_sui = <a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a> {
        id: <a href="object.md#0x2_object_new">object::new</a>(ctx),
        validator_address: pool.validator_address,
        pool_starting_epoch: pool.starting_epoch,
        delegation_activation_epoch: <a href="tx_context.md#0x2_tx_context_epoch">tx_context::epoch</a>(ctx) + 1,
        delegation_deactivation_epoch: none(),
        principal: <a href="stake.md#0x2_stake">stake</a>,
        sui_token_lock,
    };
    pool.pending_delegation = pool.pending_delegation + sui_amount;
    <a href="transfer.md#0x2_transfer_transfer">transfer::transfer</a>(staked_sui, delegator);
}
</code></pre>



</details>

<a name="0x2_staking_pool_request_withdraw_delegation"></a>

## Function `request_withdraw_delegation`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_request_withdraw_delegation">request_withdraw_delegation</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>, staked_sui: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakedSui">staking_pool::StakedSui</a>, ctx: &<b>mut</b> <a href="tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_request_withdraw_delegation">request_withdraw_delegation</a>(
    pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>,
    staked_sui: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a>,
    ctx: &<b>mut</b> TxContext
) {
    // check that the delegation is active.
    <b>assert</b>!(<a href="staking_pool.md#0x2_staking_pool_delegation_status">delegation_status</a>(staked_sui, ctx) == <a href="staking_pool.md#0x2_staking_pool_ACTIVE">ACTIVE</a>, <a href="staking_pool.md#0x2_staking_pool_ESTATUS_NOT_ACTIVE">ESTATUS_NOT_ACTIVE</a>);

    // calculate the amount of pool token <b>to</b> withdraw using the exchange rate at staking time.
    <b>let</b> principal_withdraw_amount = <a href="balance.md#0x2_balance_value">balance::value</a>(&staked_sui.principal);
    <b>let</b> exchange_rate_at_staking_epoch = <a href="staking_pool.md#0x2_staking_pool_pool_token_exchange_rate_at_epoch">pool_token_exchange_rate_at_epoch</a>(pool, staked_sui.delegation_activation_epoch);
    <b>let</b> pool_token_withdraw_amount = <a href="staking_pool.md#0x2_staking_pool_get_token_amount">get_token_amount</a>(&exchange_rate_at_staking_epoch, principal_withdraw_amount);

    <b>let</b> delegation_deactivation_epoch = <a href="tx_context.md#0x2_tx_context_epoch">tx_context::epoch</a>(ctx) + 1 + <a href="staking_pool.md#0x2_staking_pool_UNBONDING_PERIOD_LENGTH">UNBONDING_PERIOD_LENGTH</a>;

    <a href="_fill">option::fill</a>(&<b>mut</b> staked_sui.delegation_deactivation_epoch, delegation_deactivation_epoch);

    // add the withdraw amounts <b>to</b> cumulated withdraw amounts for that epoch.
    <a href="staking_pool.md#0x2_staking_pool_increment_or_insert_pending_withdraw">increment_or_insert_pending_withdraw</a>(
        &<b>mut</b> pool.pending_withdraws,
        delegation_deactivation_epoch,
        principal_withdraw_amount,
        pool_token_withdraw_amount,
    );
}
</code></pre>



</details>

<a name="0x2_staking_pool_claim_rewards"></a>

## Function `claim_rewards`

Claim the principal and rewards earned from the deactive delegation.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_claim_rewards">claim_rewards</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>, staked_sui: <a href="staking_pool.md#0x2_staking_pool_StakedSui">staking_pool::StakedSui</a>, ctx: &<b>mut</b> <a href="tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_claim_rewards">claim_rewards</a>(
    pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>,
    staked_sui: <a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a>,
    ctx: &<b>mut</b> TxContext
) {
    // check that the delegation is active.
    <b>assert</b>!(<a href="staking_pool.md#0x2_staking_pool_delegation_status">delegation_status</a>(&staked_sui, ctx) == <a href="staking_pool.md#0x2_staking_pool_DEACTIVE">DEACTIVE</a>, <a href="staking_pool.md#0x2_staking_pool_ESTATUS_NOT_DEACTIVE">ESTATUS_NOT_DEACTIVE</a>);
    <b>let</b> delegator = <a href="tx_context.md#0x2_tx_context_sender">tx_context::sender</a>(ctx);
    <b>let</b> delegation_deactivation_epoch = *<a href="_borrow">option::borrow</a>(&staked_sui.delegation_deactivation_epoch);

    // calculate pool token amount.
    <b>let</b> exchange_rate_at_staking_epoch = <a href="staking_pool.md#0x2_staking_pool_pool_token_exchange_rate_at_epoch">pool_token_exchange_rate_at_epoch</a>(pool, staked_sui.delegation_activation_epoch);
    <b>let</b> principal_amount = <a href="balance.md#0x2_balance_value">balance::value</a>(&staked_sui.principal);
    <b>let</b> pool_token_amount = <a href="staking_pool.md#0x2_staking_pool_get_token_amount">get_token_amount</a>(&exchange_rate_at_staking_epoch, principal_amount);

    // calculate the total <a href="sui.md#0x2_sui">sui</a> amount including rewards using exchange rate at unstaking time.
    <b>let</b> exchange_rate_at_unstaking_epoch = <a href="staking_pool.md#0x2_staking_pool_pool_token_exchange_rate_at_epoch">pool_token_exchange_rate_at_epoch</a>(pool, delegation_deactivation_epoch);
    <b>let</b> total_sui_amount = <a href="staking_pool.md#0x2_staking_pool_get_sui_amount">get_sui_amount</a>(&exchange_rate_at_unstaking_epoch, pool_token_amount);

    // unwrap staked <a href="sui.md#0x2_sui">sui</a>, get the principal out
    <b>let</b> (principal, <a href="epoch_time_lock.md#0x2_epoch_time_lock">epoch_time_lock</a>) = <a href="staking_pool.md#0x2_staking_pool_unwrap_staked_sui">unwrap_staked_sui</a>(staked_sui);

    // get the rewards from unclaimed rewards
    <b>let</b> reward_withdraw_amount = <a href="staking_pool.md#0x2_staking_pool_diff_if_greater">diff_if_greater</a>(total_sui_amount, principal_amount);
    <b>let</b> reward = <a href="balance.md#0x2_balance_split">balance::split</a>(&<b>mut</b> pool.unclaimed_rewards, reward_withdraw_amount);

    // <a href="transfer.md#0x2_transfer">transfer</a> the principal and reward <b>to</b> the delegator
    <b>if</b> (<a href="_is_none">option::is_none</a>(&<a href="epoch_time_lock.md#0x2_epoch_time_lock">epoch_time_lock</a>)) {
        <a href="balance.md#0x2_balance_join">balance::join</a>(&<b>mut</b> principal, reward);
        <a href="transfer.md#0x2_transfer_transfer">transfer::transfer</a>(<a href="coin.md#0x2_coin_from_balance">coin::from_balance</a>(principal, ctx), delegator);
    } <b>else</b> {
        <a href="locked_coin.md#0x2_locked_coin_new_from_balance">locked_coin::new_from_balance</a>(principal, <a href="_extract">option::extract</a>(&<b>mut</b> <a href="epoch_time_lock.md#0x2_epoch_time_lock">epoch_time_lock</a>), delegator, ctx);
        <b>if</b> (reward_withdraw_amount &gt; 0) {
            <a href="transfer.md#0x2_transfer_transfer">transfer::transfer</a>(<a href="coin.md#0x2_coin_from_balance">coin::from_balance</a>(reward, ctx), delegator);
        } <b>else</b> {
            <a href="balance.md#0x2_balance_destroy_zero">balance::destroy_zero</a>(reward);
        }
    };
    <a href="_destroy_none">option::destroy_none</a>(<a href="epoch_time_lock.md#0x2_epoch_time_lock">epoch_time_lock</a>);
}
</code></pre>



</details>

<a name="0x2_staking_pool_unwrap_staked_sui"></a>

## Function `unwrap_staked_sui`



<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_unwrap_staked_sui">unwrap_staked_sui</a>(staked_sui: <a href="staking_pool.md#0x2_staking_pool_StakedSui">staking_pool::StakedSui</a>): (<a href="balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="_Option">option::Option</a>&lt;<a href="epoch_time_lock.md#0x2_epoch_time_lock_EpochTimeLock">epoch_time_lock::EpochTimeLock</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_unwrap_staked_sui">unwrap_staked_sui</a>(staked_sui: <a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a>): (Balance&lt;SUI&gt;, Option&lt;EpochTimeLock&gt;) {
    <b>let</b> <a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a> {
        id,
        validator_address: _,
        pool_starting_epoch: _,
        delegation_activation_epoch: _,
        delegation_deactivation_epoch: _,
        principal,
        sui_token_lock
    } = staked_sui;
    <a href="object.md#0x2_object_delete">object::delete</a>(id);
    (principal, sui_token_lock)
}
</code></pre>



</details>

<a name="0x2_staking_pool_deposit_rewards"></a>

## Function `deposit_rewards`

Called at epoch advancement times to add rewards (in SUI) to the staking pool.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_deposit_rewards">deposit_rewards</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>, rewards: <a href="balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, new_epoch: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_deposit_rewards">deposit_rewards</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>, rewards: Balance&lt;SUI&gt;, new_epoch: u64) {
    pool.sui_balance = pool.sui_balance + <a href="balance.md#0x2_balance_value">balance::value</a>(&rewards);
    <a href="balance.md#0x2_balance_join">balance::join</a>(&<b>mut</b> pool.rewards_pool, rewards);
    <a href="table.md#0x2_table_add">table::add</a>(
        &<b>mut</b> pool.exchange_rates,
        new_epoch,
        <a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">PoolTokenExchangeRate</a> { sui_amount: pool.sui_balance, pool_token_amount: pool.pool_token_balance },
    );
}
</code></pre>



</details>

<a name="0x2_staking_pool_process_pending_delegation_withdraws"></a>

## Function `process_pending_delegation_withdraws`

Called at epoch boundaries to process delegations that become deactive at the new epoch.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_process_pending_delegation_withdraws">process_pending_delegation_withdraws</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>, new_epoch: u64, ctx: &<b>mut</b> <a href="tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_process_pending_delegation_withdraws">process_pending_delegation_withdraws</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>, new_epoch: u64, ctx: &<b>mut</b> TxContext) : u64 {
    <b>if</b> (<a href="table.md#0x2_table_contains">table::contains</a>(&pool.pending_withdraws, new_epoch)) {
        <b>let</b> <a href="staking_pool.md#0x2_staking_pool_PendingWithdrawEntry">PendingWithdrawEntry</a> {
            total_pool_token_withdraw_amount,
            total_principal_withdraw_amount,
        } = <a href="table.md#0x2_table_remove">table::remove</a>(&<b>mut</b> pool.pending_withdraws, new_epoch);
        <b>let</b> new_epoch_exchange_rate = <a href="staking_pool.md#0x2_staking_pool_pool_token_exchange_rate_at_epoch">pool_token_exchange_rate_at_epoch</a>(pool, new_epoch);
        <b>let</b> total_sui_amount = <a href="staking_pool.md#0x2_staking_pool_get_sui_amount">get_sui_amount</a>(&new_epoch_exchange_rate, total_pool_token_withdraw_amount);

        <b>let</b> total_reward_withdraw_amount =
            sui::math::min(
                <a href="staking_pool.md#0x2_staking_pool_diff_if_greater">diff_if_greater</a>(total_sui_amount, total_principal_withdraw_amount),
                <a href="balance.md#0x2_balance_value">balance::value</a>(&pool.rewards_pool)
            );
        <b>let</b> total_sui_withdraw_amount = total_reward_withdraw_amount + total_principal_withdraw_amount;
        <a href="balance.md#0x2_balance_join">balance::join</a>(&<b>mut</b> pool.unclaimed_rewards, <a href="balance.md#0x2_balance_split">balance::split</a>(&<b>mut</b> pool.rewards_pool, total_reward_withdraw_amount));
        pool.sui_balance = pool.sui_balance - total_sui_withdraw_amount;
        pool.pool_token_balance = pool.pool_token_balance - total_pool_token_withdraw_amount;
        total_sui_withdraw_amount
    } <b>else</b> {
        0
    }
}
</code></pre>



</details>

<a name="0x2_staking_pool_process_pending_delegation"></a>

## Function `process_pending_delegation`

Called at epoch boundaries to process the pending delegation.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_process_pending_delegation">process_pending_delegation</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>, new_epoch: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_process_pending_delegation">process_pending_delegation</a>(pool: &<b>mut</b> <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>, new_epoch: u64) {
    <b>let</b> new_epoch_exchange_rate = <a href="staking_pool.md#0x2_staking_pool_pool_token_exchange_rate_at_epoch">pool_token_exchange_rate_at_epoch</a>(pool, new_epoch);
    pool.sui_balance = pool.sui_balance + pool.pending_delegation;
    pool.pool_token_balance = pool.pool_token_balance + <a href="staking_pool.md#0x2_staking_pool_get_token_amount">get_token_amount</a>(&new_epoch_exchange_rate, pool.pending_delegation);
    pool.pending_delegation = 0;
}
</code></pre>



</details>

<a name="0x2_staking_pool_deactivate_staking_pool"></a>

## Function `deactivate_staking_pool`

Deactivate a staking pool by wrapping it in an <code><a href="staking_pool.md#0x2_staking_pool_InactiveStakingPool">InactiveStakingPool</a></code> and sharing this newly created object.
After this pool deactivation, the pool stops earning rewards. Only delegation withdraws can be made to the pool.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_deactivate_staking_pool">deactivate_staking_pool</a>(pool: <a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>, ctx: &<b>mut</b> <a href="tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_deactivate_staking_pool">deactivate_staking_pool</a>(pool: <a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> inactive_pool = <a href="staking_pool.md#0x2_staking_pool_InactiveStakingPool">InactiveStakingPool</a> { id: <a href="object.md#0x2_object_new">object::new</a>(ctx), pool};
    <a href="transfer.md#0x2_transfer_share_object">transfer::share_object</a>(inactive_pool);
}
</code></pre>



</details>

<a name="0x2_staking_pool_sui_balance"></a>

## Function `sui_balance`



<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_sui_balance">sui_balance</a>(pool: &<a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_sui_balance">sui_balance</a>(pool: &<a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>) : u64 { pool.sui_balance }
</code></pre>



</details>

<a name="0x2_staking_pool_validator_address"></a>

## Function `validator_address`



<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_validator_address">validator_address</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">staking_pool::StakedSui</a>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_validator_address">validator_address</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a>) : <b>address</b> { staked_sui.validator_address }
</code></pre>



</details>

<a name="0x2_staking_pool_staked_sui_amount"></a>

## Function `staked_sui_amount`



<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_staked_sui_amount">staked_sui_amount</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">staking_pool::StakedSui</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_staked_sui_amount">staked_sui_amount</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a>): u64 { <a href="balance.md#0x2_balance_value">balance::value</a>(&staked_sui.principal) }
</code></pre>



</details>

<a name="0x2_staking_pool_delegation_activation_epoch"></a>

## Function `delegation_activation_epoch`



<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_delegation_activation_epoch">delegation_activation_epoch</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">staking_pool::StakedSui</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_delegation_activation_epoch">delegation_activation_epoch</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a>): u64 {
    staked_sui.delegation_activation_epoch
}
</code></pre>



</details>

<a name="0x2_staking_pool_delegation_deactivation_epoch"></a>

## Function `delegation_deactivation_epoch`



<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_delegation_deactivation_epoch">delegation_deactivation_epoch</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">staking_pool::StakedSui</a>): <a href="_Option">option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_delegation_deactivation_epoch">delegation_deactivation_epoch</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a>): Option&lt;u64&gt; {
    staked_sui.delegation_deactivation_epoch
}
</code></pre>



</details>

<a name="0x2_staking_pool_delegation_status"></a>

## Function `delegation_status`



<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_delegation_status">delegation_status</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">staking_pool::StakedSui</a>, ctx: &<a href="tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_delegation_status">delegation_status</a>(staked_sui: &<a href="staking_pool.md#0x2_staking_pool_StakedSui">StakedSui</a>, ctx: &TxContext): u64 {
    <b>let</b> current_epoch = <a href="tx_context.md#0x2_tx_context_epoch">tx_context::epoch</a>(ctx);
    <b>if</b> (staked_sui.delegation_activation_epoch &gt; current_epoch) {
        <b>return</b> <a href="staking_pool.md#0x2_staking_pool_PENDING_ACTIVE">PENDING_ACTIVE</a>
    };
    <b>if</b> (<a href="_is_none">option::is_none</a>(&staked_sui.delegation_deactivation_epoch)) {
        <b>return</b> <a href="staking_pool.md#0x2_staking_pool_ACTIVE">ACTIVE</a>
    };
    <b>let</b> deactive_epoch = *<a href="_borrow">option::borrow</a>(&staked_sui.delegation_deactivation_epoch);
    <b>if</b> (deactive_epoch &gt; current_epoch) {
        <a href="staking_pool.md#0x2_staking_pool_PENDING_DEACTIVE">PENDING_DEACTIVE</a>
    } <b>else</b> {
        <a href="staking_pool.md#0x2_staking_pool_DEACTIVE">DEACTIVE</a>
    }
}
</code></pre>



</details>

<a name="0x2_staking_pool_pool_token_exchange_rate_at_epoch"></a>

## Function `pool_token_exchange_rate_at_epoch`



<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_pool_token_exchange_rate_at_epoch">pool_token_exchange_rate_at_epoch</a>(pool: &<a href="staking_pool.md#0x2_staking_pool_StakingPool">staking_pool::StakingPool</a>, epoch: u64): <a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">staking_pool::PoolTokenExchangeRate</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="staking_pool.md#0x2_staking_pool_pool_token_exchange_rate_at_epoch">pool_token_exchange_rate_at_epoch</a>(pool: &<a href="staking_pool.md#0x2_staking_pool_StakingPool">StakingPool</a>, epoch: u64): <a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">PoolTokenExchangeRate</a> {
    *<a href="table.md#0x2_table_borrow">table::borrow</a>(&pool.exchange_rates, epoch)
}
</code></pre>



</details>

<a name="0x2_staking_pool_get_sui_amount"></a>

## Function `get_sui_amount`



<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_get_sui_amount">get_sui_amount</a>(exchange_rate: &<a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">staking_pool::PoolTokenExchangeRate</a>, token_amount: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_get_sui_amount">get_sui_amount</a>(exchange_rate: &<a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">PoolTokenExchangeRate</a>, token_amount: u64): u64 {
    <b>if</b> (exchange_rate.pool_token_amount == 0) {
        <b>return</b> token_amount
    };
    <b>let</b> res = (exchange_rate.sui_amount <b>as</b> u128)
            * (token_amount <b>as</b> u128)
            / (exchange_rate.pool_token_amount <b>as</b> u128);
    (res <b>as</b> u64)
}
</code></pre>



</details>

<a name="0x2_staking_pool_get_token_amount"></a>

## Function `get_token_amount`



<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_get_token_amount">get_token_amount</a>(exchange_rate: &<a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">staking_pool::PoolTokenExchangeRate</a>, sui_amount: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_get_token_amount">get_token_amount</a>(exchange_rate: &<a href="staking_pool.md#0x2_staking_pool_PoolTokenExchangeRate">PoolTokenExchangeRate</a>, sui_amount: u64): u64 {
    <b>if</b> (exchange_rate.sui_amount == 0) {
        <b>return</b> sui_amount
    };
    <b>let</b> res = (exchange_rate.pool_token_amount <b>as</b> u128)
            * (sui_amount <b>as</b> u128)
            / (exchange_rate.sui_amount <b>as</b> u128);
    (res <b>as</b> u64)
}
</code></pre>



</details>

<a name="0x2_staking_pool_increment_or_insert_pending_withdraw"></a>

## Function `increment_or_insert_pending_withdraw`



<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_increment_or_insert_pending_withdraw">increment_or_insert_pending_withdraw</a>(<a href="table.md#0x2_table">table</a>: &<b>mut</b> <a href="table.md#0x2_table_Table">table::Table</a>&lt;u64, <a href="staking_pool.md#0x2_staking_pool_PendingWithdrawEntry">staking_pool::PendingWithdrawEntry</a>&gt;, epoch: u64, principal_withdraw_amount: u64, pool_token_withdraw_amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_increment_or_insert_pending_withdraw">increment_or_insert_pending_withdraw</a>(
    <a href="table.md#0x2_table">table</a>: &<b>mut</b> Table&lt;u64, <a href="staking_pool.md#0x2_staking_pool_PendingWithdrawEntry">PendingWithdrawEntry</a>&gt;, epoch: u64, principal_withdraw_amount: u64, pool_token_withdraw_amount: u64
) {
    <b>if</b> (!<a href="table.md#0x2_table_contains">table::contains</a>(<a href="table.md#0x2_table">table</a>, epoch)) {
        <a href="table.md#0x2_table_add">table::add</a>(
            <a href="table.md#0x2_table">table</a>,
            epoch,
            <a href="staking_pool.md#0x2_staking_pool_PendingWithdrawEntry">PendingWithdrawEntry</a> {
                total_principal_withdraw_amount: principal_withdraw_amount,
                total_pool_token_withdraw_amount: pool_token_withdraw_amount,
            },
        );
    } <b>else</b> {
        <b>let</b> entry = <a href="table.md#0x2_table_borrow_mut">table::borrow_mut</a>(<a href="table.md#0x2_table">table</a>, epoch);
        entry.total_principal_withdraw_amount = entry.total_principal_withdraw_amount + principal_withdraw_amount;
        entry.total_pool_token_withdraw_amount = entry.total_pool_token_withdraw_amount + pool_token_withdraw_amount;
    }
}
</code></pre>



</details>

<a name="0x2_staking_pool_diff_if_greater"></a>

## Function `diff_if_greater`

Returns the difference between x and y if x is greater than y, and 0 otherwise.


<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_diff_if_greater">diff_if_greater</a>(x: u64, y: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="staking_pool.md#0x2_staking_pool_diff_if_greater">diff_if_greater</a>(x: u64, y: u64): u64 {
    <b>if</b> (x &gt; y) { x - y } <b>else</b> { 0 }
}
</code></pre>



</details>
