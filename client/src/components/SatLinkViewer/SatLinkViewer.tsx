import React, { useState, useCallback } from 'react';
import styles from './SatLinkViewer.module.css';

import { useContractFunction, useContractCall } from '@usedapp/core'
import { formatEther } from '@ethersproject/units'
import { Contract } from '@ethersproject/contracts'
import { utils } from 'ethers'
import { Falsy } from '@usedapp/core/dist/esm/src/model/types';

import TwitterAccountConnection from '../TwitterAccountConnection/TwitterAccountConnection';

import satLinkFactoryAbiJson from '../../abis/SatLinkFactory.json'


const satLinkFactoryAddress = '0xDd6e237a64766AfD08E0e4937c9dB7d5CdA5FDEB'
const satLinkFactoryInterface = new utils.Interface(satLinkFactoryAbiJson.abi)

interface SatLinkViewerProps {
  account: string | Falsy
}

const useSatLinkAddress = (account: string | Falsy) => {
  // Create SatLink address variable (undefined if doesn't yet exist)
  let [satLinkAddress] = useContractCall({
    address: satLinkFactoryAddress,
    abi: satLinkFactoryInterface,
    method: 'instances',
    args: [account]
  }) ?? []

  // If SatLink address is 0x00000.. it means there's no SatLink..
  satLinkAddress = (satLinkAddress == '0x0000000000000000000000000000000000000000' ? null : satLinkAddress)

  // Create SatLink function (creating SatLink contract for account)
  const { state, send } = useContractFunction(
    new Contract(satLinkFactoryAddress, satLinkFactoryInterface),
    'createSatLink',
    {transactionName: 'createSatLink'}
  )
  const createSatLink = () => {
    // Only create a new SatLink contract if one doesn't already exist
    if (!satLinkAddress) {
      send({from: account})
    } else {
      console.log(`SatLink address already exists for account ${account} at address ${satLinkAddress}`)
    }
  }

  return [satLinkAddress, createSatLink]
}

const SatLinkViewer: React.FC<SatLinkViewerProps> = (props: SatLinkViewerProps) => {
  const [satLinkAddress, createSatLinkAddress] = useSatLinkAddress(props.account)

  return (
    <div className={styles.SatLinkViewer}>
      {props.account &&
        <div>
          {/* <button onClick={() => fetchSatLinkAddress()}> Check SatLink address </button> */}
          {!satLinkAddress && <p>You don't have a SatLink yet <button onClick={() => createSatLinkAddress()}> Create SatLink </button></p>}
          {satLinkAddress && 
            <div>
              <p>Your SatLink address is {satLinkAddress}</p>
              <TwitterAccountConnection account={props.account} satLinkAddress={satLinkAddress} />
            </div>
          }
        </div>
      }
    </div>
  )
}

export default SatLinkViewer;
