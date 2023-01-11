import Stake from "./Stake";
import React, {useEffect, useState} from "react";
import Web3 from "web3";
import {NPC_ABI, NPC_ADDRESS, STAKER_ABI, STAKER_ADDRESS} from "./config";

const MainApp = () => {
    const [account, setAccount] = useState('')
    const [nftCount, setNftCount] = useState(0)
    const [nftApproval, setNftApproval] = useState(false)
    const [nftIds, setNftIds] = useState([])
    const [npc, setNpc] = useState(null)
    const [loading, setLoading] = useState(false)
    const [staker, setStaker] = useState(null)
    const [stakeList, setStakeList] = useState([])
    const [stakeButtonDisabled, setStakeButtonDisabled] = useState(true)

    const updateButtons = (nftApproval) => {
        console.log("NFT Approval:")
        console.log(nftApproval)
        if(nftApproval) {
            console.log("Disabling")
            setStakeButtonDisabled(false)
        } else {
            console.log("Enabling")
            setStakeButtonDisabled(true)
        }
    }

    const loadBlockchainData = async () => {
        const web3 = new Web3(Web3.givenProvider || "http://localhost:8545")
        const accounts = await web3.eth.getAccounts()
        // setAccount(accounts[0])

        const fetchStaker = new web3.eth.Contract(STAKER_ABI, STAKER_ADDRESS)
        // setStaker(fetchStaker)

        const fetchedNpc = new web3.eth.Contract(NPC_ABI, NPC_ADDRESS)
        // setNpc(fetchedNpc)

        const fetchedNftCount = await fetchedNpc.methods.balanceOf(accounts[0]).call()
        // setNftCount(fetchedNftCount)

        const fetchedNftApproval = await fetchedNpc.methods.isApprovedForAll(accounts[0], STAKER_ADDRESS).call()
        // setNftApproval(fetchedNftApproval)

        // updateButtons(fetchedNftApproval)
        console.log("Loaded")

        for (var i = 0; i <= fetchedNftCount; i++) {
            const nft_id = await fetchedNpc.methods.tokenOfOwnerByIndex(accounts[0],i).call()
            setNftIds(prev => ([...prev, nft_id]))
        }
        setLoading(false)
    }

    // const stakeSelected = (content) => {
    //     setLoading(true)
    //     staker.methods.stake_npc(content).send({from: account})
    //         .once('receipt', () => {
    //             //this.setState({ loading: false })
    //             updateButtons()
    //         })
    // }
    //
    // const approveAll = () => {
    //     //this.state.npc.methods.setApprovalForAll().send({from: this.state.account})
    //     npc.methods.setApprovalForAll('0xcB64aD4B67fc2bffC01a2685237Bf8DC4aC93B4b', true).send({from: account})
    //
    //     //this.setState({stakeButtonDisabled: false})
    //     updateButtons()
    // }
    //
    //
    // const toggleChecked = (listId) => {
    //     console.log("listId")
    //     console.log('listId' + listId)
    //
    //     if (listId in stakeList) {
    //         console.log("Pruning")
    //         const list = stakeList
    //         for (var i in list) {
    //             if(list[i] == listId) {
    //                 delete list[i]
    //             }
    //         }
    //
    //         setStakeList(list)
    //     } else{
    //         console.log("Adding")
    //         setStakeList([...stakeList, '' + listId])
    //     }
    //     console.log(stakeList)
    // }

    //  onMount
    useEffect(() => {
        console.log('init MainApp')
        loadBlockchainData()
    }, [])

    return null

//    return (
//        <>
//            <h1>Staker</h1>
//            <p>Your account: {account}</p>
//            <p>Your balance: {nftCount}</p>
//            <p>Your approval: {nftApproval ? 'true' : 'false'}</p>
//            <p>Your stake menu: {stakeList}</p>
//            <p>stakeButtonDisabled: {stakeButtonDisabled ? 'true' : 'false'}</p>
//
//            <main role="main" className="col-lg-12 d-flex justify-content-center">
//                { loading
//                    ? <div id="loader" className="text-center"><p className="text-center">Loading...</p></div>
//                    : <Stake
//                        nftIds={nftIds}
//                        stakeButtonDisabled={stakeButtonDisabled}
//                        stakeSelected={stakeSelected}
//                        approveAll={approveAll}
//                        toggleChecked={toggleChecked}
//                    />
//                }
//            </main>
//        </>
//    )
}

export default MainApp
