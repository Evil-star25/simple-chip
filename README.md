
## 📦 Modules Overview

### ✅ USART (Universal Synchronous/Asynchronous Receiver/Transmitter)
- **Description**: Handles serial communication for transmitting and receiving 8-bit data.
- **Files**: `usart.v`, `usart_tb.v`
- **Interface**: Configurable TX and RX paths, supports integration with FIFO.

### ✅ FIFO (Synchronous)
- **Description**: A basic synchronous FIFO buffer to decouple input and output data rates.
- **Features**: Simultaneous read/write, status signals (`full`, `empty`).
- **Files**: `fifo.v`, `fifo_tb.v`

### ✅ PWM (Pulse Width Modulation)
- **Description**: Generates a modulated pulse signal with configurable duty cycle.
- **Testbench**: Implemented in Python using a simulation framework such as cocotb.
- **Files**: `pwm.v`, `pwm_tb.py`

### ✅ Shift Registers
- **Serial to Parallel**: Converts incoming serial bits into a parallel byte.
- **Parallel to Serial**: Converts parallel byte data into a serial stream.
- **Files**: `serial_to_parallel.v`, `parallel_to_serial.v`, `shift_register_tb.v`

## 🧪 Testbenches

Each module includes a corresponding testbench:

- **Verilog Testbenches**: For `usart`, `fifo`, and `shift_register` modules.
- **Python Testbench**: For `pwm`, using `cocotb` or similar HDL simulation environment.

### ▶️ Example: Running a Verilog Testbench

```bash
# Example using Icarus Verilog
cd fifo/
iverilog -o fifo_tb fifo.v fifo_tb.v
vvp fifo_tb

author:

cedric kouega

