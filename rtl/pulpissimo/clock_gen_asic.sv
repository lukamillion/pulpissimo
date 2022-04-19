//-----------------------------------------------------------------------------
// Title         : Wrapper of ETH custom FLL IP models
//-----------------------------------------------------------------------------
// File          : clock_gen_asic.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 19.04.2022
//-----------------------------------------------------------------------------
// Description :
//
// This module wraps the behavioral FLL models for the technology specific FLLs
// used for ETH/Unibo ASIC tapeouts. If you want to port PULPissimo to a
// different, please provide your own implementation of this module. You can use
// the config `register_interface` to connect to internal register files that
// controll your clock generation IP. In that case,  you will have to modify the
// pulp-runtime/SDK to use your custom FLL configuration interface (i.e. you
// need to provide a driver on how to talk to your PLL/FLL). Vanila
// pulp-runtime/SDK is developed to communicate with this behavioral model.
//
//-----------------------------------------------------------------------------
// Copyright (C) 2022 ETH Zurich, University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
// SPDX-License-Identifier: SHL-0.51
//-----------------------------------------------------------------------------


module clock_gen #(
  // This particular version of clock_gen requires a `register_interface` config port
  parameter type cfg_bus_req_t = logic,
  parameter type cfg_bus_resp_t = logic
)(
  // Reference clock for internal clock generation. The frequency of this clock
  // is platform dependent (ASIC/RTL sim -> 32kHz)
  input logic  ref_clk_i,
  // If asserted all output clocks shall be directly connected to `ref_clk_i`
  input logic  clk_byp_en_i,
  // Asynchronous active-low reset. Shall reset all clock generation config.
  input logic  rst_ni,
  // Configuration interface for clock generation
  input        cfg_bus_req_t cfg_req_i,
  output       cfg_bus_resp_t cfg_resp_o,
  // Output clocks
  output logic slow_clk_o, // 32 kHz clock
  output logic soc_clk_o, // Clock that drives SoC domain (should be as fast or
                          // faster than per_clk_o)
  output logic per_clk_o // Clock that drives IO buffers within IO peripherals
);


  gf22_FLL i_fll_soc (
    .FLLCLK ( s_clk_fll_soc            ),
    .FLLOE  ( 1'b1                     ),
    .REFCLK ( ref_clk_i                ),
    .LOCK   ( soc_fll_slave_lock_o     ),
    .CFGREQ ( soc_fll_slave_req_i      ),
    .CFGACK ( soc_fll_slave_ack_o      ),
    .CFGAD  ( soc_fll_slave_add_i[1:0] ),
    .CFGD   ( soc_fll_slave_data_i     ),
    .CFGQ   ( soc_fll_slave_r_data_o   ),
    .CFGWEB ( soc_fll_slave_wrn_i      ),
    .RSTB   ( rstn_glob_i              ),
    .PWD    ( 1'b0                     ),
    .RET    ( 1'b0                     ),
    .TM     ( test_mode_i              ),
    .TE     ( shift_enable_i           ),
    .TD     ( 1'b0                     ),
    .TQ     (                          ),
    .JTD    ( 1'b0                     ),
    .JTQ    (                          )
        );

endmodule
