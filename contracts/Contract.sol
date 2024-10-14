// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract MyContract is ReentrancyGuard {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    event CampaignCreated(uint256 id, address owner, string title, uint256 target, uint256 deadline, string image);
    event DonationMade(uint256 campaignId, address donator, uint256 amount);

    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");
        require(_target > 0, "Target must be greater than zero.");

        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = msg.sender; // Set the creator as the owner
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        emit CampaignCreated(numberOfCampaigns, msg.sender, _title, _target, _deadline, _image);

        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable nonReentrant {
        uint256 amount = msg.value;

        require(_id < numberOfCampaigns, "Campaign does not exist.");
        require(amount > 0, "Donation must be greater than zero.");

        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.deadline, "Campaign has ended.");

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        
        (bool sent,) = payable(campaign.owner).call{value: amount}("");
        require(sent, "Failed to send Ether.");

        campaign.amountCollected += amount;

        emit DonationMade(_id, msg.sender, amount);
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint i = 0; i < numberOfCampaigns; i++) {
            allCampaigns[i] = campaigns[i];
        }

        return allCampaigns;
    }
}
