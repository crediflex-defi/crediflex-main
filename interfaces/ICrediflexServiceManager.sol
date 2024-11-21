// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICrediflexServiceManager {
    event NewTaskCreated(uint32 indexed taskIndex, Task task);
    event TaskResponded(uint32 indexed taskIndex, Task task, address operator);
    event CScoreInserted(address indexed user, uint256 cScore, uint256 timestamp);

    struct Task {
        address user;
        uint256 cScore;
        uint32 taskCreatedBlock;
    }

    struct CScoreData {
        uint256 cScore;
        uint256 lastUpdate;
    }

    function getUserCScoreData(address user) external view returns (CScoreData memory);

    function latestTaskNum() external view returns (uint32);

    function allTaskHashes(uint32 taskIndex) external view returns (bytes32);

    function allTaskResponses(address operator, uint32 taskIndex) external view returns (bytes memory);

    function createNewTask(address user, uint256 cScore) external returns (Task memory);

    function respondToTask(Task calldata task, uint32 referenceTaskIndex, bytes calldata signature) external;
}
