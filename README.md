# P2P Betting Smart Contracts

**P2P Betting is a platform that allows users to create and join sportsbets without the participation of a betting business as an intermediary**

This repo contains the work I made during the 2024 Chainlink BlockMagic Hackathon (https://chain.link/hackathon), the Smart Contracts that act as a backend for the app. The full project with the frontend developed by my teammates is in this repository : https://github.com/martinllobell/dapp

## P2PBettingFront.sol

Contains the different functions that the front-end might need to work correctly. Getters, setters, creating and joining bets, getting the rewards...

## P2PBettingActions.sol

Contains the computationally demaning functions and the usage of chainlink functions.

## P2PBetting.sol

Deprecated. Only there to show the progress made during the month of the hackathon

### Disclaimer

No contracts here have been audited so they should ONLY be deployed to testnets.

## Next Steps : 
- NatSpec for every function and variable
- More testing
