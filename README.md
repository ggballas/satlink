# SatLink
Connect your social accounts, publicly available web content, IPFS files, PGP keys, and more in a decentralized and trustlessly provable way!

## Installation
### Node version
SatLink was developed using `node` version `v10.22.0`. Please run this code in all terminal windows for SatLink to work properly:
```
nvm install v10.22.0
nvm use v10.22.0
```

### Download repo and run build
```
git clone https://github.com/ggballas/satlink.git
npm install
```

## Setting up
### Run Ganache (local blockchain simulator)
```
# Terminal window #1
ganache-cli --gasLimit=0x1fffffffffffff --allowUnlimitedContractSize -e 1000000000
```

### Run Provable bridge (to enable Provable oracle calls)
```
# Terminal window #2
npm run bridge
```

### Compile and deploy smart contracts
After you have run Ganache and the Provable bridge, do the following:
```
# Terminal window #3
truffle migrate
```

## Interact with SatLink
Now that our local blockchain and bridge are up and running, and the smart contracts are deployed, it's time to start interacting with the SatLink.

### Open truffle console
```
# Terminal window #3
truffle console
```

Run all of the commands below in the truffle console.

### Get address of your account and create SatLink for it
```
accounts = await web3.eth.getAccounts()
acc0 = accounts[0]

slf = await SatLinkFactory.deployed()

tx0 = await slf.createSatLink({from: acc0})
sl = await slf.instances(acc0).then((addr) => {return SatLink.at(addr)})

// Fund your SatLink contract (needed for oracle calls)
tx1 = await sl.sendTransaction({from: acc0, value: web3.utils.toWei('1', 'ether')})
```

### Twitter authentication
Generate an OTP for a certain handle (in this example - `ggballas`):
```
tx2 = await sl.generateTwitterOtp('ggballas')
```

Get the generated OTP by calling:
```
otp = await sl.twitterOtp()
otp.toNumber()
```

Now change your Twitter bio to match that OTP (doesn't have to be the whole bio, just the beginning is good enough).

Have the SatLink check the bio by running:
```
tx3 = await sl.queryTwitterConnection()
```

Wait for a while for the message to propagate through the oracle. After a few minutes, the latest event emitted by the contract will be `twitter_link_success`. You can view the latest event from your SatLink by running:
```
last_event = sl.getPastEvents("allEvents", { fromBlock: 1}).then((es) => es[es.length-1])
```

You can verify that the account is linked by running:
```
sl.twitterHandle()  // -> 'ggballas'
sl.twitterConnected // -> true
```

### IPFS content authentication
Generate an OTP:
```
tx2 = await sl.generateIpfsOtp()
```

Get the generated OTP by calling:
```
otp = await sl.ipfsOtp()
otp.toNumber()
```

Now we have to provide the SatLink with the CID of the file that we want to upload (it needs to be yet non-existent on the IPFS network), and with the hash of the content, salted with the OTP (hash(content + otp))

Generate the CID of the IPFS content like so:
```
npx ipfs-only-hash ./file.txt
```

Generate the salted hash like so (Python):
```
import hashlib
with open('file.txt', 'rb') as f:
    content = f.read()
otp = '<insert OTP here>'

print(hashlib.md5(content + otp.encode()).hexdigest())
```

Provide the SatLink with the CID and the salted hash like so (in the `truffle console`):
```
tx3 = await sl.assertIpfsNonexistent('<insert CID here>', '<insert salted hash here>')
```

This transaction will trigger a request over Provable. Wait until it finishes executing. You'll know it's finished once the last event emitted by your SatLink is `ipfs_salted_hash_uploaded`. You may retrieve the last event like so:
```
last_event = sl.getPastEvents("allEvents", { fromBlock: 1}).then((es) => es[es.length-1])
```

Now upload your file to the IPFS. Once you've done that call this function on your SatLink:
```
tx4 = await sl.verifyIpfs()
```

And wait for the event `ipfs_link_success` to be emitted by your SatLink.

You may verify that your IPFS content is linked by running:
```
sl.ipfsCid()       // -> Your file's CID
sl.ipfsConnected() // -> true
```

### PGP pubkey authentication
Export your pubkey and upload it to IPFS. You can export your pubkey like so:
```
gpg --export -a "john@example.com" > public.key
```

Generate an OTP for that pubkey:
```
tx2 = await sl.generatePgpOtp('<IPFS CID of pubkey file>')
```


Get the generated OTP by calling:
```
otp = await sl.pgpOtp()
otp.toNumber()
```

Save the OTP to a file named `file.txt` (with no newline at the end!) and sign it by running:
```
gpg --output file.txt.dtcsign.armr --armor --detach-sig file.txt
```

Upload the `file.txt.dtcsign.armr` file to the IPFS.

Now provide your SatLink with your signature to prove ownership:
```
tx3 = await sl.provePgpKeyOwnership('<IPFS CID of signature>')
```

Wait for a while for the message to propagate through the oracle. After a few minutes, the latest event emitted by the contract will be `pgp_link_success`. You can view the latest event from your SatLink by running:
```
last_event = sl.getPastEvents("allEvents", { fromBlock: 1}).then((es) => es[es.length-1])
```

You can verify that the account is linked by running:
```
sl.pgpPubkeyIpfs() // -> IPFS CID of your pubkey
sl.pgpConnected()  // -> true
```

## Using the GUI
A GUI is implemented (only works with Twitter authentication). You may run the GUI by running:
```
npm run client
```

The GUI is pretty self-explanatory. Make sure to point your MetaMask (or whatever extension you're using) to the local Ganache blockchain simulator.