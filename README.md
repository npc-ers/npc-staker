## Setup
- Add WEB3_INFURA_PROJECT_ID to your env
- Follow setup instructions for brownie

### Tests
- Run `brownie test --network mainnet-fork`


### Troubleshooting
`Unknown contract address` and/or Brownie does not autofetch Contract sources`

- Replace `Contract("CANT_FIND")` with `Contract.from_explorer(`
- Run once to download all contracts
- Will likely hit rate limiting error
- Revert changes using `from_explorer`
- Profit