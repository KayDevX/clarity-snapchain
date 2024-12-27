import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can mint a new photo NFT",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('photo-nft', 'mint-photo', [
        types.utf8("Sunset at Beach"),
        types.utf8("Canon EOS R5"),
        types.utf8("Malibu, CA"),
        types.utf8("Beautiful sunset captured at Malibu beach")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    let photoData = chain.callReadOnlyFn(
      'photo-nft',
      'get-photo-data',
      [types.uint(1)],
      deployer.address
    );
    
    photoData.result.expectSome().expectTuple();
  }
});

Clarinet.test({
  name: "Can list and buy photo NFT",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const seller = accounts.get('wallet_1')!;
    const buyer = accounts.get('wallet_2')!;
    
    // First mint NFT
    let block = chain.mineBlock([
      Tx.contractCall('photo-nft', 'mint-photo', [
        types.utf8("Mountain Peak"),
        types.utf8("Sony A7III"),
        types.utf8("Swiss Alps"),
        types.utf8("Majestic mountain peak at sunrise")
      ], seller.address)
    ]);
    
    const tokenId = block.receipts[0].result.expectOk().expectUint(1);
    
    // List NFT for sale
    block = chain.mineBlock([
      Tx.contractCall('photo-nft', 'list-for-sale', [
        types.uint(tokenId),
        types.uint(100000000) // 100 STX
      ], seller.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Buy NFT
    block = chain.mineBlock([
      Tx.contractCall('photo-nft', 'buy-photo', [
        types.uint(tokenId)
      ], buyer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify new owner
    const owner = chain.callReadOnlyFn(
      'photo-nft',
      'get-owner',
      [types.uint(tokenId)],
      deployer.address
    );
    
    owner.result.expectPrincipal(buyer.address);
  }
});