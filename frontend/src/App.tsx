import { connect, disconnect } from '@stacks/connect'
import type { GetAddressesResult } from '@stacks/connect/dist/types/methods'
import { useState } from 'react'

export default function App() {
  let [isConnected, setIsConnected] = useState<boolean>(false)
  let [walletInfo, setWalletInfo] = useState<any>(null)
  let [bns, setBns] = useState<string>('')

  async function connectWallet() {
    let connectionResponse: GetAddressesResult = await connect()
    let bnsName = await getBns(connectionResponse.addresses[2].address)

    setIsConnected(true)
    setWalletInfo(connectionResponse)
    setBns(bnsName)
  }

  async function disconnectWallet() {
    disconnect();
  }
  
  async function getBns(stxAddress: string) {
    let response = await fetch(`https://api.bnsv2.com/testnet/names/address/${stxAddress}/valid`)
    let data = await response.json()

    return data.names[0].full_name
  }
  
  return (
    <>
      <h3>Stacks Dev Quickstart Message Board</h3>
      {isConnected ? (
        <button onClick={disconnectWallet}>{
          bns ? bns : walletInfo.addresses[2].address
        }</button>
      ) : (
        <button onClick={connectWallet}>connect wallet</button>
      )}
    </>
  )
}