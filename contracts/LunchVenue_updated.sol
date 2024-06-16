/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract to agree on the lunch venue
/// @author Weng Xinn Chow 

contract LunchVenue_updated {
    
    struct Friend {
        string name;
        bool voted; //Vote state
    }
    
    struct Vote {
        address voterAddress;
        uint restaurant;
    }

    mapping (uint => string) public restaurants;   //List of restaurants (restaurant no, name)
    mapping (address => Friend) public friends;    //List of friends (address, Friend)
    uint public numRestaurants = 0;
    uint public numFriends = 0;
    uint public numVotes = 0;
    address public manager;                        //Contract manager
    string public votedRestaurant = "";            //Where to have lunch

    Vote[] public votes;                           //List of votes
    mapping (uint => uint) private _results;       //List of vote counts (restaurant no, no of votes)
    bool public voteOpen = false;                  //voting is open

    //List to track if restaurants exist (restaurantHash, bool)
    //The key is the hash of restaurant's name to ensure efficient lookup
    mapping (bytes32 => bool) private _restaurantExists;

    uint public timeoutBlockNumber;                //Block number when voting should be closed
    bool public isActive = true;                   //Contract status
    address public sender;                         //Message sender

    uint constant DEFAULTTIMEOUTDURATION = 100;    //Default timeout duration

    /**
     * @dev Set manager and lunchtimeBlock when contract starts
     *
     * @param timeoutDuration Duration of voting process
     */
    constructor(uint timeoutDuration) {
        manager = msg.sender;                                 //Set contract creator as manager

        // Set timeout block number to default timeout if 0 timeout duration
        if (timeoutDuration == 0) {
            timeoutDuration = DEFAULTTIMEOUTDURATION;
        }
        timeoutBlockNumber = block.number + timeoutDuration;   //Set timeout block number
        
    }

    /**
     * @notice Add a new restaurant
     * @dev The code checks duplication of restaurants, 
     *      it ensures restaurants can no longer be added once voting is open, 
     *      or when timeout is reached, 
     *      and it is restricted to manager only,
     *      when contract is active
     *
     * @param name Restaurant name
     * @return Number of restaurants added so far
     */
    function addRestaurant(string memory name) public restricted votingDisabled timeoutNotReached active returns (uint) {
        //Check precondition: restaurant hasn't been added
        bytes32 restaurantHash = keccak256(bytes(name));
        require(!_restaurantExists[restaurantHash], "Restaurant already exists");

        // Add restaurant to restaurants list
        numRestaurants++;
        restaurants[numRestaurants] = name;
        _restaurantExists[restaurantHash] = true;
        return numRestaurants;
    }

    /**
     * @notice Add a new friend to voter list
     * @dev The code checks duplication of friends, 
     *      it ensures friends can no longer be added once voting is open,
     *      or when timeout is reached, 
     *      and it is restricted to manager only,
     *      when contract is active
     *
     * @param friendAddress Friend's account/address
     * @param name Friend's name
     * @return Number of friends added so far
     */
    function addFriend(address friendAddress, string memory name) public restricted votingDisabled timeoutNotReached active returns (uint) {
        //Check precondition: friend hasn't been added
        require(bytes(friends[friendAddress].name).length == 0, "Friend already exists");

        // Add friend to friends list
        numFriends++;
        Friend memory f;
        f.name = name;
        f.voted = false;
        friends[friendAddress] = f;
        return numFriends;
    }
    
    /** 
     * @notice Vote for a restaurant
     * @dev The code ensures voting can only be done when voting is open, 
     *      and when timeout is not reached, 
     *      and when quorum is not reached, 
     *      and if contract is active
     *
     * @param restaurant Restaurant number being voted
     * @return validVote Is the vote valid? A valid vote should be from a registered 
     *         friend to a registered restaurant
    */
    function doVote(uint restaurant) public votingOpen active returns (bool validVote) {
        validVote = false;    //Is the vote valid?

        //Check preconditions to vote:
        //Timeout is not reached
        if (block.number >= timeoutBlockNumber) {
            _finalResult();
        }
        //Friend (who votes) exists 
        require(bytes(friends[msg.sender].name).length != 0, "Friend does not exist");
        //Restaurant voted exists
        require(bytes(restaurants[restaurant]).length != 0, "Restaurant voted does not exist");
        //Friend (who votes) has not already voted
        require(!friends[msg.sender].voted, "Friend has voted already");

        // Add vote to votes list
        validVote = true;
        friends[msg.sender].voted = true;
        numVotes++;
        Vote memory v;
        v.voterAddress = msg.sender;
        v.restaurant = restaurant;
        votes.push(v);
        
        //Quorum is met
        if (numVotes >= numFriends/2 + 1) {
            _finalResult();
        }
        return validVote;
    }

    /** 
     * @notice Determine winner restaurant
     * @dev The code checks if contract is active
     *      If top 2 restaurants have the same no of votes, result depends on vote order
    */
    function _finalResult() private active {
        uint highestVotes = 0;
        uint highestRestaurant = 0;
        
        //For each vote
        for (uint i = 0; i < numVotes; i++) {
            uint voteCount = 1;
            //Already start counting
            //Update votes for existed restaurants in results list
            if(_results[votes[i].restaurant] > 0) {
                voteCount += _results[votes[i].restaurant];
            }
            // Add restaurants and corresponding votes to results list
            _results[votes[i].restaurant] = voteCount;

            // New winner
            if (voteCount > highestVotes){
                highestVotes = voteCount;
                highestRestaurant = votes[i].restaurant;
            }
        }
        votedRestaurant = restaurants[highestRestaurant];   //Chosen restaurant
        voteOpen = false;                                   //Voting is now closed
    }

    /** 
     * @notice Set duration of voting
     * @dev The code checks if contract is active, 
     *      and is restricted to manager only
     *
     * @param timeoutDuration Duration of voting process
    */
    function setTimeoutDuration(uint timeoutDuration) public restricted active returns (bool status) {
        status = false;   // Change status
        timeoutBlockNumber = block.number + timeoutDuration;

        if (block.number <= timeoutBlockNumber) {
            voteOpen = false;
        }

        status = true;
        return status;
    }

    /** 
     * @notice Enable voting
     * @dev The code checks if contract is active, 
     *      and is restricted to manager only
     *
    */
    function enableVoting() public restricted active {
        //Precondition to enable voting: 
        //At least 2 restaurants for voting
        require(numRestaurants >= 2, "Can vote only when there are at least 2 restaurants");
        //At least 2 friends to vote
        require(numFriends >= 2, "Can vote only when there are at least 2 friends");
        //Timeout is not reached
        require(block.number < timeoutBlockNumber, "Timeout reached and voting is closed");

        voteOpen = true;
    }

    /** 
     * @notice Disable contract
     * @dev The code checks if contract is active, 
     *      and is restricted to manager only
     *
    */
    function disableContract() public restricted active {
        isActive = false;
    }
    
    /** 
     * @notice Only the manager can do
     */
    modifier restricted() {
        require (msg.sender == manager, "Can only be executed by the manager");
        _;
    }
    
    /**
     * @notice Only when voting is still open
     */
    modifier votingOpen() {
        require(voteOpen == true, "Can vote only while voting is open");
        _;
    }

    /**
     * @notice Only when voting is closed
     */
    modifier votingDisabled() {
        require(voteOpen == false, "Can add friends or restaurants only when voting is disabled");
        _;
    }

    /**
     * @notice Only when timeout is not reached
     */
    modifier timeoutNotReached() {
        require(block.number < timeoutBlockNumber, "Timeout reached");
        _;
    }

    /**
     * @notice Only when contract is active
     */
    modifier active() {
        require(isActive == true, "Only when contract is active");
        _;
    }
}