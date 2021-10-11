import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';
import { ChainId, DAppProvider, Config } from '@usedapp/core'

const config: Config = {
  // readOnlyChainId: ChainId.Kovan,
  // readOnlyUrls: {
  //   [ChainId.Ropsten]: 'https://kovan.infura.io/v3/62687d1a985d4508b2b7a24827551934',
  // },
  supportedChains: [1337]
}

ReactDOM.render(
  <React.StrictMode>
    <DAppProvider config={config}>
      <App />
    </DAppProvider>
  </React.StrictMode>,
  document.getElementById('root')
)
