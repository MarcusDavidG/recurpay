// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CircuitBreaker {
    enum State {
        CLOSED,
        OPEN,
        HALF_OPEN
    }

    struct CircuitConfig {
        uint256 failureThreshold;
        uint256 timeout;
        uint256 successThreshold;
    }

    struct CircuitState {
        State state;
        uint256 failureCount;
        uint256 successCount;
        uint256 lastFailureTime;
        uint256 nextAttemptTime;
    }

    mapping(bytes32 => CircuitState) public circuits;
    mapping(bytes32 => CircuitConfig) public circuitConfigs;

    event CircuitOpened(bytes32 indexed circuitId);
    event CircuitClosed(bytes32 indexed circuitId);
    event CircuitHalfOpened(bytes32 indexed circuitId);

    function createCircuit(
        bytes32 circuitId,
        uint256 failureThreshold,
        uint256 timeout,
        uint256 successThreshold
    ) external {
        circuitConfigs[circuitId] = CircuitConfig({
            failureThreshold: failureThreshold,
            timeout: timeout,
            successThreshold: successThreshold
        });

        circuits[circuitId] = CircuitState({
            state: State.CLOSED,
            failureCount: 0,
            successCount: 0,
            lastFailureTime: 0,
            nextAttemptTime: 0
        });
    }

    function recordSuccess(bytes32 circuitId) external {
        CircuitState storage circuit = circuits[circuitId];
        CircuitConfig memory config = circuitConfigs[circuitId];

        circuit.successCount++;
        circuit.failureCount = 0;

        if (circuit.state == State.HALF_OPEN && circuit.successCount >= config.successThreshold) {
            circuit.state = State.CLOSED;
            circuit.successCount = 0;
            emit CircuitClosed(circuitId);
        }
    }

    function recordFailure(bytes32 circuitId) external {
        CircuitState storage circuit = circuits[circuitId];
        CircuitConfig memory config = circuitConfigs[circuitId];

        circuit.failureCount++;
        circuit.lastFailureTime = block.timestamp;

        if (circuit.state == State.CLOSED && circuit.failureCount >= config.failureThreshold) {
            circuit.state = State.OPEN;
            circuit.nextAttemptTime = block.timestamp + config.timeout;
            emit CircuitOpened(circuitId);
        } else if (circuit.state == State.HALF_OPEN) {
            circuit.state = State.OPEN;
            circuit.nextAttemptTime = block.timestamp + config.timeout;
            circuit.successCount = 0;
            emit CircuitOpened(circuitId);
        }
    }

    function canExecute(bytes32 circuitId) external returns (bool) {
        CircuitState storage circuit = circuits[circuitId];

        if (circuit.state == State.CLOSED) {
            return true;
        } else if (circuit.state == State.OPEN) {
            if (block.timestamp >= circuit.nextAttemptTime) {
                circuit.state = State.HALF_OPEN;
                circuit.successCount = 0;
                emit CircuitHalfOpened(circuitId);
                return true;
            }
            return false;
        } else { // HALF_OPEN
            return true;
        }
    }

    function getCircuitState(bytes32 circuitId) external view returns (State) {
        return circuits[circuitId].state;
    }
}
