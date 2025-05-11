# class-based-testbench-for-4-bit-bidirectional-counter-verification-
class based testbench for 4 bit bidirectional counter verification 

SystemVerilog Testbench for 4-Bit Bidirectional Counter
Overview
This repository contains a SystemVerilog testbench for verifying a 4-bit bidirectional counter. The counter increments or decrements based on a mode signal and includes a reset feature. The testbench uses a class-based structure for modularity and reusability.
Design Under Test (DUT)
The DUT is a 4-bit counter with:

Inputs:
clk: Clock signal
reset: Synchronous reset (active high)
mod: Mode signal (1 = increment, 0 = decrement)


Output:
count: 4-bit counter value


Behavior:
On a clock edge, if reset is high, count resets to 0000.
If reset is low, count increments (if mod = 1) or decrements (if mod = 0).
Wraps around at 1111 (increment) or 0000 (decrement).



Testbench Structure
The testbench is organized into classes for clarity:
1. Counter Item

Represents a transaction with reset, mod, and count.
Uses constrained randomization for input patterns.
Includes a print method for logging.

2. Interface

Connects the testbench to the DUT.
Uses modports for driver and monitor signal access.

3. Generator

Creates test scenarios:
Scenario 1: Reset test.
Scenario 2: 20 cycles of incrementing.
Scenario 3: 20 cycles of decrementing.
Scenario 4: 20 cycles with random mod.


Sends transactions to the driver via a mailbox.

4. Driver

Drives reset and mod to the DUT based on transactions.
Synchronizes with the clock and signals completion.

5. Monitor

Samples DUT inputs and outputs each clock cycle.
Sends data to the scoreboard.

6. Scoreboard

Verifies DUT output against expected behavior.
Checks transitions and wrap-around cases.
Tracks and reports total checks and errors.

7. Environment

Connects generator, driver, monitor, and scoreboard.
Manages mailboxes and events.

8. Test

Initializes the environment and starts the test.

9. Testbench Module

Top-level module with DUT, interface, and test.
Generates the clock and dumps waveforms.

Files
counter.sv: The counter design.
counter_tb.sv: Testbench with all classes and connections.
README.md: This file.

Requirements
SystemVerilog simulator (e.g., VCS, QuestaSim, Incisive).

Compile and Simulate (example with VCS):
vcs -sverilog -timescale=1ns/1ns counter.sv counter_tb.sv
./simv


View Waveforms:
Waveforms are saved in wave.shm. Use your simulator’s viewer to analyze signals.



Output
Transaction logs with time, component, and signal details.
Pass/fail messages for each test case.
Final scoreboard summary with total checks and errors.

Features
Modular design for easy updates.
Comprehensive testing of reset, increment, decrement, and random cases.
Constrained randomization for realistic inputs.
Detailed error reporting.
Waveform support for debugging.

Potential Improvements
Add functional coverage analysis.
Adopt UVM for standardization.
Support configurable counter bit-width.

License
GNU License. See the LICENSE file for details.
Contributing
Contributions are welcome. Submit a pull request or open an issue for suggestions or bugs.
Contact
For questions, email gowdashashank414@gmail.com or open an issue.
