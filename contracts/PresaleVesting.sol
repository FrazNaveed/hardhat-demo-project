// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract TestController {
    event TokenPurchased(address indexed _owner, uint256 _amount, uint256 _bnb);
    event ClaimedToken(address indexed _owner, uint256 _stakeId, uint256 _date);
    IToken Token;

    bool public is_preselling;
    address payable owner;
    // address payable tokenSource = payable(0x9bE5cB252c30db05b82354C0E58A8F922406C1af);
    // address payable fundreceiver = payable(0xAd9De7bEe3e73b327f997766c86C67feAB3Da1D4);

    address payable tokenSource =
        payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    address payable fundreceiver =
        payable(0xAd9De7bEe3e73b327f997766c86C67feAB3Da1D4);
    uint256 baseTokenPrice = 285714285714286;
    uint256 soldTokens;
    uint256 receivedFunds;

    struct tokenVesting {
        uint256 amount;
        uint256 date_added;
        uint256 redeem_date;
        uint256 redeem_count;
    }

    uint256 redemptionCount = 1; //1 time to redeem
    uint256 lockDays = 270; //9 months duration every redemption
    uint256 rewardRate = 7; //7% reward for vesting the tokens
    uint256 public RecordId;
    mapping(uint256 => tokenVesting) idVesting;
    // mapping(uint256 => address) recordIdOwner;
    mapping(address => uint256[]) OwnerRecordId;

    mapping(address => bool) public check;

    constructor(IToken _tokenAddress) {
        Token = _tokenAddress;
        owner = payable(msg.sender);
        is_preselling = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "invalid owner");
        _;
    }

    receive() external payable {
        uint256 amount = msg.value / baseTokenPrice;
        tokensale(amount);
    }

    function setBaseTokenPrice() public view onlyOwner returns (uint256) {}

    //buy tokens
    function tokensale(uint256 _amount) public payable returns (bool) {
        require(is_preselling, "pre selling is over.");
        require(_amount >= 1, "Amount should be greater thatn 1e18");
        // 1000000000000001000 wei or 1 BNB = 3500 Token
        require(msg.value == _amount * baseTokenPrice, "Incorrect BNB amount ");
        uint256 _rewardAmount = (_amount * rewardRate) / 100; //get total reward for vesting
        uint256 _totalTokens = _amount + _rewardAmount; //total tokens (principal + reward)
        RecordId += 1;
        tokenVesting storage _vesting = idVesting[RecordId];
        _vesting.amount = _totalTokens;
        _vesting.date_added = block.timestamp;
        _vesting.redeem_date = block.timestamp + (lockDays * 1 days); //set 1st redemption date (+30 days)

        //track down the owner of the record id
        // recordIdOwner[RecordId] = msg.sender;

        OwnerRecordId[msg.sender].push(RecordId);
        Token.transferFrom(tokenSource, address(this), _totalTokens);
        fundreceiver.transfer(msg.value);
        soldTokens += _amount;
        receivedFunds += msg.value;
        emit TokenPurchased(msg.sender, _amount, msg.value);
        return true;
    }

    function Redeem() public returns (bool) {
        uint256 _id = OwnerRecordId[msg.sender][0];

        //verify the owner of the stake record
        // address _recordOwner = recordIdOwner[_id];
        // require(_recordOwner == msg.sender, "invalid owner");

        tokenVesting storage _vesting = idVesting[_id];
        //validate if total redemption is not greater than 4 or (redemption count)
        require(_vesting.redeem_count < redemptionCount, "already redeemed");

        //validate if redemption date is ready
        uint256 _redeemDate = _vesting.redeem_date;
        require(block.timestamp >= _redeemDate, "not yet ready to redeem");

        //amount every redemption (divided by number of redemption or 4)
        uint256 _redeemAmount = _vesting.amount / redemptionCount;

        _vesting.redeem_count += 1; //update count of redemption max of 4

        _vesting.redeem_date = block.timestamp + (lockDays * 1 days); // update date for next redemption +30 days

        //tokens will be transferred to user's wallet address
        Token.transfer(msg.sender, _redeemAmount);
        emit ClaimedToken(msg.sender, _id, block.timestamp);
        return true;
    }

    function getTokenSupply() public view returns (uint256) {
        return Token.totalSupply();
    }

    function getTokenbalance(address _address) public view returns (uint256) {
        return Token.balanceOf(_address);
    }

    function totalSoldTokens() public view returns (uint256) {
        return soldTokens;
    }

    function totalReceivedFunds() public view returns (uint256) {
        return receivedFunds;
    }

    function getbalance() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function SetReceiver(address payable _fund) public onlyOwner {
        fundreceiver = _fund;
    }

    function SetPreSellingStatus() public onlyOwner {
        if (is_preselling) {
            is_preselling = false;
        } else {
            is_preselling = true;
        }
    }
}
