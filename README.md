# Workshop for crafting NFT

This project contains 2 Solidity smart contracts. ERC-1155 standard became the one, which was chosen to be implemented.
`ManuvantaraCollection.sol` has definition for fungible and non-fungible tokens; mints them; keeps track of wallets and amount of tokens they have. It was designed only for owner to work with it, since it contains mostly internal functions.<br />
`Workshop.sol` is aimed for users and contains all main functions.
<br />
<br />
Algorithm of interacting with workshop:

1. Create a token using function `createNewToken`: give it name, define its symbol and fungibility;<br />
2. If token was created as fungible, owner should mint it to proper addresses. Non-fungible tokens are automatically sent to their creator's address and afterwards it is impossible to mint or assemble them;<br />
3. Create a recipe. For this you should use `addRecipe` function. There you should pass:<br/>
   a. ids of input tokens (ids can be found using function `getIdBySymbol`, which takes token's symbol as argument);<br />
   b. amounts of each token **in the same order as it was done with ids**;<br />
   c. id of the output token. To your attention, it is impossible to create more than 1 type of token using any recipe;<br />
4. If you need to change the recipy, you should use `changeRecipe` function. As arguments it takes:<br />
   a. ids of tokens, amount of which you want to change;<br />
   b. new amounts of tokens **in the same order as it was ids were indicated**;<br />
5. Use `assembling` or `disassembling` functions depending on your needs. Please, note that it is possible to assemble something using non-fungible tokens are impossible to assemble, but it can be as an input to assemble something else.
