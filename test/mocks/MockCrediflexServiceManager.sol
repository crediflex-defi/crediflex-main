// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ICrediflexServiceManager} from "../../interfaces/ICrediflexServiceManager.sol";

contract MockCrediflexServiceManager is ICrediflexServiceManager {
    uint32 public latestTaskNum;
    mapping(uint32 => bytes32) public allTaskHashes;
    mapping(address => mapping(uint32 => bytes)) public allTaskResponses;
    mapping(address => CScoreData) private _userCScoreData;

    function createNewTask(address user) external returns (Task memory) {
        Task memory newTask;
        newTask.user = user;
        newTask.taskCreatedBlock = uint32(block.number);

        // store hash of task onchain, emit event, and increase taskNum
        allTaskHashes[latestTaskNum] = keccak256(abi.encode(newTask));
        emit NewTaskCreated(latestTaskNum, newTask);
        latestTaskNum = latestTaskNum + 1;

        return newTask;
    }

    function respondToTask(
        Task calldata task,
        uint256 cScore,
        uint32, /*referenceTaskIndex*/
        bytes calldata /* signature */
    ) external {
        allTaskResponses[msg.sender][latestTaskNum] = "";
        _userCScoreData[task.user] = CScoreData({cScore: cScore, lastUpdate: block.timestamp});
        emit CScoreInserted(task.user, cScore, block.timestamp);
        emit TaskResponded(latestTaskNum, task, msg.sender);
    }

    function getUserCScoreData(address user) external view override returns (CScoreData memory) {
        return _userCScoreData[user];
    }
}
