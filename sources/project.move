module nft_auction_house::auction_house {

    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// An error code for when a bid is too low.
    const E_BID_TOO_LOW: u64 = 1;

    /// An error code for when the auction is not found.
    const E_AUCTION_NOT_FOUND: u64 = 2;

    /// The struct representing an NFT auction.
    struct Auction has store, key {
        nft_id: u64,
        current_bid: u64,
        highest_bidder: address,
    }

    /// A function to start an auction for a specific NFT.
    public entry fun create_auction(
        owner: &signer,
        nft_id: u64
    ) {
        let auction = Auction {
            nft_id,
            current_bid: 0,
            highest_bidder: @0x0,
        };

        move_to(owner, auction);
    }

    /// A function for users to place a bid on an auction.
    public entry fun place_bid(
        bidder: &signer,
        auction_owner: address,
        amount: u64
    ) acquires Auction {
        // Check if the auction exists at the given address
        assert!(exists<Auction>(auction_owner), E_AUCTION_NOT_FOUND);

        let auction = borrow_global_mut<Auction>(auction_owner);

        // Ensure the new bid is higher than the current bid
        assert!(amount > auction.current_bid, E_BID_TOO_LOW);

        // Refund the previous highest bidder, if they exist
        if (auction.highest_bidder != @0x0) {
            let old_bid = coin::withdraw<AptosCoin>(bidder, auction.current_bid);
            coin::deposit<AptosCoin>(auction.highest_bidder, old_bid);
        };

        // Transfer the new bid to the auction owner
        let new_bid = coin::withdraw<AptosCoin>(bidder, amount);
        coin::deposit<AptosCoin>(auction_owner, new_bid);

        // Update the auction state
        auction.current_bid = amount;
        auction.highest_bidder = signer::address_of(bidder);
    }
}