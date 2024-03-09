# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

def hex(n): # Return integer equivalent of 2 BCD digits
  return (n/10)*16 + n%10;

async def testCycle(period):
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
  
  clock = Clock(dut.clk, 1000000/32768, units="us")
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1

  # Set the input values, wait one clock cycle, and check the output
  dut._log.info("Test")
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  
  await testCycle(1)
  dut.u_in.value = 1 # press btn4
  await testCycle(4)
  dut.u_in.value = 2 # press btn6
  await testCycle(6)
  dut.u_in.value = 4 # press btn8
  await testCycle(8)
  dut.u_in.value = 8 # press btn10
  await testCycle(10)
  dut.u_in.value = 16 # press btn12
  await testCycle(12)
  dut.u_in.value = 32 # press btn20
  await testCycle(20)
  dut.u_in.value = 32 # press btn100
  await testCycle(100)
  
  dut._log.info("End testbench")
