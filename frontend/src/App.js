import React, {useEffect, useState} from 'react'
import Web3 from "web3";

import './App.css'
import Stake from "./Stake";
import {NPC_ABI, NPC_ADDRESS, STAKER_ABI, STAKER_ADDRESS} from "./config";

const App = () => {
    const [account, setAccount] = useState('')
    const [nftCount, setNftCount] = useState(0)
    const [nftApproval, setNftApproval] = useState(false)
    const [nftIds, setNftIds] = useState([])
    const [nftMultipliers, setNftMultipliers] = useState([])
    const [npc, setNpc] = useState(null)
    const [loading, setLoading] = useState(false)
    const [staker, setStaker] = useState(null)
    const [stakeList, setStakeList] = useState([])
    const [stakeButtonDisabled, setStakeButtonDisabled] = useState(true)
    const [approveButtonDisabled, setApproveButtonDisabled] = useState(true)

    const updateButtons = async () => {
	if(loading) {
		setApproveButtonDisabled(true)
		setStakeButtonDisabled(true)
		return
	}
	const currentNftApproval = await npc.methods.isApprovedForAll(account, STAKER_ADDRESS).call()

        if(currentNftApproval) {
	    setApproveButtonDisabled(true)
            setStakeButtonDisabled(false)
        } else {
	    setApproveButtonDisabled(false)
            setStakeButtonDisabled(true)
        }
	const selected = selectedNfts()
	if(selected.length == 0) {
		setStakeButtonDisabled(true)
	}	
    }

    const loadBlockchainData = async () => {
        const web3 = new Web3(Web3.givenProvider || "http://localhost:8545")
        const accounts = await web3.eth.getAccounts()
        setAccount(accounts[0])

        const fetchedStaker = new web3.eth.Contract(STAKER_ABI, STAKER_ADDRESS)
        setStaker(fetchedStaker)

        const fetchedNpc = new web3.eth.Contract(NPC_ABI, NPC_ADDRESS)
        setNpc(fetchedNpc)

        const fetchedNftCount = await fetchedNpc.methods.balanceOf(accounts[0]).call()
        setNftCount(fetchedNftCount)

        const fetchedNftApproval = await fetchedNpc.methods.isApprovedForAll(accounts[0], STAKER_ADDRESS).call()
        setNftApproval(fetchedNftApproval)

        for (var i = 0; i < fetchedNftCount; i++) {
	    // XXX Need to pull this via multicall due to contract bug
            const nft_id = await fetchedNpc.methods.tokenOfOwnerByIndex(accounts[0],i).call()
	    console.log(nft_id)
            setNftIds(prev => ([...prev, nft_id]))
	   
	    // XXX Epoch is hard-coded 
	    const nft_multiplier = await fetchedStaker.methods.calc_multiplier(nft_id, 0).call()
            setNftMultipliers(prev => ([...prev, nft_multiplier]))

        }
	
        setLoading(false)
    }

    const selectedNfts = () => {
	const selected = []
	for (var i in nftIds) {
		if(document.getElementById("nft-"+nftIds[i]).checked) {
			if (!selected.includes(nftIds[i])) {
				selected.push(nftIds[i])	
			}
		}
	}

	return selected
    }

    const stakeSelected = (content) => {
	const selected = selectedNfts()
	
 	if(selected.length == 0) {
		return
	}	
        staker.methods.stake_npc(selected).send({from: account})
            .once('receipt', () => {
                updateButtons()
            })
    }

    const approveAll = () => {
        npc.methods.setApprovalForAll(STAKER_ADDRESS, true).send({from: account})
		.once('receipt', () => {
			updateButtons()
		})

        updateButtons()
    }


    const toggleChecked = (listId) => {
	updateButtons()
    }

    //  onMount
    useEffect(() => {
        loadBlockchainData()
    }, [])
    useEffect(() => {
       if(npc && account && !loading) {
	updateButtons()
       }	
    }, [npc, account, loading])

    return (
        <div className="container">
            <h1>Staker</h1>
            <p>Your account: {account}</p>
            <p>Your balance: {nftCount}</p>
            <p>Your approval: {nftApproval ? 'true' : 'false'}</p>
            <p>stakeButtonDisabled: {stakeButtonDisabled ? 'true' : 'false'}</p>
            <p>approveButtonDisabled: {approveButtonDisabled ? 'true' : 'false'}</p>

            <main role="main" className="col-lg-12 d-flex justify-content-center">
                { loading
                    ? <div id="loader" className="text-center"><p className="text-center">Loading...</p></div>
                    : <Stake
                        nftIds={nftIds}
                        nftMultipliers={nftMultipliers}
                        approveButtonDisabled={approveButtonDisabled}
                        stakeButtonDisabled={stakeButtonDisabled}
                        stakeSelected={stakeSelected}
                        approveAll={approveAll}
                        toggleChecked={toggleChecked}
                    />
                }
            </main>
        </div>
    );
}

export default App;
