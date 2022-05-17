// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IMarketPlace.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SongMarketplace is ReentrancyGuard, IMarketPlace {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _itemCounter; //start from 1

    address payable public marketowner;
    uint256 public listingFee = 0.025 ether;

    enum State {
        Created,
        Release,
        Inactive
    }

    struct MarketItem {
        uint256 id;
        uint256 quantity;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable buyer;
        uint256 price;
        State state;
    }

    mapping(uint256 => MarketItem) public marketItems;

    event MarketItemCreated(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 quantity,
        address seller,
        address buyer,
        uint256 price,
        State state
    );

    event MarketItemSold(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 quantity,
        address seller,
        address buyer,
        uint256 price,
        State state
    );

    constructor() {
        marketowner = payable(msg.sender);
    }

    /**
     * @dev Returns the listing fee of the marketplace
     */
    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    /**
     * @dev create a MarketItem for NFT sale on the marketplace.
     *
     * List an NFT.
     */
    function createMarketItem(
        address nftOwner,
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external override nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        // require(msg.value == listingFee, "Fee must be equal to listing fee");

        //token id and marketitem index id is same
        _itemCounter.increment();
        uint256 id = _itemCounter.current();

        marketItems[id] = MarketItem(
            id,
            quantity,
            nftContract,
            tokenId,
            payable(nftOwner),
            payable(address(0)),
            price,
            State.Created
        );

        require(
            IERC1155(nftContract).isApprovedForAll(nftOwner, address(this)) ==
                true,
            "NFT must be approved to market"
        );

        // change to approve mechanism from the original direct transfer to market
        // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            id,
            nftContract,
            tokenId,
            quantity,
            msg.sender,
            address(0),
            price,
            State.Created
        );
    }

    /**
     * @dev delete a MarketItem from the marketplace.
     *
     * de-List an NFT.
     *
     * todo ERC721.approve can't work properly!! comment out
     */
    function deleteMarketItem(uint256 itemId) public nonReentrant {
        require(itemId <= _itemCounter.current(), "id must <= item count");
        require(
            marketItems[itemId].state == State.Created,
            "item must be on market"
        );
        MarketItem storage item = marketItems[itemId];

        require(
            IERC721(item.nftContract).ownerOf(item.tokenId) == msg.sender,
            "must be the owner"
        );
        require(
            IERC1155(item.nftContract).isApprovedForAll(
                item.seller,
                address(this)
            ) == true,
            "NFT must be approved to market"
        );

        item.state = State.Inactive;

        emit MarketItemSold(
            itemId,
            item.nftContract,
            item.tokenId,
            item.quantity,
            item.seller,
            address(0),
            0,
            State.Inactive
        );
    }

    /**
     * @dev (buyer) buy a MarketItem from the marketplace.
     * Transfers ownership of the item, as well as funds
     * NFT:         seller    -> buyer
     * value:       buyer     -> seller
     * listingFee:  contract  -> marketowner
     */
    function createMarketSale(
        address nftContract,
        uint256 id,
        uint256 quantity
    ) public payable nonReentrant {
        MarketItem storage item = marketItems[id]; //should use storge!!!!
        uint256 price = item.price;
        uint256 tokenId = item.tokenId;
        require(item.state != State.Release, "All nfts are sold");
        require(item.seller != msg.sender, "Can't buy your NFT");
        require(
            msg.value == price * quantity,
            "Please submit the correct price"
        );
        require(
            IERC1155(item.nftContract).isApprovedForAll(
                item.seller,
                address(this)
            ) == true,
            "NFT must be approved to market"
        );

        require(item.quantity + 1 > quantity, "Quantity exceeds");

        item.buyer = payable(msg.sender);
        item.quantity = item.quantity.sub(quantity);
        if (item.quantity == 0) {
            //if all NFTs are sold
            item.state = State.Release;
        }

        IERC1155(nftContract).safeTransferFrom(
            item.seller,
            msg.sender,
            tokenId,
            quantity,
            ""
        );
        // payable(marketowner).transfer(listingFee);
        item.seller.transfer(msg.value);

        emit MarketItemSold(
            id,
            nftContract,
            tokenId,
            item.quantity,
            item.seller,
            msg.sender,
            price,
            State.Release
        );
    }

    /**
     * @dev Returns all unsold market items
     * condition:
     *  1) state == Created
     *  2) buyer = 0x0
     *  3) still have approve
     */
    function fetchActiveItems() public view returns (MarketItem[] memory) {
        return fetchHepler(FetchOperator.ActiveItems);
    }

    /**
     * @dev Returns only market items a user has purchased
     * todo pagination
     */
    function fetchMyPurchasedItems() public view returns (MarketItem[] memory) {
        return fetchHepler(FetchOperator.MyPurchasedItems);
    }

    /**
     * @dev Returns only market items a user has created
     * todo pagination
     */
    function fetchMyCreatedItems() public view returns (MarketItem[] memory) {
        return fetchHepler(FetchOperator.MyCreatedItems);
    }

    enum FetchOperator {
        ActiveItems,
        MyPurchasedItems,
        MyCreatedItems
    }

    /**
     * @dev fetch helper
     * todo pagination
     */
    function fetchHepler(FetchOperator _op)
        private
        view
        returns (MarketItem[] memory)
    {
        uint256 total = _itemCounter.current();
        console.log("total count ", total);
        uint256 itemCount = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op)) {
                itemCount++;
            }
        }

        uint256 index = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op)) {
                items[index] = marketItems[i];
                index++;
            }
        }
        return items;
    }

    /**
     * @dev helper to build condition
     *
     * todo should reduce duplicate contract call here
     *
     */
    function isCondition(MarketItem memory item, FetchOperator _op)
        private
        view
        returns (bool)
    {
        if (_op == FetchOperator.MyCreatedItems) {
            return
                (item.seller == msg.sender && item.state != State.Inactive)
                    ? true
                    : false;
        } else if (_op == FetchOperator.MyPurchasedItems) {
            return (item.buyer == msg.sender) ? true : false;
        } else if (_op == FetchOperator.ActiveItems) {
            return
                (item.buyer == address(0) &&
                    item.state == State.Created &&
                    (IERC1155(item.nftContract).isApprovedForAll(
                        item.seller,
                        address(this)
                    ) == true))
                    ? true
                    : false;
        } else {
            return false;
        }
    }
}
