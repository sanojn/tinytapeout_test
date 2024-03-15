<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

### Press buttons to roll various types of TTRPG dice

Playing table top role playing games (TTRPGs) often involves rolling dice of various types.
This design is a combination of the most common types of dice used.

It has six button inputs, each corresponding to a certain type of die, and a two-digit seven segment display that shows the result of the roll when the button is released.

While a button is pressed, a counter is decremented every clock cycle. When the counter reaches 1, it is reloaded with the largest value of the corresponding die. When the button is released, the counter stops and the result is displayed on the seven segment display.

The design outputs seven segment signals and 'common' drivers for two digits, in order to be able to show dual digit results for the larger dice. It has configuration pinss that set the active level of segment and common signals independently of each other, to allow the connection of either common-cathode or common-anode diplays, or displays with inverting or non-inverting drive buffers for segments and/or common signals. Similarly, the button inputs can be configured as active low or high.

Dice up to d10 can use a single seven segment display without a common driver like the one on the evaluation board. If such a display is used, it will toggle between showing the 1s digit and the blanked 10s digit. When the result is 10, it will show a 1 and 0 superimposed, which will look like a slightly wonky 0.

### IOs

| No.    | Input  | Output | Bidir IO                      |
|--------|--------|--------|-------------------------------|
| 0      | Btn4   | Seg A  | 1s digit common (output)      |
| 1      | Btn6   | Seg B  | 10s digit common (output)     |
| 2      | Btn8   | Seg C  | Not used                      |
| 3      | Btn10  | Seg D  | Not used                      |
| 4      | Btn12  | Seg E  | Not used                      |
| 5      | Btn20  | Seg F  | Button polarity  cfg (input)  |
| 6      | Btn100 | Seg G  | Segment polarity cfg (input)  |
| 7      | -      | Seg DP | 'Common' polarity cfg (input) |

Though it should work at any reasonable frequency, it uses clock timing to debounce the buttons and is optimized to run at 32768 Hz. At much higher frequencies, the button debouncer will be unreliable and display muxing may not work properly. At much lower frequencies, the higher valued dice will have a low cycle rate and could be possible to cheat by well-timed key presses.

'Polarity' pins shold be set to the logic level that acts as the active level for the corresponding I/O signals: 0 for an active low and 1 for active high. For instance: uio[7]=0 causes the digit select signals to be active low, suitable for directly driving common cathode pins. When uio[6]=1, lit segments are high, suitable for direct segment drive of common cathode displays. Similarly, when  uio[5]=0 button inputs are expected to be high when idle and low when pressed.

## How to test

Set clock frequency to 32768 Hz.
Configure uio[7:5] for the appropriate signal polarity:

| Seven segment                                       | uio[7:6] |
| ----------------------------------------------------| -------- |
| Common cathode, direct segment drive ( eval board)  | 01       |
| Common anode, direct segment drive                  | 10       |
| Inverting common anode drive, direct segment drive  | 00       |

For the eval board, set uio[7:5] to 010

Press one of the buttons ui[6:0] (according to the selected button polarity) and release it.
The dice roll is shown on the LED display.

* ui[0] rolls a d4 (four sided die).
* ui[1] rolls a d6
* ui[2] rolls a d8
* ui[3] rolls a d10
* ui[4] rolls a d12
* ui[5] rolls a d20
* ui[6] rolls a d100

## External hardware

Pullups on ui[6:0] with pushbuttons closing to GND.

A two-digit LED display. Common anode and/or cathode are supported using the configuraiton pins.
Segments are connected to uo[7:0] (DP, G, F, E, D, C, B, A in that order)
Left cathode connected to uio[1]
Right cathode to uio[0]

Static configuration inputs on uio[7:5] should be connected to VDD or GND.

The chip may struggle to supply common anode displays with enough current.
If so, drive the common anode pin with an inverting transistor driver and
change the active level of the 'common' output by setting uio[7] to 0.
