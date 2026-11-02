# UART FIFO Design and Formal Verification

This activity is part of **DigitalSeed**, a training initiative developed within the **OnChip Research Group**. It focuses on applying formal verification techniques to digital hardware using SystemVerilog and open-source verification tools.

The main objective is to design and formally verify the FIFO (First-In, First-Out) architectures used in a UART (Universal Asynchronous Receiver/Transmitter) communication system.

The designs are based on the UART architecture described in the *KeyStone Architecture Universal Asynchronous Receiver/Transmitter (UART)* documentation by Texas Instruments.

The project covers two main components: the **Receiver FIFO**, responsible for buffering incoming data and its associated error information, and the **Transmitter FIFO**, responsible for buffering outgoing data before it is transferred to the transmitter shift register.

The initial implementations are described in Verilog and will serve as the starting point for the verification process. The designs will be progressively adapted to SystemVerilog to incorporate formal properties, assertions, and verification mechanisms capable of checking their functional behavior and operating constraints.

## Receiver FIFO Architecture

The Receiver FIFO temporarily stores incoming UART data and its associated error information until the receiving system retrieves it.

### Input Signals

| Signal | Width | Description |
|---|---:|---|
| `clk` | 1 bit | System clock. |
| `rst` | 1 bit | Reset signal. |
| `din` | 8 bits | Input data to be stored in the FIFO. |
| `err_in` | 3 bits | Error information associated with the incoming data. |
| `push` | 1 bit | Write request to insert data into the FIFO. |
| `pop` | 1 bit | Read request to retrieve data from the FIFO. |
| `fifo_en` | 1 bit | FIFO enable control. |
| `clr` | 1 bit | FIFO clear control. |
| `rxfifotl` | 2 bits | Receive FIFO trigger-level configuration. |

### Output Signals

| Signal | Width | Description |
|---|---:|---|
| `dout` | 8 bits | Data available at the FIFO output. |
| `err_top` | 3 bits | Error information associated with the data at the FIFO output. |
| `empty` | 1 bit | Indicates that the FIFO contains no valid entries. |
| `full` | 1 bit | Indicates that the FIFO has reached its storage capacity. |
| `count` | 5 bits | Number of entries currently stored in the FIFO. |
| `trig_reached` | 1 bit | Indicates that the configured receive FIFO trigger level has been reached. |
| `any_err` | 1 bit | Indicates the presence of error information in the FIFO. |

## Transmitter FIFO Architecture

The Transmitter FIFO temporarily stores outgoing UART data before it is retrieved by the transmitter logic and transferred to the transmit shift register for serial transmission.

Unlike the Receiver FIFO, this architecture does not require additional error information associated with each stored data entry.

### Input Signals

| Signal | Width | Description |
|---|---:|---|
| `clk` | 1 bit | System clock. |
| `rst` | 1 bit | Reset signal. |
| `din` | 8 bits | Input data to be stored in the FIFO. |
| `push` | 1 bit | Write request to insert data into the FIFO. |
| `pop` | 1 bit | Read request to retrieve data from the FIFO. |
| `fifo_en` | 1 bit | FIFO enable control. |

### Output Signals

| Signal | Width | Description |
|---|---:|---|
| `dout` | 8 bits | Data available at the FIFO output. |
| `empty` | 1 bit | Indicates that the FIFO contains no valid entries. |
| `full` | 1 bit | Indicates that the FIFO has reached its storage capacity. |
| `count` | 5 bits | Number of entries currently stored in the FIFO. |

## Directory Structure

```text
4_activity/
│
├── ReceiverFIFO/
│   ├── Contador.v
│   ├── FFD.v
│   ├── ReceiverFIFO.v
│   └── RAM.v
│
├── TransmitterFIFO/
│   ├── Contador.v
│   ├── FFD.v
│   ├── TransmitterFIFO.v
│   └── RAM.v
│
└── README.md
```

## Directory Description

- **`ReceiverFIFO/`** — Contains the Verilog implementation of the UART Receiver FIFO and its internal hardware components, including the counter, D-type flip-flops, and memory structure. This design serves as the initial target for the formal verification process.

- **`TransmitterFIFO/`** — Contains the Verilog implementation of the UART Transmitter FIFO and its internal hardware components. This design will also undergo formal verification to validate its data buffering and control behavior.

## Formal Verification Roadmap

The project follows two main verification stages:

### Stage 1: Receiver FIFO Verification

The first stage focuses on reviewing the existing Receiver FIFO architecture, adapting the RTL implementation to SystemVerilog, and developing the formal verification environment.

The verification process will focus on the following properties:

- Correct FIFO data ordering (First-In, First-Out behavior).
- Data integrity during write and read operations.
- Correct behavior under simultaneous push and pop operations.
- Proper handling of full and empty conditions.
- Correct occupancy counter behavior.
- Reset and clear functionality.
- Correct association between received data and its error information.
- Trigger-level detection and error-status signaling.

### Stage 2: Transmitter FIFO Verification

The second stage focuses on reviewing and adapting the Transmitter FIFO implementation to SystemVerilog, followed by the development of its formal verification environment.

The verification process will focus on:

- Correct FIFO data ordering.
- Data integrity during write and read operations.
- Correct behavior under simultaneous push and pop operations.
- Proper handling of full and empty conditions.
- Correct occupancy counter behavior.
- Reset functionality.
- Prevention of invalid read and write operations.

## Implementation Status

**Status: Under development.**

Both Receiver and Transmitter FIFO RTL implementations are available in Verilog and serve as the starting point for the formal verification activities.

The next step is to review the existing architectures, adapt the designs to SystemVerilog, and define the formal properties required to validate their functional behavior and operating constraints.

The verification process will initially focus on the Receiver FIFO. Once its properties have been implemented and validated, the same methodology will be extended to the Transmitter FIFO.

The final objective is to obtain formally verified FIFO implementations for both the reception and transmission paths of the UART communication system.