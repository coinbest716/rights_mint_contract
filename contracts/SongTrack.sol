// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IMarketPlace.sol";
import "hardhat/console.sol";

/**
 * @title SongTrack
 * SongTrack - ERC1155 contract that whitelists an operator address, 
 * has mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract SongTrack is ERC1155Supply, Ownable {
    using SafeMath for uint256;
    string public name;
    string public symbol;

    uint256 private _currentTokenID = 0;
    uint256 public nftPrice = 0.001 ether;
    address private immutable marketplaceAddr;
    struct TrackInfo {
        string uri;
        address creator;
    }
    // Optional mapping for token URIs
    mapping(uint256 => TrackInfo) private _trackInfos;

    /// @notice Platform fee
    uint256 public platformFee;
    // Platform fee receipient
    address payable public feeReceipient;

    event BatchMint(uint256[] ids, string[] uris);

    constructor(
        uint256 _platformFee,
        address payable _feeReceipient,
        address _marketplaceAddr,
        string memory _name,
        string memory _symbol
    ) ERC1155("") {
        platformFee = _platformFee;
        feeReceipient = _feeReceipient;
        marketplaceAddr = _marketplaceAddr;
        name = _name; //"Dua in Hanburg";
        symbol = _symbol; //"Dua Lipa";
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return _trackInfos[_id].uri;
    }

    // /**
    //  * @dev Returns the total quantity for a token ID
    //  * @param _id uint256 ID of the token to query
    //  * @return amount of token in existence
    //  */
    // function totalSupply(uint256 _id) public view returns (uint256) {
    //     return tokenSupply[_id];
    // }

    /**
     * @dev Creates a new token type and assigns _supply to an address
     * @param _to owner address of the new token
     * @param _supply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     */
    function mint(
        address _to,
        uint256 _supply,
        string calldata _uri
    ) external payable {
        require(msg.value >= platformFee, "Insufficient funds to mint.");

        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        _mint(_to, _id, _supply, bytes(""));
        setApprovalForAll(marketplaceAddr, true);
        //added to the list of marketplace
        IMarketPlace(marketplaceAddr).createMarketItem(
            msg.sender,
            address(this),
            _id,
            _supply,
            nftPrice
        );
        _trackInfos[_id].uri = _uri;
        _trackInfos[_id].creator = _to;

        (bool success, ) = feeReceipient.call{value: msg.value}("");
        require(success, "Transfer failed");

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }
    }

    /**
     * @dev Creates a new token type and assigns _supply to an address
     * @param _to owner address of the new token
     * @param _supplys Optional amount to supply the first owner
     * @param _uris Optional URI for this token type
     */
    function mintBatch(
        address _to,
        uint256[] calldata _supplys,
        string[] calldata _uris
    ) external payable {
        require(msg.value >= platformFee, "Insufficient funds to mint.");
        require(
            _supplys.length == _uris.length,
            "supplys and uris have a same length"
        );

        uint256[] memory ids = new uint256[](_supplys.length);
        for (uint256 i = 0; i < _supplys.length; i++) {
            ids[i] = _getNextTokenID();
            _incrementTokenTypeId();
        }

        _mintBatch(_to, ids, _supplys, bytes(""));
        setApprovalForAll(marketplaceAddr, true);

        //added to the list of marketplace
        for (uint256 i = 0; i < _supplys.length; i++) {
            IMarketPlace(marketplaceAddr).createMarketItem(
                msg.sender,
                address(this),
                ids[i],
                _supplys[i],
                nftPrice
            );
            _trackInfos[ids[i]].uri = _uris[i];
            _trackInfos[ids[i]].creator = _to;
        }

        (bool success, ) = feeReceipient.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit BatchMint(ids, _uris);
    }

    /**
    @param price - price of individual NFT
     */
    function setNFTPrice(uint256 price) external onlyOwner {
        nftPrice = price;
    }

    function getCurrentTokenID() public view returns (uint256) {
        return _currentTokenID;
    }

    /**
     * Override isApprovedForAll to whitelist SongAlbum contracts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }
}
