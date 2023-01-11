import React, { Component } from 'react'

class Stake extends Component {
    render() {
        const selected = []
        return(
              <div id="content">
                <form onSubmit={(event) => {
                  event.preventDefault()
                }}>
                  <input type="submit" value='approve' disabled={this.props.approveButtonDisabled} hidden={false} onClick={() => this.props.approveAll()}  />

                  <input type="submit" value='stake' disabled={this.props.stakeButtonDisabled} hidden={false} onClick={() => this.props.stakeSelected(selected) }  />
                </form>
                <ul id="taskList" className="list-unstyled">
                { this.props.nftIds.map((val, key) => {
		    const imgSrc = "https://nftstorage.link/ipfs/bafybeia64ynhssbioiss7fwgiiafrgffakplg6uxt3tamgpvoli5ogrpyi/"+val+".png"
		    const multiplier = this.props.nftMultipliers[key]
		    const nftDomId = "nft-"+val
                    return(
                      <div className="taskTemplate" className="checkbox" key={key}>
                        <label>
                        <center>
                          <input 
                                type="checkbox" 
				id={nftDomId}
                                name={val}
                                  ref={(input) => {
                                    this.checkbox = input
                                  }}

                                onClick={(event) => {
                                    this.props.toggleChecked(val)
                                }}
                                /><br/>
                          <span className="content">
                                <img src={imgSrc} alt={imgSrc} width='100' height='100'  />
                                <br/>
                                Multiplier: {multiplier}
                          </span>
                        </center>
                        </label>
                      </div>
                    )
                  })}
                </ul>
                <ul id="completedTaskList" className="list-unstyled">
                </ul>
              </div>
        );		
    }

}



export default Stake;

