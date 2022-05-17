// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { DefaultRpcClient as rpc, type Network } from './DefaultRpcClient';

export const navigateWithUnknown = async (
    input: string,
    navigate: Function,
    network: Network
) => {
    const addrPromise = rpc(network)
        .getOwnedObjectRefs(input)
        .then((data) => {
            if (data.length <= 0) throw new Error('No objects for Address');

            return {
                category: 'addresses',
                data: data,
            };
        });
    const objInfoPromise = rpc(network)
        .getObjectInfo(input)
        .then((data) => {
            if (data.status !== 'Exists') {
                throw new Error('no object found');
            }

            return {
                category: 'objects',
                data: data,
            };
        });

    const txDetailsPromise = rpc(network)
        .getTransactionWithEffects(input)
        .then((data) => ({
            category: 'transactions',
            data: data,
        }));

    return (
        Promise.any([objInfoPromise, addrPromise, txDetailsPromise])
            .then((pac) => {
                if (
                    pac?.data &&
                    (pac?.category === 'objects' ||
                        pac?.category === 'addresses' ||
                        pac?.category === 'transactions')
                ) {
                    navigate(
                        `../${pac.category}/${encodeURIComponent(input)}`,
                        {
                            state: pac.data,
                        }
                    );
                } else {
                    throw new Error(
                        'Something wrong with navigateWithUnknown function'
                    );
                }
            })
            //if none of the queries find a result, show missing page
            .catch((error) => {
                // encode url in
                navigate(`../missing/${encodeURIComponent(input)}`);
            })
    );
};
