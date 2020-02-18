pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/VotingInterface.sol";

/**
 * @title Library to compute rounds and phases for an equal length commit-reveal voting cycle. 
 */
library VoteTiming {
    using SafeMath for uint;

    struct Data {
        uint phaseLength;
    }

    /**
     * @notice Initializes the data object. Sets the phase length based on the input.
     */
    function init(Data storage data, uint phaseLength) internal {
        data.phaseLength = phaseLength;
    }

    /**
     * @notice Computes the roundID based off the current time as floor(timestamp/phaseLength).
     */
    function computeCurrentRoundId(Data storage data, uint currentTime) internal view returns (uint roundId) {
        uint roundLength = data.phaseLength.mul(uint(VotingInterface.Phase.NUM_PHASES_PLACEHOLDER));
        return currentTime.div(roundLength);
    }

    function computeRoundEndTime(Data storage data, uint roundId) internal view returns (uint timestamp) {
        uint roundLength = data.phaseLength.mul(uint(VotingInterface.Phase.NUM_PHASES_PLACEHOLDER));
        return roundLength.mul(roundId.add(1));
    }

    /**
     * @notice Computes the current phase based only on the current time.
     */
    function computeCurrentPhase(Data storage data, uint currentTime) internal view returns (VotingInterface.Phase) {
        // This employs some hacky casting. We could make this an if-statement if we're worried about type safety.
        return
            VotingInterface.Phase(
                currentTime.div(data.phaseLength).mod(uint(VotingInterface.Phase.NUM_PHASES_PLACEHOLDER))
            );
    }
}