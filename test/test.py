# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

def hex(n): # Return binary integer equivalent of 2 BCD digits
  return (n//10)*16 + n%10;

async def testCycle(dut,period):
    # Check one period
    for i in range(period,period,-1):
      await ClockCycles(dut.clk, 1)
      assert dut.uo_out.value == hex(i)
    # Check one more period
    for i in range(period,period,-1):
      await ClockCycles(dut.clk, 1)
      assert dut.uo_out.value == hex(i)
    # Multiple cycles
    await ClockCycles(dut.clk, 3*period)
    assert dut.uo_out.value == hex(1)

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
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  assert dut.uo_out.value == hex(1)

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
  dut.ui_in.value = 32 # press btn100
  await testCycle(dut,100)
  
  dut._log.info("End testbench")
