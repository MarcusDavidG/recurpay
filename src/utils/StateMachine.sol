// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract StateMachine {
    enum State {
        CREATED,
        ACTIVE,
        PAUSED,
        CANCELLED,
        EXPIRED,
        SUSPENDED
    }

    struct StateTransition {
        State from;
        State to;
        bool allowed;
        string reason;
    }

    mapping(bytes32 => State) public currentState;
    mapping(bytes32 => StateTransition[]) public stateHistory;
    mapping(State => mapping(State => bool)) public allowedTransitions;

    event StateChanged(bytes32 indexed entityId, State from, State to, string reason);

    constructor() {
        // Define allowed state transitions
        allowedTransitions[State.CREATED][State.ACTIVE] = true;
        allowedTransitions[State.ACTIVE][State.PAUSED] = true;
        allowedTransitions[State.ACTIVE][State.CANCELLED] = true;
        allowedTransitions[State.ACTIVE][State.SUSPENDED] = true;
        allowedTransitions[State.PAUSED][State.ACTIVE] = true;
        allowedTransitions[State.PAUSED][State.CANCELLED] = true;
        allowedTransitions[State.SUSPENDED][State.ACTIVE] = true;
        allowedTransitions[State.SUSPENDED][State.CANCELLED] = true;
    }

    function transitionState(
        bytes32 entityId,
        State newState,
        string memory reason
    ) external {
        State currentStateValue = currentState[entityId];
        require(allowedTransitions[currentStateValue][newState], "Invalid state transition");

        currentState[entityId] = newState;
        
        stateHistory[entityId].push(StateTransition({
            from: currentStateValue,
            to: newState,
            allowed: true,
            reason: reason
        }));

        emit StateChanged(entityId, currentStateValue, newState, reason);
    }

    function getCurrentState(bytes32 entityId) external view returns (State) {
        return currentState[entityId];
    }

    function getStateHistory(bytes32 entityId) external view returns (StateTransition[] memory) {
        return stateHistory[entityId];
    }

    function isTransitionAllowed(State from, State to) external view returns (bool) {
        return allowedTransitions[from][to];
    }
}
