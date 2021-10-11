import React, { useState } from 'react';
import styles from './TwitterAccountConnection.module.css';

import { useContractFunction, useContractCall } from '@usedapp/core'
import { Contract } from '@ethersproject/contracts'
import { utils } from 'ethers'
import { Falsy } from '@usedapp/core/dist/esm/src/model/types';

import satLinkAbiJson from '../../abis/SatLink.json'

const satLinkFactoryInterface = new utils.Interface(satLinkAbiJson.abi)

interface TwitterAccountConnectionProps {
  account: string | Falsy,
  satLinkAddress: string | Falsy
}

const useTwitterHandle = (satLinkAddress: string | Falsy) => {
  return useContractCall({
    address: satLinkAddress as any,
    abi: satLinkFactoryInterface,
    method: 'twitterHandle',
    args: []
  }) ?? []
}

const useTwitterConnection = (account: string | Falsy, satLinkAddress: string | Falsy) => {
  const [twitterConnected] = useContractCall({
    address: satLinkAddress as any,
    abi: satLinkFactoryInterface,
    method: 'twitterConnected',
    args: []
  }) ?? []

  const { state, send } = useContractFunction(
    new Contract(satLinkAddress as any, satLinkFactoryInterface),
    'queryTwitterConnection',
    {transactionName: 'queryTwitterConnection'}
  )
  const queryTwitterConnection = () => {
    // Only create a new SatLink contract if one doesn't already exist
    if (!twitterConnected) {
      send({from: account})
    } else {
      console.log(`Twitter is already connected on SatLink ${satLinkAddress}`)
    }
  }

  return [twitterConnected, queryTwitterConnection]
}

const useUnlinkTwitter = (account: string | Falsy, satLinkAddress: string | Falsy) => {
  const [twitterConnected, queryTwitterConnection] = useTwitterConnection(account, satLinkAddress)

  const { state, send } = useContractFunction(
    new Contract(satLinkAddress as any, satLinkFactoryInterface),
    'unlinkTwitter',
    {transactionName: 'unlinkTwitter'}
  )
  const unlinkTwitter = () => {
    // Only create a new SatLink contract if one doesn't already exist
    if (twitterConnected) {
      send({from: account})
    } else {
      console.log(`No Twitter account is connected on SatLink ${satLinkAddress}`)
    }
  }

  return [unlinkTwitter]
}

const useGenerateTwitterOtp = (account: string | Falsy, satLinkAddress: string | Falsy) => {
  const [twitterOtpGenerated] = useContractCall({
    address: satLinkAddress as any,
    abi: satLinkFactoryInterface,
    method: 'twitterOtpGenerated',
    args: []
  }) ?? []

  const { state, send } = useContractFunction(
    new Contract(satLinkAddress as any, satLinkFactoryInterface),
    'generateTwitterOtp',
    {transactionName: 'generateTwitterOtp'}
  )
  const generateTwitterOtp = (twitterHandle: string) => {
    // Only create a new SatLink contract if one doesn't already exist
    if (!twitterOtpGenerated) {
      send(twitterHandle, {from: account})
    } else {
      console.log(`Twitter OTP was already generated for SatLink ${satLinkAddress}`)
    }
  }

  return [twitterOtpGenerated, generateTwitterOtp]
}

const useTwitterOtp = (satLinkAddress: string | Falsy) => {
  return useContractCall({
    address: satLinkAddress as any,
    abi: satLinkFactoryInterface,
    method: 'twitterOtp',
    args: []
  }) ?? []
}

const TwitterAccountConnection: React.FC<TwitterAccountConnectionProps> = (props: TwitterAccountConnectionProps) => {
  const [twitterHandleInput, setTwitterHandleInput] = useState('')
  const [twitterHandle] = useTwitterHandle(props.satLinkAddress)
  const [twitterConnected, queryTwitterConnection] = useTwitterConnection(props.account, props.satLinkAddress)
  const [unlinkTwitter] = useUnlinkTwitter(props.account, props.satLinkAddress)
  const [twitterOtpGenerated, generateTwitterOtp] = useGenerateTwitterOtp(props.account, props.satLinkAddress)
  const [twitterOtp] = useTwitterOtp(props.satLinkAddress)

  return (
    <div className={styles.TwitterAccountConnection}>
      {!twitterConnected && !twitterOtpGenerated &&
        <>
          <input type="text" name="twitterHandle" onInput={(e) => setTwitterHandleInput((e.target as HTMLInputElement).value)} />
          <button onClick={() => generateTwitterOtp(twitterHandleInput)}>Connect Twitter</button>
        </>
      }
      {!twitterConnected && twitterOtpGenerated && twitterOtp &&
        <button onClick={() => queryTwitterConnection()}>Query Twitter OTP ({twitterOtp.toNumber()})</button>
      }
      {twitterConnected && twitterHandle &&
        <>
          <p>Twitter account <code>{twitterHandle}</code> verified! ✅</p>
          <button onClick={() => unlinkTwitter()}>Unlink Twitter</button>
        </>
      }
    </div>
  )
}

export default TwitterAccountConnection;
