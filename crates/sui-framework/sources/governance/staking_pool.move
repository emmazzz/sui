// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::staking_pool {
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use std::option::{Self, Option, none, some};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::epoch_time_lock::{EpochTimeLock};
    use sui::object::{Self, UID};
    use sui::locked_coin;
    use sui::coin;
    use sui::math;
    use sui::table::{Self, Table};

    friend sui::validator;
    friend sui::validator_set;
    
    const EINSUFFICIENT_POOL_TOKEN_BALANCE: u64 = 0;
    const EWRONG_POOL: u64 = 1;
    const EWITHDRAW_AMOUNT_CANNOT_BE_ZERO: u64 = 2;
    const EINSUFFICIENT_SUI_TOKEN_BALANCE: u64 = 3;
    const EINSUFFICIENT_REWARDS_POOL_BALANCE: u64 = 4;
    const EDESTROY_NON_ZERO_BALANCE: u64 = 5;
    const ETOKEN_TIME_LOCK_IS_SOME: u64 = 6;
    const EWRONG_DELEGATION: u64 = 7;
    const EPENDING_DELEGATION_DOES_NOT_EXIST: u64 = 8;
    const ESTATUS_NOT_ACTIVE: u64 = 9;
    const ESTATUS_NOT_DEACTIVE: u64 = 10;

    const PENDING_ACTIVE: u64 = 0;
    const ACTIVE: u64 = 1;
    const PENDING_DEACTIVE: u64 = 2;
    const DEACTIVE: u64 = 3;

    const UNBONDING_PERIOD_LENGTH: u64 = 0;

    /// A staking pool embedded in each validator struct in the system state object.
    struct StakingPool has store {
        // TODO: use object ID instead of validator address to identify a pool
        /// The sui address of the validator associated with this pool.
        validator_address: address,
        /// The epoch at which this pool started operating. Should be the epoch at which the validator became active.
        starting_epoch: u64,
        /// The total number of SUI tokens in this pool, including the SUI in the rewards_pool, as well as in all the principal
        /// in the `StakedSui` object, updated at epoch boundaries.
        sui_balance: u64,
        /// The epoch delegation rewards will be added here at the end of each epoch. 
        rewards_pool: Balance<SUI>,
        /// Total number of pool tokens issued by the pool.
        pool_token_balance: u64,
        /// Exchange rate history of previous epochs. Key is the epoch number.
        exchange_rates: Table<u64, PoolTokenExchangeRate>,
        /// Pending delegation amount for this epoch.
        pending_delegation: u64,
        /// Cumulated delegation withdraws where the key is the epoch at which the withdraws should be processed.
        pending_withdraws: Table<u64, PendingWithdrawEntry>,
        /// Stores the rewards that are ready to be claimed. This doesn't count towards the stake distribution.
        unclaimed_rewards: Balance<SUI>,
    }

    /// Struct representing the exchange rate of the delegation pool token to SUI.
    struct PoolTokenExchangeRate has store, copy, drop {
        sui_amount: u64,
        pool_token_amount: u64,
    }

    /// An inactive staking pool associated with an inactive validator.
    /// Only withdraws can be made from this pool.
    struct InactiveStakingPool has key {
        id: UID, // TODO: inherit an ID from active staking pool?
        pool: StakingPool,
    }

    /// Struct representing a pending delegation withdraw.
    struct PendingWithdrawEntry has store {
        total_principal_withdraw_amount: u64,
        total_pool_token_withdraw_amount: u64,
    }

    /// A self-custodial object holding the staked SUI tokens.
    struct StakedSui has key {
        id: UID,
        /// The validator we are staking with.
        validator_address: address,
        /// The epoch at which the staking pool started operating.
        pool_starting_epoch: u64,
        /// The epoch at which the delegation becomes active.
        delegation_activation_epoch: u64,
        /// The epoch at which the delegation becomes deactive.
        /// This field is none if the delegation is still active.
        delegation_deactivation_epoch: Option<u64>,
        /// The staked SUI tokens.
        principal: Balance<SUI>,
        /// If the stake comes from a Coin<SUI>, this field is None. If it comes from a LockedCoin<SUI>, this
        /// field will record the original lock expiration epoch, to be used when unstaking.
        sui_token_lock: Option<EpochTimeLock>,
    }

    // ==== initializer ====

    /// Create a new, empty staking pool.
    public(friend) fun new(validator_address: address, starting_epoch: u64, ctx: &mut TxContext) : StakingPool {
        let exchange_rates = table::new(ctx);
        table::add(
            &mut exchange_rates,
            tx_context::epoch(ctx),
            PoolTokenExchangeRate { sui_amount: 0, pool_token_amount: 0 }
        );
        StakingPool {
            validator_address,
            starting_epoch,
            sui_balance: 0,
            rewards_pool: balance::zero(),
            pool_token_balance: 0,
            exchange_rates,
            pending_delegation: 0,
            pending_withdraws: table::new(ctx),
            unclaimed_rewards: balance::zero(),
        }
    }


    // ==== delegation requests ====

    /// Request to delegate to a staking pool. The delegation gets counted at the beginning of the next epoch,
    /// when the delegation object containing the pool tokens is distributed to the delegator.
    public(friend) fun request_add_delegation(
        pool: &mut StakingPool, 
        stake: Balance<SUI>, 
        sui_token_lock: Option<EpochTimeLock>,
        delegator: address,
        ctx: &mut TxContext
    ) {
        let sui_amount = balance::value(&stake);
        assert!(sui_amount > 0, 0);
        let staked_sui = StakedSui {
            id: object::new(ctx),
            validator_address: pool.validator_address,
            pool_starting_epoch: pool.starting_epoch,
            delegation_activation_epoch: tx_context::epoch(ctx) + 1,
            delegation_deactivation_epoch: none(),
            principal: stake,
            sui_token_lock,
        };
        pool.pending_delegation = pool.pending_delegation + sui_amount;
        transfer::transfer(staked_sui, delegator);
    }

    public(friend) fun request_withdraw_delegation(
        pool: &mut StakingPool,  
        staked_sui: &mut StakedSui,
        ctx: &mut TxContext
    ) {
        // check that the delegation is active.
        assert!(delegation_status(staked_sui, ctx) == ACTIVE, ESTATUS_NOT_ACTIVE);

        // calculate the amount of pool token to withdraw using the exchange rate at staking time.
        let principal_withdraw_amount = balance::value(&staked_sui.principal);
        let exchange_rate_at_staking_epoch = pool_token_exchange_rate_at_epoch(pool, staked_sui.delegation_activation_epoch);
        let pool_token_withdraw_amount = get_token_amount(&exchange_rate_at_staking_epoch, principal_withdraw_amount);

        let delegation_deactivation_epoch = tx_context::epoch(ctx) + 1 + UNBONDING_PERIOD_LENGTH;

        option::fill(&mut staked_sui.delegation_deactivation_epoch, delegation_deactivation_epoch);

        // add the withdraw amounts to cumulated withdraw amounts for that epoch.
        increment_or_insert_pending_withdraw(
            &mut pool.pending_withdraws,
            delegation_deactivation_epoch,
            principal_withdraw_amount,
            pool_token_withdraw_amount,
        );
    }

    /// Claim the principal and rewards earned from the deactive delegation.
    public(friend) fun claim_rewards(
        pool: &mut StakingPool,  
        staked_sui: StakedSui,
        ctx: &mut TxContext
    ) {
        // check that the delegation is active.
        assert!(delegation_status(&staked_sui, ctx) == DEACTIVE, ESTATUS_NOT_DEACTIVE);
        let delegator = tx_context::sender(ctx);
        let delegation_deactivation_epoch = *option::borrow(&staked_sui.delegation_deactivation_epoch);

        // calculate pool token amount.
        let exchange_rate_at_staking_epoch = pool_token_exchange_rate_at_epoch(pool, staked_sui.delegation_activation_epoch);
        let principal_amount = balance::value(&staked_sui.principal);
        let pool_token_amount = get_token_amount(&exchange_rate_at_staking_epoch, principal_amount);
        
        // calculate the total sui amount including rewards using exchange rate at unstaking time.
        let exchange_rate_at_unstaking_epoch = pool_token_exchange_rate_at_epoch(pool, delegation_deactivation_epoch);
        let total_sui_amount = get_sui_amount(&exchange_rate_at_unstaking_epoch, pool_token_amount);

        // unwrap staked sui, get the principal out
        let (principal, epoch_time_lock) = unwrap_staked_sui(staked_sui);

        // get the rewards from unclaimed rewards
        let reward_withdraw_amount = diff_if_greater(total_sui_amount, principal_amount);
        let reward = balance::split(&mut pool.unclaimed_rewards, reward_withdraw_amount);

        // transfer the principal and reward to the delegator
        if (option::is_none(&epoch_time_lock)) {
            balance::join(&mut principal, reward);
            transfer::transfer(coin::from_balance(principal, ctx), delegator);
        } else {
            locked_coin::new_from_balance(principal, option::extract(&mut epoch_time_lock), delegator, ctx);
            if (reward_withdraw_amount > 0) {
                transfer::transfer(coin::from_balance(reward, ctx), delegator);
            } else {
                balance::destroy_zero(reward);
            }
        };
        option::destroy_none(epoch_time_lock);
    }

    fun unwrap_staked_sui(staked_sui: StakedSui): (Balance<SUI>, Option<EpochTimeLock>) {
        let StakedSui { 
            id,
            validator_address: _,
            pool_starting_epoch: _,
            delegation_activation_epoch: _,
            delegation_deactivation_epoch: _,
            principal,
            sui_token_lock
        } = staked_sui;
        object::delete(id);
        (principal, sui_token_lock)
    }

    // ==== functions called at epoch boundaries ===

    /// Called at epoch advancement times to add rewards (in SUI) to the staking pool. 
    public(friend) fun deposit_rewards(pool: &mut StakingPool, rewards: Balance<SUI>, new_epoch: u64) {
        pool.sui_balance = pool.sui_balance + balance::value(&rewards);
        balance::join(&mut pool.rewards_pool, rewards);
        table::add(
            &mut pool.exchange_rates,
            new_epoch,
            PoolTokenExchangeRate { sui_amount: pool.sui_balance, pool_token_amount: pool.pool_token_balance },
        );
    }

    /// Called at epoch boundaries to process delegations that become deactive at the new epoch.
    /// Returns the total sui withdraw amount for the new epoch.
    public(friend) fun process_pending_delegation_withdraws(pool: &mut StakingPool, new_epoch: u64, ctx: &mut TxContext) : u64 {
        if (table::contains(&pool.pending_withdraws, new_epoch)) {
            let PendingWithdrawEntry {
                total_pool_token_withdraw_amount,
                total_principal_withdraw_amount,
            } = table::remove(&mut pool.pending_withdraws, new_epoch);

            // use the new exchange rate to calculate how much sui we are withdrawing in total (including both principal and rewards)
            let new_epoch_exchange_rate = pool_token_exchange_rate_at_epoch(pool, new_epoch);
            let total_sui_amount = get_sui_amount(&new_epoch_exchange_rate, total_pool_token_withdraw_amount);

            // calculate the reward portion of the withdraw
            let total_reward_withdraw_amount = 
                sui::math::min(
                    diff_if_greater(total_sui_amount, total_principal_withdraw_amount),
                    balance::value(&pool.rewards_pool)
                );

            // and put it into unclaimed rewards
            balance::join(&mut pool.unclaimed_rewards, balance::split(&mut pool.rewards_pool, total_reward_withdraw_amount));

            let total_sui_withdraw_amount = total_reward_withdraw_amount + total_principal_withdraw_amount;

            // decrement the balance accordingly
            pool.sui_balance = pool.sui_balance - total_sui_withdraw_amount;
            pool.pool_token_balance = pool.pool_token_balance - total_pool_token_withdraw_amount;
            total_sui_withdraw_amount
        } else {
            0
        }
    }

    /// Called at epoch boundaries to process the pending delegation.
    public(friend) fun process_pending_delegation(pool: &mut StakingPool, new_epoch: u64) {
        let new_epoch_exchange_rate = pool_token_exchange_rate_at_epoch(pool, new_epoch);
        pool.sui_balance = pool.sui_balance + pool.pending_delegation;
        pool.pool_token_balance = pool.pool_token_balance + get_token_amount(&new_epoch_exchange_rate, pool.pending_delegation);
        pool.pending_delegation = 0;
    }

    // ==== inactive pool related ====

    /// Deactivate a staking pool by wrapping it in an `InactiveStakingPool` and sharing this newly created object. 
    /// After this pool deactivation, the pool stops earning rewards. Only delegation withdraws can be made to the pool.
    public(friend) fun deactivate_staking_pool(pool: StakingPool, ctx: &mut TxContext) {
        let inactive_pool = InactiveStakingPool { id: object::new(ctx), pool};
        transfer::share_object(inactive_pool);
    }

    // ==== getters and misc utility functions ====

    public fun sui_balance(pool: &StakingPool) : u64 { pool.sui_balance }

    public fun validator_address(staked_sui: &StakedSui) : address { staked_sui.validator_address }

    public fun staked_sui_amount(staked_sui: &StakedSui): u64 { balance::value(&staked_sui.principal) }

    public fun delegation_activation_epoch(staked_sui: &StakedSui): u64 {
        staked_sui.delegation_activation_epoch
    }

    public fun delegation_deactivation_epoch(staked_sui: &StakedSui): Option<u64> {
        staked_sui.delegation_deactivation_epoch
    }

    public fun delegation_status(staked_sui: &StakedSui, ctx: &TxContext): u64 {
        let current_epoch = tx_context::epoch(ctx);
        if (staked_sui.delegation_activation_epoch > current_epoch) {
            return PENDING_ACTIVE
        };
        if (option::is_none(&staked_sui.delegation_deactivation_epoch)) {
            return ACTIVE
        };
        let deactive_epoch = *option::borrow(&staked_sui.delegation_deactivation_epoch);
        if (deactive_epoch > current_epoch) {
            PENDING_DEACTIVE
        } else {
            DEACTIVE
        }
    }

    public fun pool_token_exchange_rate_at_epoch(pool: &StakingPool, epoch: u64): PoolTokenExchangeRate {
        *table::borrow(&pool.exchange_rates, epoch)
    }

    fun get_sui_amount(exchange_rate: &PoolTokenExchangeRate, token_amount: u64): u64 {
        if (exchange_rate.pool_token_amount == 0) { 
            return token_amount 
        };
        let res = (exchange_rate.sui_amount as u128) 
                * (token_amount as u128) 
                / (exchange_rate.pool_token_amount as u128);
        (res as u64)
    }

    fun get_token_amount(exchange_rate: &PoolTokenExchangeRate, sui_amount: u64): u64 {
        if (exchange_rate.sui_amount == 0) { 
            return sui_amount
        };
        let res = (exchange_rate.pool_token_amount as u128) 
                * (sui_amount as u128)
                / (exchange_rate.sui_amount as u128);
        (res as u64)
    }

    fun increment_or_insert_pending_withdraw(
        table: &mut Table<u64, PendingWithdrawEntry>, epoch: u64, principal_withdraw_amount: u64, pool_token_withdraw_amount: u64
    ) {
        if (!table::contains(table, epoch)) {
            table::add(
                table,
                epoch,
                PendingWithdrawEntry {
                    total_principal_withdraw_amount: principal_withdraw_amount,
                    total_pool_token_withdraw_amount: pool_token_withdraw_amount,
                },
            );
        } else {
            let entry = table::borrow_mut(table, epoch);
            entry.total_principal_withdraw_amount = entry.total_principal_withdraw_amount + principal_withdraw_amount;
            entry.total_pool_token_withdraw_amount = entry.total_pool_token_withdraw_amount + pool_token_withdraw_amount;
        }
    }

    /// Returns the difference between x and y if x is greater than y, and 0 otherwise.
    fun diff_if_greater(x: u64, y: u64): u64 {
        if (x > y) { x - y } else { 0 }
    }
}
