import React from 'react'
import SatLinkViewer from './components/SatLinkViewer/SatLinkViewer';

import { useEthers } from '@usedapp/core'

function App() {
  const { activateBrowserWallet, account } = useEthers()

  return(
    <div>
      {!account && <button onClick={activateBrowserWallet as any}> Connect </button>}
      {account &&
        <div>
          <p>Account: {account}</p>
          <SatLinkViewer account={account} />
        </div>
      }
    </div>
  )  
}

export default App;
