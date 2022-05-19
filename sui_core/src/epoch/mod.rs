// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use serde::{Deserialize, Serialize};
use sui_types::{committee::Committee, messages_checkpoint::CheckpointSequenceNumber};

#[derive(Clone, Serialize, Deserialize)]
pub struct EpochInfo {
    pub committee: Committee,
    pub first_checkpoint: CheckpointSequenceNumber,
    pub last_checkpoint: CheckpointSequenceNumber,
    pub validator_halted: bool,
}
