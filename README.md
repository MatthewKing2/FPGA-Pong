# Pong on an FPGA

## Overview

This project implements a Pong inspired video game on an Lattice ICE40 HX1K FPGA using Verilog.

## Features

- **VGA Display:** Renders game elements at 640x480 resolution.
- **UART Input:** Allows for player control using a keyboard.
- **Block RAM:** Stores the RGB data for a cat face image to represent the Pong ball.
- **Game Engine:** Two paddles and a ball with movement, collision detection, and scoring behavior.

## How to Play

### Prerequisites

- **FPGA:** NANDLAND [The Go Board](https://nandland.com/the-go-board/).
- **Synthesizer:** [APIO](https://github.com/FPGAwars/apio) (free and open source).
- **Tools:** [Tera Term](https://teratermproject.github.io/index-en.html) (for UART communication with FPGA)

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/MatthewKing2/fpgaPong.git
   cd fpgaPong
   ```

2. **Synthesize the design:**

   ```bash
   apio build -v
   ```

3. **Upload to your FPGA:**

   ```bash
   apio upload
   ```

### Usage

1. **Connect the FPGA's UART input to a PC or other device.**
2. **Connect the FGPA's VGA output to a monitor.**
3. **Set up Terra Term to send keyboard input to the FPGA:**
   - Open the application.
   - Click Setup > Serial Port.
   - Select the correct COM port.
   - Make sure speed is set to 115200 (UART baud rate).
   - Select the window and type input into it.
4. **Play the game on your VGA display.**
   - Player 1 Controls: 'w' (up), 's' (down)
   - Player 2 Controls: 'i' (up), 'k' (down)

## Modules Description

- **vgaTopMod:** Top-level module that integrates all other modules and connects them to the VGA and UART interfaces.

- **vgaSyncPorches:** Handles the generation of VGA synchronization signals and pixel positions.

- **UartReceive:** Receives serial data via UART and converts it to parallel data for processing.

- **slowCLK:** Generates a slower clock for controlling game logic timing.

- **vagDottledLine:** Draws a dotted line down the center of the screen.

- **vgaRectangle:** Renders rectangular shapes on the VGA display, used for drawing paddles.

- **paddleBehavior:** Manages the position and movement of the paddles based on player input.

- **ballBehavior:** Controls the movement and collision logic of the ball.

### Ball Behavior FSM Implementation

The ball's behavior was the most complex element of the game logic. I chose to design a FSM implementation:

![BallBehaviorFSM](/BallBehaviorFSM.png)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Inspiration:** Classic Pong game.
- **Tutorials Used:** Nandland: [Nandland Go Board](https://www.youtube.com/playlist?list=PLnAoag7Ew-vr1M98Q5K2kLHxFQ5l0DU3B), DigiKey: [Introduction to FPGA](https://www.youtube.com/playlist?list=PLEBQazB0HUyT1WmMONxRZn9NmQ_9CIKhb)

## Contact

Please feel free to reach me at [matthewjesseking@gmail.com](matthewjesseking@gmail.com).

---
