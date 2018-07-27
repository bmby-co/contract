pragma solidity ^0.4.17;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

contract BMBYToken is ERC721Token("BMBY", "BMBY"), Ownable {

    struct BMBYTokenInfo {
        uint64 timestamp;
        string userId;
    }

    BMBYTokenInfo[] public tokens;

    mapping(uint256 => address) private creators;
    mapping(uint256 => uint256) private prices;

    address public ceoAddress;
    uint64 public creationFee;
    uint64 public initialTokenValue;
    string public baseURI;

    uint public currentOwnerFeePercent;
    uint public creatorFeePercent;

    uint256 public priceStep1;
    uint256 public priceStep2;
    uint256 public priceStep3;
    uint256 public priceStep4;
    uint256 public priceStep5;
    uint256 public priceStep6;
    uint256 public priceStep7;
    uint256 public priceStep8;

    event TokenCreated(uint256 tokenId, uint64 timestamp, string userId, address creator);
    event TokenSold(uint256 tokenId, uint256 oldPriceInEther, uint256 newPriceInEther, address prevOwner, address newOwener);

    // --------------


    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    constructor() public {
        ceoAddress = msg.sender;
        baseURI = "https://bmby.co/api/tokens/";

        creationFee = 0.03 ether;
        initialTokenValue = 0.06 ether;

        priceStep1 = 5.0 ether;
        priceStep2 = 10.0 ether;
        priceStep3 = 20.0 ether;
        priceStep4 = 30.0 ether;
        priceStep5 = 40.0 ether;
        priceStep6 = 50.0 ether;
        priceStep7 = 60.0 ether;
        priceStep8 = 70.0 ether;

        currentOwnerFeePercent = 85;
        creatorFeePercent = 5;
    }


    function getNewTokenPrice(uint256 currentTokenPrice) public view returns (uint256){

        uint newPriceValuePercent;

        if (currentTokenPrice <= priceStep1) {
            newPriceValuePercent = 200;
        } else if (currentTokenPrice <= priceStep2) {
            newPriceValuePercent = 150;
        } else if (currentTokenPrice <= priceStep3) {
            newPriceValuePercent = 135;
        } else if (currentTokenPrice <= priceStep4) {
            newPriceValuePercent = 125;
        } else if (currentTokenPrice <= priceStep5) {
            newPriceValuePercent = 120;
        } else if (currentTokenPrice <= priceStep6) {
            newPriceValuePercent = 117;
        } else if (currentTokenPrice <= priceStep7) {
            newPriceValuePercent = 115;
        } else if (currentTokenPrice <= priceStep8) {
            newPriceValuePercent = 113;
        } else {
            newPriceValuePercent = 110;
        }

        return currentTokenPrice.mul(newPriceValuePercent).div(100);
    }

    // ------------------------
    // Critical

    function mint(string userId) public payable {

        require(msg.value >= creationFee);
        address tokenCreator = msg.sender;

        require(isValidAddress(tokenCreator));

        uint64 timestamp = uint64(now);

        BMBYTokenInfo memory newToken = BMBYTokenInfo({timestamp : timestamp, userId : userId});

        uint256 tokenId = tokens.push(newToken) - 1;

        require(tokenId == uint256(uint32(tokenId)));

        prices[tokenId] = initialTokenValue;
        creators[tokenId] = tokenCreator;

        string memory tokenIdString = toString(tokenId);
        string memory tokenUri = concat(baseURI, tokenIdString);

        _mint(tokenCreator, tokenId);
        _setTokenURI(tokenId, tokenUri);

        emit TokenCreated(tokenId, timestamp, userId, tokenCreator);
    }

    function purchase(uint256 tokenId) public payable {

        address newHolder = msg.sender;
        address holder = ownerOf(tokenId);

        require(holder != newHolder);

        uint256 contractPayment = msg.value;

        require(contractPayment > 0);
        require(isValidAddress(newHolder));

        uint256 currentTokenPrice = prices[tokenId];

        require(currentTokenPrice > 0);

        require(contractPayment >= currentTokenPrice);

        // -------------------
        // New Price

        uint256 newTokenPrice = getNewTokenPrice(currentTokenPrice);
        require(newTokenPrice > currentTokenPrice);

        // ------------------------------

        uint256 currentOwnerFee = uint256(currentTokenPrice.mul(currentOwnerFeePercent).div(100));
        uint256 creatorFee = uint256(currentTokenPrice.mul(creatorFeePercent).div(100));

        require(contractPayment > currentOwnerFee + creatorFee);

        // ------------------------------

        address creator = creators[tokenId];

        // If the current owner is the contract, the money is already in the balance so there's no need to transfer
        if (holder != address(this)) {
            // send money to the seller
            holder.transfer(currentOwnerFee);
        }

        // if the current owner is the creator, we don't give fee at this stage. only if other people purchase you
        if (holder != creator) {
            // send money to the creator
            creator.transfer(creatorFee);
        }

        emit Transfer(holder, newHolder, tokenId);
        emit TokenSold(tokenId, currentTokenPrice, newTokenPrice, holder, newHolder);

        removeTokenFrom(holder, tokenId);
        addTokenTo(newHolder, tokenId);

        prices[tokenId] = newTokenPrice;
    }

    function payout(uint256 amount, address destination) public onlyCEO {
        require(isValidAddress(destination));
        uint balance = address(this).balance;
        require(balance >= amount);
        destination.transfer(amount);
    }

    // ------------------------
    // Setters

    function setCEOAddress(address newValue) public onlyCEO {
        require(isValidAddress(newValue));
        ceoAddress = newValue;
    }

    function setCreationFee(uint64 newValue) public onlyCEO {
        creationFee = newValue;
    }

    function setInitialTokenValue(uint64 newValue) public onlyCEO {
        initialTokenValue = newValue;
    }

    function setBaseURI(string newValue) public onlyCEO {
        baseURI = newValue;
    }

    function setCurrentOwnerFeePercent(uint newValue) public onlyCEO {
        currentOwnerFeePercent = newValue;
    }

    function setCreatorFeePercent(uint newValue) public onlyCEO {
        creatorFeePercent = newValue;
    }

    function setPriceStep1(uint256 newValue) public onlyCEO {
        priceStep1 = newValue;
    }

    function setPriceStep2(uint256 newValue) public onlyCEO {
        priceStep2 = newValue;
    }

    function setPriceStep3(uint256 newValue) public onlyCEO {
        priceStep3 = newValue;
    }

    function setPriceStep4(uint256 newValue) public onlyCEO {
        priceStep4 = newValue;
    }

    function setPriceStep5(uint256 newValue) public onlyCEO {
        priceStep5 = newValue;
    }

    function setPriceStep6(uint256 newValue) public onlyCEO {
        priceStep6 = newValue;
    }

    function setPriceStep7(uint256 newValue) public onlyCEO {
        priceStep7 = newValue;
    }

    function setPriceStep8(uint256 newValue) public onlyCEO {
        priceStep8 = newValue;
    }

    // ------------------------
    // Getters

    function getTokenInfo(uint tokenId) public view returns (string userId, uint64 timestamp, address creator, address holder, uint256 price){
        BMBYTokenInfo memory tokenInfo = tokens[tokenId];

        userId = tokenInfo.userId;
        timestamp = tokenInfo.timestamp;
        creator = creators[tokenId];
        holder = ownerOf(tokenId);
        price = prices[tokenId];
    }

    function getTokenCreator(uint256 tokenId) public view returns (address) {
        return creators[tokenId];
    }

    function getTokenPrice(uint256 tokenId) public view returns (uint256) {
        return prices[tokenId];
    }


    // -----------------
    // Utilities

    function toString(uint256 v) private pure returns (string) {
        if (v == 0) {
            return "0";
        }
        else {
            uint maxlength = 100;
            bytes memory reversed = new bytes(maxlength);
            uint i = 0;
            while (v != 0) {
                uint remainder = v % 10;
                v = v / 10;
                reversed[i] = byte(48 + remainder);

                if (v != 0) {
                    i++;
                }
            }

            bytes memory s = new bytes(i + 1);
            for (uint j = 0; j <= i; j++) {
                s[j] = reversed[i - j];
            }
            return string(s);

        }
    }

    function concat(string _a, string _b) private pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        return string(babcde);
    }

    function isValidAddress(address addr) private pure returns (bool) {
        return addr != address(0);
    }

}
