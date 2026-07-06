///////////////////////////////////////////////////////////////////////////////////
// SYSTOLIC ARRAY TO AXI ADAPTER
// DMA read from the address range and then write the results to the DRAM.
// Similar structure to the axi_spad_write_adapter, this is a read adapter
// Connect to top_wrapper (for the systolic array)
// o_or_rd_en => i_or_read_en
// o_or_rd_addr => i_or_addr
// i_or_rd_data <= o_or_data_out        (32-bit SPAD word)
// i_or_rd_valid <= o_or_data_out_valid
//
// top_wrapper output SPAD is 32-bit wide; this adapter presents it as
// 32-bit AXI beats.
// Each SPAD word = 1 AXI beat. DMA LEN does not need to be even anymore.
//
// Plan is to have the CPU poll the STATUS register (0x34) of the systolic_csr
// if i_done == 1, then configure the DMA Channel:
//      SRC=OUTPUT_SPAD_BASE,
//      DST=DDR_ADDR
//      LEN=output_bytes
// Write DMA CTRL[0]= 1 to start the transfer
// Then poll the DMA status until DONE
//
///////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module axi_output_read_adapter #(
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 32,
    parameter BUF_ADDR_WIDTH = 16     // matches i_or_addr, check top_wrapper and csr map for consistency
)(
    input  wire clk,
    input  wire nrst,

    // --- AXI4 Slave read address channel ---
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [7:0]                s_axi_arlen,
    input  wire [2:0]                s_axi_arsize,
    input  wire [1:0]                s_axi_arburst,
    input  wire [2:0]                s_axi_arprot,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,

    // --- AXI4 Slave read data channel ---
    output reg  [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rlast,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready,

    // --- AXI4 Slave write address channel (not supported, tied off) ---
    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [7:0]                s_axi_awlen,
    input  wire [2:0]                s_axi_awsize,
    input  wire [1:0]                s_axi_awburst,
    input  wire [2:0]                s_axi_awprot,
    input  wire                      s_axi_awvalid,
    output wire                      s_axi_awready,

    // --- AXI4 Slave write data channel (not supported, tied off) ---
    input  wire [AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                        s_axi_wlast,
    input  wire                        s_axi_wvalid,
    output wire                        s_axi_wready,

    // --- AXI4 Slave write response channel (not supported, tied off) ---
    output wire [1:0]                s_axi_bresp,
    output wire                      s_axi_bvalid,
    input  wire                      s_axi_bready,

    // --- Output SPAD read port (to top_wrapper) ---
    // SPAD words are 32-bit; each read returns one 32-bit word as one AXI beat
    output reg  [BUF_ADDR_WIDTH-1:0] o_or_rd_addr,
    output reg                       o_or_rd_en,
    input  wire [31:0]               i_or_rd_data,    // 32-bit from o_or_data_out
    input  wire                      i_or_rd_valid    // asserts when data is ready after rd_en
);

    // Write channels: not supported
    assign s_axi_awready = 1'b0;
    assign s_axi_wready  = 1'b0;
    assign s_axi_bresp   = 2'b10;   // SLVERR
    assign s_axi_bvalid  = 1'b0;

    localparam BPW = AXI_DATA_WIDTH / 8;  // bytes per 32-bit word = 4

    // 3-state read FSM
    // Each 32-bit SPAD word is served as one 32-bit AXI beat.
    localparam RD_IDLE = 2'd0,
               RD_WAIT = 2'd1,   // waiting for SPAD valid after rd_en pulse
               RD_BEAT = 2'd2;   // presenting bits [31:0], waiting for rready

    reg [1:0]                rd_state;
    reg [7:0]                rd_beats_left;          // AXI beats remaining after current beat
    reg [BUF_ADDR_WIDTH-1:0] rd_word_addr;           // current SPAD word address
    reg [31:0]               rd_data_buf;            // latched 32-bit SPAD word

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rlast   <= 1'b0;
            s_axi_rdata   <= {AXI_DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;

            o_or_rd_addr  <= {BUF_ADDR_WIDTH{1'b0}};
            o_or_rd_en    <= 1'b0;

            rd_state      <= RD_IDLE;
            rd_beats_left <= 8'd0;
            rd_word_addr  <= {BUF_ADDR_WIDTH{1'b0}};
            rd_data_buf   <= 32'd0;
        end else begin
            o_or_rd_en <= 1'b0;  // default: de-asserted; pulsed for one cycle per SPAD read

            case (rd_state)

                RD_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid  <= 1'b0;
                    s_axi_rlast   <= 1'b0;

                    if (s_axi_arvalid && s_axi_arready) begin
                        s_axi_arready <= 1'b0;

                        // AXI byte address → SPAD word address
                        // For 32-bit AXI, strip 2 byte-lane bits.
                        rd_word_addr  <= s_axi_araddr[
                            BUF_ADDR_WIDTH + $clog2(BPW) - 1 : $clog2(BPW)
                        ];

                        // arlen = total_beats - 1
                        // Example:
                        //   arlen = 0 means 1 beat total
                        //   arlen = 3 means 4 beats total
                        // Here rd_beats_left means "extra beats after current beat".
                        rd_beats_left <= s_axi_arlen;

                        o_or_rd_addr  <= s_axi_araddr[
                            BUF_ADDR_WIDTH + $clog2(BPW) - 1 : $clog2(BPW)
                        ];
                        o_or_rd_en    <= 1'b1;

                        rd_state      <= RD_WAIT;
                    end
                end

                RD_WAIT: begin
                    // Wait for top_wrapper's output SPAD to return 32-bit valid data.
                    if (i_or_rd_valid) begin
                        rd_data_buf  <= i_or_rd_data;
                        s_axi_rdata  <= i_or_rd_data;
                        s_axi_rresp  <= 2'b00;

                        // rlast is set here only if this is the final beat.
                        // Since each SPAD word is one AXI beat, arlen=0 means
                        // this first returned word is also the last word.
                        s_axi_rlast  <= (rd_beats_left == 8'd0);
                        s_axi_rvalid <= 1'b1;

                        rd_state     <= RD_BEAT;
                    end
                end

                RD_BEAT: begin
                    // Presenting one 32-bit SPAD word; hold until master accepts
                    if (s_axi_rvalid && s_axi_rready) begin
                        if (s_axi_rlast) begin
                            // Burst complete
                            s_axi_rvalid <= 1'b0;
                            s_axi_rlast  <= 1'b0;
                            rd_state     <= RD_IDLE;
                        end else begin
                            // Fetch next SPAD word for the next AXI beat
                            rd_beats_left <= rd_beats_left - 8'd1;
                            rd_word_addr  <= rd_word_addr + 1'b1;

                            o_or_rd_addr  <= rd_word_addr + 1'b1;
                            o_or_rd_en    <= 1'b1;

                            s_axi_rvalid  <= 1'b0;
                            s_axi_rlast   <= 1'b0;

                            rd_state      <= RD_WAIT;
                        end
                    end
                end

                default: begin
                    rd_state <= RD_IDLE;
                end

            endcase
        end
    end

endmodule