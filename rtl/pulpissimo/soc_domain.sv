//-----------------------------------------------------------------------------
// Title         : soc_domain
//-----------------------------------------------------------------------------
// File          : soc_domain.sv
// Author        : Manuel Eggimann  <meggimann@iis.ee.ethz.ch>
// Created       : 19.04.2022
//-----------------------------------------------------------------------------
// Description :
//
// PULP SoC Wrapper for PULPissimo. Since `pulp_soc` is shared between the
// single-core SoC variant PULPissimo and the multi-core pulp-open we need a
// pulpissimo specific wrapper that ties of uneccesarry signals and exposes only
// the signals required for pulpissimo.
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

`include "pulp_soc_defines.sv"

module soc_domain #(
    parameter CORE_TYPE            = 0,
    parameter USE_FPU              = 1,
    parameter USE_ZFINX            = 1,
    parameter USE_HWPE             = 1,
    parameter SIM_STDOUT           = 1,
    localparam NGPIO = gpio_reg_pkg::GPIOCount // Have a look at the README in
                                               // the GPIO repo in order to
                                               // change the number of GPIOs.
)(
    // Clock and reset signals
    input logic                 slow_clk_i,
    input logic                 slow_clk_rst_ni,
    input logic                 soc_clk_i,
    input logic                 soc_rst_ni,
    input logic                 per_clk_i,
    input logic                 per_rst_ni,

    // DFT signals
    input logic                 dft_test_mode_i,
    input logic                 dft_cg_enable_i,
    // Boot mode selection (check bootcode repo for documentation what bootmodes
    // are available and how they are mapped)
    input logic [1:0]           bootsel_i,

    // Timer PWM output signals (4 channels per timer)
    output logic [3:0]          timer_ch0_o,
    output logic [3:0]          timer_ch1_o,
    output logic [3:0]          timer_ch2_o,
    output logic [3:0]          timer_ch3_o,

    // GPIO
    input logic [NGPIO-1:0]     gpio_i,
    output logic [NGPIO-1:0]    gpio_o,
    output logic [NGPIO-1:0]    gpio_tx_en_o,

    // uDMA Peripherals
    // UART
    output                      uart_pkg::uart_to_pad_t [udma_cfg_pkg::N_UART-1:0] uart_to_pad_o,
    input                       uart_pkg::pad_to_uart_t [udma_cfg_pkg::N_UART-1:0] pad_to_uart_i,
    // I2C
    output                      i2c_pkg::i2c_to_pad_t [udma_cfg_pkg::N_I2C-1:0] i2c_to_pad_o,
    input                       i2c_pkg::pad_to_i2c_t [udma_cfg_pkg::N_I2C-1:0] pad_to_i2c_i,
    // SDIO
    output                      sdio_pkg::sdio_to_pad_t [udma_cfg_pkg::N_SDIO-1:0] sdio_to_pad_o,
    input                       sdio_pkg::pad_to_sdio_t [udma_cfg_pkg::N_SDIO-1:0] pad_to_sdio_i,
    // I2S
    output                      i2s_pkg::i2s_to_pad_t [udma_cfg_pkg::N_I2S-1:0] i2s_to_pad_o,
    input                       i2s_pkg::pad_to_i2s_t [udma_cfg_pkg::N_I2S-1:0] pad_to_i2s_i,
    // QSPI
    output                      qspi_pkg::qspi_to_pad_t [udma_cfg_pkg::N_QSPIM-1:0] qspi_to_pad_o,
    input                       qspi_pkg::pad_to_qspi_t [udma_cfg_pkg::N_QSPIM-1:0] pad_to_qspi_i,
    // CPI
    input                       cpi_pkg::pad_to_cpi_t [udma_cfg_pkg::N_CPI-1:0] pad_to_cpi_i,
    // HYPER
    output                      hyper_pkg::hyper_to_pad_t [udma_cfg_pkg::N_HYPER-1:0] hyper_to_pad_o,
    input                       hyper_pkg::pad_to_hyper_t [udma_cfg_pkg::N_HYPER-1:0] pad_to_hyper_i,
    // fll bypass bit in legacy pulp JTAG TAP. Can be used to control FLL
    // bypassing via JTAG instead of dedicated pad
    output logic                jtag_tap_bypass_fll_clk_o,
    // APB port to control various aspects of PULPissimo which are platform
    // dependent (e.g. pad multiplexer, clock generation etc.). Check
    // soc_mem_map.svh for the global address space region which is mapped to
    // this port.
    APB.Master                  apb_chip_ctrl_master,

    // JTAG signals (connets to risc-v debug unit legacy pulp debug TAP)
    input logic                 jtag_tck_i,
    input logic                 jtag_trst_ni,
    input logic                 jtag_tms_i,
    input logic                 jtag_tdi_i,
    output logic                jtag_tdo_o,
);

    pulp_soc #(
      .CORE_TYPE           ( CORE_TYPE           ),
      .USE_FPU             ( USE_FPU             ),
      .USE_HWPE            ( USE_HWPE            ),
      .USE_CLUSTER_EVENT   ( USE_CLUSTER_EVENT   ),
      .SIM_STDOUT          ( SIM_STDOUT          ),
      .AXI_ADDR_WIDTH      ( AXI_ADDR_WIDTH      ),
      .AXI_DATA_IN_WIDTH   ( AXI_DATA_IN_WIDTH   ),
      .AXI_DATA_OUT_WIDTH  ( AXI_DATA_OUT_WIDTH  ),
      .AXI_ID_IN_WIDTH     ( AXI_ID_IN_WIDTH     ),
      .AXI_USER_WIDTH      ( AXI_USER_WIDTH      ),
      .AXI_STRB_WIDTH_IN   ( AXI_STRB_WIDTH_IN   ),
      .AXI_STRB_WIDTH_OUT  ( AXI_STRB_WIDTH_OUT  ),
      .CDC_FIFOS_LOG_DEPTH ( CDC_FIFOS_LOG_DEPTH ),
      .EVNT_WIDTH          ( EVNT_WIDTH          ),
      .NB_CORES            ( NB_CL_CORES         ),
      .USE_ZFINX           ( USE_ZFINX           )
    ) pulp_soc_i (
      .slow_clk_i,
      .slow_clk_rst_ni,
      .soc_clk_i,
      .soc_rst_ni,
      .per_clk_i,
      .per_rst_ni,
      .dft_test_mode_i,
      .dft_cg_enable_i,
      .boot_l2_i(1'b0),
      .bootsel_i,
      // Start booting from bootrom immediately
      // after reset
      .fc_fetch_en_valid_i(1'b1),
      .fc_fetch_en_i(1'b1),
      .cluster_rstn_req_o          (    ), // PULPissimo doesn't have a cluster
      .async_data_slave_aw_wptr_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_slave_aw_data_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_slave_aw_rptr_o  (    ), // PULPissimo doesn't have a cluster
      .async_data_slave_ar_wptr_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_slave_ar_data_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_slave_ar_rptr_o  (    ), // PULPissimo doesn't have a cluster
      .async_data_slave_w_wptr_i   ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_slave_w_data_i   ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_slave_w_rptr_o   (    ), // PULPissimo doesn't have a cluster
      .async_data_slave_r_wptr_o   (    ), // PULPissimo doesn't have a cluster
      .async_data_slave_r_data_o   (    ), // PULPissimo doesn't have a cluster
      .async_data_slave_r_rptr_i   ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_slave_b_wptr_o   (    ), // PULPissimo doesn't have a cluster
      .async_data_slave_b_data_o   (    ), // PULPissimo doesn't have a cluster
      .async_data_slave_b_rptr_i   ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_master_aw_wptr_o (    ), // PULPissimo doesn't have a cluster
      .async_data_master_aw_data_o (    ), // PULPissimo doesn't have a cluster
      .async_data_master_aw_rptr_i ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_master_ar_wptr_o (    ), // PULPissimo doesn't have a cluster
      .async_data_master_ar_data_o (    ), // PULPissimo doesn't have a cluster
      .async_data_master_ar_rptr_i ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_master_w_wptr_o  (    ), // PULPissimo doesn't have a cluster
      .async_data_master_w_data_o  (    ), // PULPissimo doesn't have a cluster
      .async_data_master_w_rptr_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_master_r_wptr_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_master_r_data_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_master_r_rptr_o  (    ), // PULPissimo doesn't have a cluster
      .async_data_master_b_wptr_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_master_b_data_i  ( '0 ), // PULPissimo doesn't have a cluster
      .async_data_master_b_rptr_o  (    ), // PULPissimo doesn't have a cluster
      .async_cluster_events_wptr_o (    ), // PULPissimo doesn't have a cluster
      .async_cluster_events_rptr_i ( '0 ), // PULPissimo doesn't have a cluster
      .async_cluster_events_data_o (    ), // PULPissimo doesn't have a cluster
      .cluster_busy_i              ( '0 ), // PULPissimo doesn't have a cluster
      .dma_pe_evt_ack_o            (    ), // PULPissimo doesn't have a cluster
      .dma_pe_evt_valid_i          ( '0 ), // PULPissimo doesn't have a cluster
      .dma_pe_irq_ack_o            (    ), // PULPissimo doesn't have a cluster
      .dma_pe_irq_valid_i          ( '0 ), // PULPissimo doesn't have a cluster
      .pf_evt_ack_o                (    ), // PULPissimo doesn't have a cluster
      .pf_evt_valid_i              ( '0 ), // PULPissimo doesn't have a cluster
      .timer_ch0_o,
      .timer_ch1_o,
      .timer_ch2_o,
      .timer_ch3_o,
      .uart_to_pad_o,
      .pad_to_uart_i,
      .i2c_to_pad_o,
      .pad_to_i2c_i,
      .sdio_to_pad_o,
      .pad_to_sdio_i,
      .i2s_to_pad_o,
      .pad_to_i2s_i,
      .qspi_to_pad_o,
      .pad_to_qspi_i,
      .pad_to_cpi_i,
      .hyper_to_pad_o,
      .pad_to_hyper_i,
      .gpio_i,
      .gpio_o,
      .gpio_tx_en_o,
      .jtag_tap_bypass_fll_clk_o,
      .apb_chip_ctrl_master_paddr_o   ( apb_chip_ctrl_master.paddr   ),
      .apb_chip_ctrl_master_pprot_o   ( apb_chip_ctrl_master.pprot   ),
      .apb_chip_ctrl_master_psel_o    ( apb_chip_ctrl_master.psel    ),
      .apb_chip_ctrl_master_penable_o ( apb_chip_ctrl_master.penable ),
      .apb_chip_ctrl_master_prdata_i  ( apb_chip_ctrl_master.prdata  ),
      .apb_chip_ctrl_master_pready_i  ( apb_chip_ctrl_master.pready  ),
      .apb_chip_ctrl_master_pslverr_i ( apb_chip_ctrl_master.pslverr ),
      .jtag_tck_i,
      .jtag_trst_ni,
      .jtag_tms_i,
      .jtag_tdi_i,
      .jtag_tdo_o,
      .cluster_dbg_irq_valid_o () // PULPissimo doesn't have a cluster
    );

endmodule
