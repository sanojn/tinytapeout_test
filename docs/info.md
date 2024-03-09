<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Press buttons to roll various types of TTRPG dice

## How to test

Press one of the buttons ui[6:0] and release.
A dice roll is shown on the LED display.

ui[0] rolls a d4.
ui[1] rolls a d6.
ui[2] rolls a d8.
ui[3] rolls a d10.
ui[4] rolls a d12.
ui[5] rolls a d20.
ui[6] rolls a d100.

## External hardware

Pullups on ui[6:0] with pushbuttons closing to GND.
A two-digit common-cathode LED display. Segment anodes are connected to uo[7:0] (A,B,C..,G,Dot in that order)
Left cathode connected to uio[1], right cathode to uio[0].

