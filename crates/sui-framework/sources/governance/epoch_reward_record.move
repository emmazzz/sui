// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::epoch_reward_record {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    friend sui::sui_system;
    friend sui::validator_set;

    const BASIS_POINT_DENOMINATOR: u128 = 10000;

    /// EpochRewardRecord is an immutable record created per epoch per active validator.
    /// Sufficient information is saved in the record so that delegators can claim
    /// delegation rewards from past epochs, and for validators that may no longer be active.
    /// TODO: For now we assume that validators don't charge an extra fee.
    /// Delegation reward is simply proportional to to overall delegation reward ratio
    /// and the delegation amount.
    struct EpochRewardRecord has key {
        id: UID,
        epoch: u64,
        computation_charge: u64,
        total_stake: u64,
        delegator_count: u64,
        validator: address,
        validator_commission_rate: u64, // in basis point
    }

    public(friend) fun create(
        epoch: u64,
        computation_charge: u64,
        total_stake: u64,
        delegator_count: u64,
        validator: address,
        validator_commission_rate: u64,
        ctx: &mut TxContext,
    ) {
        transfer::share_object(EpochRewardRecord {
            id: object::new(ctx),
            epoch,
            computation_charge,
            total_stake,
            delegator_count,
            validator,
            validator_commission_rate,
        })
    }

    /// Given the delegation amount, calculate the reward, and decrement the `delegator_count`.
    public(friend) fun claim_reward(self: &mut EpochRewardRecord, delegation_amount: u64): u64 {
        self.delegator_count = self.delegator_count - 1;
        // TODO: Once self.delegator_count reaches 0, we should be able to delete this object.
        let delegation_reward_amount = (delegation_amount as u128) * (self.computation_charge as u128) / (self.total_stake as u128);
        let commission = (delegation_reward_amount as u128) * (self.validator_commission_rate as u128) / BASIS_POINT_DENOMINATOR;
        let result = delegation_reward_amount - commission;
        (result as u64)
    }

    public fun epoch(self: &EpochRewardRecord): u64 {
        self.epoch
    }

    public fun validator(self: &EpochRewardRecord): address {
        self.validator
    }
}
