//////////////////////////////////////////////////////////////////////////////////
// systolic_csr.v
// Hold all the configuration registers of the top.sv (systolic array)
// CPU writes config registers AFTER DMA finishes loading the SPADs.
//
// Register Map, Byte Addressable:
// 0x00 conv_mode  [0] (PW = 0, DW = 1)
// 0x04 p_mode     [1:0]
// 0x08 i_size
// 0x0C i_c_size
// 0x10 o_c_size
// 0x14 o_size
// 0x18 stride
// 0x1C depth_mult
// 0x20 i_start_addr
// 0x24 i_addr_end
// 0x28 w_start_addr
// 0x2C w_addr_end
// 0x30 CTRL       [0]=route_en/START, [1]=reg_clear
// 0x34 STATUS     [0]=done_latche
// 0x38 zero_point
// 0x3C input_offset
// 0x40 DDR_STATUS [0]=i_ddr_calib_done
// 0x44 pad_h
// 0x48 pad_w
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module systolic_csr #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 32
)(
    input wire clk,
    input wire nrst,

    // --- AXI4-Lite Slave ---
    input  wire [7:0]  s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output reg         s_axil_awready,

    input  wire [31:0] s_axil_wdata,
    input  wire        s_axil_wvalid,
    output reg         s_axil_wready,

    output reg  [1:0]  s_axil_bresp,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,

    input  wire [7:0]  s_axil_araddr,
    input  wire        s_axil_arvalid,
    output reg         s_axil_arready,

    output reg  [31:0] s_axil_rdata,
    output reg  [1:0]  s_axil_rresp,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready,

    // --- Status input from top.sv / accelerator ---
    input wire         i_done,

    // --- DDR/MIG calibration status ---
    // Connect this to MIG init_calib_complete.
    // If you do not want to use it yet, tie it to 1'b1 in the wrapper/BD.
    input wire         i_ddr_calib_done,

    // --- Config Outputs to top.sv ---
    output reg                    o_conv_mode,
    output reg  [1:0]             o_p_mode,

    output reg  [ADDR_WIDTH-1:0]  o_i_size,
    output reg  [ADDR_WIDTH-1:0]  o_i_c_size,
    output reg  [ADDR_WIDTH-1:0]  o_o_c_size,
    output reg  [ADDR_WIDTH-1:0]  o_o_size,

    output reg  [ADDR_WIDTH-1:0]  o_stride,
    output reg  [ADDR_WIDTH-1:0]  o_depth_mult,

    output reg  [ADDR_WIDTH-1:0]  o_i_start_addr,
    output reg  [ADDR_WIDTH-1:0]  o_i_addr_end,
    output reg  [ADDR_WIDTH-1:0]  o_w_start_addr,
    output reg  [ADDR_WIDTH-1:0]  o_w_addr_end,

    output reg                    o_route_en,
    output reg                    o_reg_clear,

    // --- Zero Points ---
    output reg  [DATA_WIDTH-1:0]   o_zero_point,
    output reg  [DATA_WIDTH-1:0]   o_input_offset,

    // --- Padding ---
    output reg  [DATA_WIDTH-1:0]   o_pad_h,
    output reg  [DATA_WIDTH-1:0]   o_pad_w
);

    // ================================================================
    // AXI write address holding
    // ================================================================
    reg [7:0] aw_lat;
    reg       aw_pend;

    // Latched done bit.
    // This is better than reading i_done directly because i_done may only pulse.
    reg done_latched;

    // Run tracking.
    // This prevents the CSR from treating an idle-high i_done as a real completed run.
    //
    // Correct done sequence:
    //   1. CPU writes START.
    //   2. run_active becomes 1.
    //   3. CSR waits until i_done becomes 0 at least once.
    //   4. CSR accepts the next i_done=1 as the real accelerator completion.
    reg run_active;
    reg seen_done_low_after_start;

    // Optional debug registers/signals, useful for ILA
    reg dbg_ctrl_write_hit;
    reg dbg_any_write_hit;

    // ================================================================
    // AXI Write Path
    // ================================================================
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_bvalid  <= 1'b0;
            s_axil_bresp   <= 2'b00;

            aw_pend <= 1'b0;
            aw_lat  <= 8'd0;

            o_conv_mode    <= 1'b0;
            o_p_mode       <= 2'd0;

            o_i_size       <= {ADDR_WIDTH{1'b0}};
            o_i_c_size     <= {ADDR_WIDTH{1'b0}};
            o_o_c_size     <= {ADDR_WIDTH{1'b0}};
            o_o_size       <= {ADDR_WIDTH{1'b0}};

            o_stride       <= {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
            o_depth_mult   <= {{(ADDR_WIDTH-1){1'b0}}, 1'b1};

            o_i_start_addr <= {ADDR_WIDTH{1'b0}};
            o_i_addr_end   <= {ADDR_WIDTH{1'b0}};
            o_w_start_addr <= {ADDR_WIDTH{1'b0}};
            o_w_addr_end   <= {ADDR_WIDTH{1'b0}};

            o_route_en     <= 1'b0;
            o_reg_clear    <= 1'b0;

            o_zero_point   <= {DATA_WIDTH{1'b0}};
            o_input_offset <= {DATA_WIDTH{1'b0}};

            o_pad_h <= {DATA_WIDTH{1'b0}};
            o_pad_w <= {DATA_WIDTH{1'b0}};

            done_latched              <= 1'b0;
            run_active                <= 1'b0;
            seen_done_low_after_start <= 1'b0;

            dbg_ctrl_write_hit <= 1'b0;
            dbg_any_write_hit  <= 1'b0;

        end else begin
            // Defaults every cycle
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;

            // reg_clear should stay a pulse.
            o_reg_clear <= 1'b0;

            // Debug pulses
            dbg_ctrl_write_hit <= 1'b0;
            dbg_any_write_hit  <= 1'b0;

            // Latch done so software can see it even if i_done is a short pulse.
            //
            // IMPORTANT:
            // Do not latch i_done immediately just because it is high.
            // top.sv may have o_done=1 while idle. If we accepted that directly,
            // CSR_STATUS would become 1 immediately after START and o_route_en
            // would be cleared before the accelerator actually runs.
            //
            // Instead, after START, wait for i_done to go LOW once, then accept
            // the next HIGH as the true run completion.
            if (run_active) begin
                if (!i_done) begin
                    seen_done_low_after_start <= 1'b1;
                end

                if (seen_done_low_after_start && i_done) begin
                    done_latched <= 1'b1;
                    run_active   <= 1'b0;

                    // Stop route_en once accelerator reports a real done.
                    o_route_en   <= 1'b0;
                end
            end

            // Accept write address.
            if (s_axil_awvalid && !aw_pend && !s_axil_bvalid) begin
                s_axil_awready <= 1'b1;
                aw_lat  <= s_axil_awaddr;
                aw_pend <= 1'b1;
            end

            // Accept write data after address has been latched.
            if (s_axil_wvalid && aw_pend && !s_axil_bvalid) begin
                s_axil_wready <= 1'b1;
                aw_pend       <= 1'b0;

                dbg_any_write_hit <= 1'b1;

                case (aw_lat[7:2])
                    6'h00: o_conv_mode    <= s_axil_wdata[0];
                    6'h01: o_p_mode       <= s_axil_wdata[1:0];
                    6'h02: o_i_size       <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h03: o_i_c_size     <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h04: o_o_c_size     <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h05: o_o_size       <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h06: o_stride       <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h07: o_depth_mult   <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h08: o_i_start_addr <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h09: o_i_addr_end   <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h0A: o_w_start_addr <= s_axil_wdata[ADDR_WIDTH-1:0];
                    6'h0B: o_w_addr_end   <= s_axil_wdata[ADDR_WIDTH-1:0];

                    6'h0C: begin
                        // CTRL register
                        // bit 0: route_en/start
                        // bit 1: reg_clear
                        dbg_ctrl_write_hit <= 1'b1;

                        // Make route_en sticky instead of one-cycle pulse.
                        // This lets top.sv run as long as route_en is high.
                        if (s_axil_wdata[1]) begin
                            // reg_clear clears route_en and done state.
                            o_route_en                <= 1'b0;
                            o_reg_clear               <= 1'b1;
                            done_latched              <= 1'b0;
                            run_active                <= 1'b0;
                            seen_done_low_after_start <= 1'b0;
                        end else if (s_axil_wdata[0]) begin
                            // START the accelerator.
                            // Clear previous done and begin watching for a real done transition.
                            o_route_en                <= 1'b1;
                            done_latched              <= 1'b0;
                            run_active                <= 1'b1;
                            seen_done_low_after_start <= 1'b0;
                        end else begin
                            // Manual stop / write CTRL=0.
                            o_route_en                <= 1'b0;
                            run_active                <= 1'b0;
                            seen_done_low_after_start <= 1'b0;
                        end
                    end

                    // 6'h0D: STATUS is read-only.

                    6'h0E: begin
                        o_zero_point <= s_axil_wdata[DATA_WIDTH-1:0];
                    end

                    6'h0F: begin
                        o_input_offset <= s_axil_wdata[DATA_WIDTH-1:0];
                    end

                    6'h10: begin
                        // DDR_STATUS is read-only.
                    end

                    6'h11: begin // Top padding
                        o_pad_h <= s_axil_wdata[DATA_WIDTH-1:0];
                    end
                    
                    6'h12: begin // Left padding
                        o_pad_w <= s_axil_wdata[DATA_WIDTH-1:0];
                    end

                    default: begin
                        // unmapped write ignored
                    end
                endcase

                s_axil_bvalid <= 1'b1;
                s_axil_bresp  <= 2'b00;
            end

            // Complete write response.
            if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

    // ================================================================
    // AXI Read Path
    // ================================================================
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid  <= 1'b0;
            s_axil_rdata   <= 32'd0;
            s_axil_rresp   <= 2'b00;

        end else begin
            s_axil_arready <= 1'b0;

            if (s_axil_arvalid && !s_axil_rvalid) begin
                s_axil_arready <= 1'b1;

                case (s_axil_araddr[7:2])
                    6'h00: s_axil_rdata <= {31'd0, o_conv_mode};
                    6'h01: s_axil_rdata <= {30'd0, o_p_mode};
                    6'h02: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_i_size};
                    6'h03: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_i_c_size};
                    6'h04: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_o_c_size};
                    6'h05: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_o_size};
                    6'h06: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_stride};
                    6'h07: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_depth_mult};
                    6'h08: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_i_start_addr};
                    6'h09: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_i_addr_end};
                    6'h0A: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_w_start_addr};
                    6'h0B: s_axil_rdata <= {{(32-ADDR_WIDTH){1'b0}}, o_w_addr_end};

                    // CTRL readback:
                    // bit 0 shows current sticky route_en.
                    // bit 1 is usually 0 because reg_clear is a pulse.
                    6'h0C: s_axil_rdata <= {30'd0, o_reg_clear, o_route_en};

                    // STATUS:
                    // bit 0 is latched done.
                    // This is safer than exposing raw i_done only.
                    6'h0D: s_axil_rdata <= {31'd0, done_latched};

                    // Input and output zero points/offsets.
                    6'h0E: s_axil_rdata <= {{(32-DATA_WIDTH){o_zero_point[DATA_WIDTH-1]}}, o_zero_point};
                    6'h0F: s_axil_rdata <= {{(32-DATA_WIDTH){o_input_offset[DATA_WIDTH-1]}}, o_input_offset};

                    // DDR_STATUS at byte offset 0x40.
                    // Since address decode uses [7:2], 0x40 becomes 6'h10.
                    6'h10: s_axil_rdata <= {31'd0, i_ddr_calib_done};

                    // Padding registers.
                    6'h11: s_axil_rdata <= {{(32-DATA_WIDTH){1'b0}}, o_pad_h};
                    6'h12: s_axil_rdata <= {{(32-DATA_WIDTH){1'b0}}, o_pad_w};

                    default: s_axil_rdata <= 32'hB0BACAFE;
                endcase

                s_axil_rresp  <= 2'b00;
                s_axil_rvalid <= 1'b1;
            end

            if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

endmodule