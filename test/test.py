# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import RisingEdge
from cocotb.triggers import Trigger
from cocotb.triggers import Edge

def hex(n): # Return a binary octet with 2 BCD digits
  return ((n%100)//10)*16 + n%10;

def internalDigits(dut): # Return the two internal digit counters as an octet
  return dut.user_project.digit10.value*16 + dut.user_project.digit1.value

async def testCycle(dut,period):
    await ClockCycles(dut.clk, 1, False) # allow for synch delay
    # allow input to be deglitched
    if (dut.user_project.tick.value==0):
      await RisingEdge(dut.user_project.tick)
    await RisingEdge(dut.user_project.tick)
    await ClockCycles(dut.clk, 2, False) # Let the debounce FSM see the tick
    # Now the counter should be rolling
    # Wait until it's 1 to simplify tests
    if (internalDigits(dut)!=hex(1)):
      for i in range(0,period):
        await ClockCycles(dut.clk, 1, False)
        if (internalDigits(dut)==hex(1)):
          break;
    # Check one period
    for i in range(period,0,-1):
      await ClockCycles(dut.clk, 1, False)
      assert internalDigits(dut) == hex(i)
    # Check one more period
    for i in range(period,0,-1):
      await ClockCycles(dut.clk, 1, False)
      assert internalDigits(dut) == hex(i)
    # Multiple cycles
    await ClockCycles(dut.clk, 3*period, False)
    assert internalDigits(dut) == hex(1)
    # Run the last part only if we're actually pressing a button
    if (period!=1):
      # Release button and verify that counting stops
      dut.ui_in.value = 0;
      await ClockCycles(dut.clk,1,False) # Allow for synch delay
      assert internalDigits(dut) == hex(period) # Counter should have rolled over 
      await ClockCycles(dut.clk,1,False)
      assert internalDigits(dut) == hex(period-1) # The debouncer changes state as we roll down once more
      await ClockCycles(dut.clk,1,False)
      assert internalDigits(dut) == hex(period-1) # The counter should stopped now
      await RisingEdge(dut.user_project.tick)  # Wait a while so the debouncer knows the button is released
      assert internalDigits(dut) == hex(period-1) # Verify that the counter hasn't moved
      await ClockCycles(dut.clk, 7, False)
      assert internalDigits(dut) == hex(period-1) # Verify that the counter hasn't moved

# def sevenSegment_decode(display,activePhase):
# @cocotb.coroutine()
# def sevenSegmentCheck():
#      await Edge(uio_out[0])
#      await(Timer(1,units='us'))  // Allow outputs to settle

def noDigitsShown(): # Check that the 'common' signal of both displays are off
  return ( dut.digit1_active.value==0 & digit10_active.value==0 )

@cocotb.coroutine()
def digitsShownCheck(dut):
   while (dut.ui_in.value%128 != 0): # some button is pressed
     await Timer(1, units='ms');
     if (dut.ui_in.value%128 != 0): assert noDigitsShown();
   while (dut.ui_in.value%128 == 0): # no button is pressed
     await Timer(1, units='ms');
     if (dut.ui_in.value%128 == 0): assert !noDigitsShown();

@cocotb.test()
async def test_adder(dut):
  dut._log.info("Start testbench")
  
  clock = Clock(dut.clk, 30, units="us") # Approximation of 32768 Hz
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10, False)
  dut.rst_n.value = 1
  assert internalDigits(dut) == hex(1)

  digitsShown_task = cocotb.start(digitsShownCheck(dut))

  # Set the input values, wait one clock cycle, and check the output
  dut._log.info("Test")
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  
  dut._log.info("Testing no button")
  await testCycle(dut,1)
  dut._log.info("Testing btn4")
  dut.ui_in.value = 1 # press btn4
  await testCycle(dut,4)
  dut._log.info("Testing btn6")
  dut.ui_in.value = 2 # press btn6
  await testCycle(dut,6)
  dut._log.info("Testing btn8")
  dut.ui_in.value = 4 # press btn8
  await testCycle(dut,8)
  dut._log.info("Testing btn10")
  dut.ui_in.value = 8 # press btn10
  await testCycle(dut,10)
  dut._log.info("Testing btn12")
  dut.ui_in.value = 16 # press btn12
  await testCycle(dut,12)
  dut._log.info("Testing btn20")
  dut.ui_in.value = 32 # press btn20
  await testCycle(dut,20)
  dut._log.info("Testing btn100")
  dut.ui_in.value = 64 # press btn100
  await testCycle(dut,100)
  
  dut._log.info("End testbench")
