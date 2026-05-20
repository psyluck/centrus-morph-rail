// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CentrusMorphSettlement
 * @dev Handles automated institutional last-mile distribution across settlement rails.
 */
contract CentrusMorphSettlement {
    
    struct RailDistribution {
        address targetRail; // The address handling the specific rail liquidity (XRPL, RLUSD, USDC Arc)
        uint256 weight;     // Basis points (e.g., 1000 = 10%, 10000 = 100%)
        bool isActive;
    }

    address public owner;
    
    // Maps a unique corporate client or batch ID to its target distribution matrix
    mapping(bytes32 => RailDistribution[]) private distributionMatrices;

    event SettlementExecuted(bytes32 indexed batchId, address indexed token, uint256 totalAmount);
    event RailSettled(bytes32 indexed batchId, address indexed targetRail, uint256 amountDistributed);
    event MatrixConfigured(bytes32 indexed batchId, uint256 totalRails);

    modifier onlyOwner() {
        require(msg.sender == owner, "Centrus: Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Configures the settlement matrix weights for a specific distribution path.
     * @param batchId The unique identifier representing this transaction flow or client strategy.
     * @param targets An array of rail target addresses.
     * @param weights An array of weights in basis points (must sum to 10,000).
     */
    function configureMatrix(
        bytes32 batchId,
        address[] calldata targets,
        uint256[] calldata weights
    ) external onlyOwner {
        require(targets.length == weights.length, "Centrus: Mismatched array lengths");
        require(targets.length > 0, "Centrus: No targets provided");

        // Clear existing matrix if updating
        delete distributionMatrices[batchId];

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < targets.length; i++) {
            require(targets[i] != address(0), "Centrus: Invalid target rail");
            require(weights[i] > 0, "Centrus: Weight must exceed zero");
            
            distributionMatrices[batchId].push(RailDistribution({
                targetRail: targets[i],
                weight: weights[i],
                isActive: true
            }));
            
            totalWeight += weights[i];
        }

        // 10,000 basis points equals exactly 100.00%
        require(totalWeight == 10000, "Centrus: Total weights must equal 10000 bps");

        emit MatrixConfigured(batchId, targets.length);
    }

    /**
     * @notice Programmatically distributes assets to last-mile rails based on configured weights.
     * @dev For this hackathon baseline, it handles native asset routing (e.g., ETH/Morph).
     * @param batchId The unique matrix configuration profile to execute.
     */
    function executeSettlement(bytes32 batchId) external payable {
        uint256 totalAmount = msg.value;
        require(totalAmount > 0, "Centrus: Settlement amount must be greater than 0");
        
        RailDistribution[] memory rails = distributionMatrices[batchId];
        require(rails.length > 0, "Centrus: Distribution matrix not configured");

        emit SettlementExecuted(batchId, address(0), totalAmount);

        for (uint256 i = 0; i < rails.length; i++) {
            if (rails[i].isActive) {
                // Calculate fractional distribution mathematically: (Amount * Weight) / 10,000
                uint256 distributionAmount = (totalAmount * rails[i].weight) / 10000;
                
                if (distributionAmount > 0) {
                    (bool success, ) = rails[i].targetRail.call{value: distributionAmount}("");
                    require(success, "Centrus: Last-mile rail transfer failed");
                    
                    emit RailSettled(batchId, rails[i].targetRail, distributionAmount);
                }
            }
        }
    }

    /**
     * @notice Helper to inspect a configured matrix profile
     */
    function getMatrix(bytes32 batchId) external view returns (RailDistribution[] memory) {
        return distributionMatrices[batchId];
    }
}