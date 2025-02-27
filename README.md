# Snoopy Cache Coherence Protocol Implementation

## Overview
This project implements a Snoopy Cache Coherence Protocol between two cache memories using VHDL. The implementation resolves the cache coherence problem in multiprocessor systems by ensuring data integrity and optimizing access speeds.

## Problem Statement
In multiprocessor systems, when shared data is cached in different processors, maintaining data consistency becomes challenging. The Snoopy protocol addresses this by monitoring a common bus and invalidating or updating cache blocks when necessary.

## Solution
The implemented solution uses a write-invalidate protocol with MSI (Modified, Shared, Invalid) states to maintain cache coherence. When a processor writes to a shared memory location, it invalidates copies in other caches, ensuring exclusive access during write operations.

## Key Components
- **Processor Core**: Calculates address, data, and desired operation
- **Cache DataPath**: Implements basic cache functionality with write-back support
- **Cache Controller**: Uses a finite state machine to manage cache operations
- **Bus Architecture**: Allows caches to "snoop" on memory transactions
- **RAM Memory**: Main memory for data storage
- **RAM Memory Controller**: Ensures serialized data access

## Implementation
The project is implemented in VHDL with the following state transitions:
- **Shared**: Block contains an unmodified copy from main memory
- **Modified/Exclusive**: Block has been modified by the processor
- **Invalid**: Block is ignored (occurs when another processor modifies shared data)

## Author
Rotaru Cristian, Technical University of Cluj-Napoca (2024)
