`timescale 1ns / 1ps

module input_router #(
    parameter int DATA_WIDTH = 8,
    parameter int SPAD_DATA_WIDTH = 64,
    parameter int SPAD_N = SPAD_DATA_WIDTH / DATA_WIDTH,
    parameter int ADDR_WIDTH = 8,
    parameter int COUNT = 4,
    parameter int MISO_DEPTH = 16,
    parameter int KERNEL_LENGTH = 9
)(
    input logic i_clk,
    input logic i_nrst,
    input logic i_en,
    input logic i_reg_clear,
    input logic i_fifo_pop_en,
    input logic i_fifo_ptr_reset,

    // Precision mode - 0: 8x8, 1: 4x4: 2: 2x2
    input logic [1:0] i_p_mode,

    // Convolution mode - 0: PWise, 1: DWise
    input logic i_conv_mode,

    // Array dimensions
    input logic [ADDR_WIDTH-1:0] i_i_size,
    input logic [ADDR_WIDTH-1:0] i_o_size,
    input logic [ADDR_WIDTH-1:0] i_i_c_size,
    input logic [ADDR_WIDTH-1:0] i_i_c,
    input logic [ADDR_WIDTH-1:0] i_stride,
    input logic [DATA_WIDTH-1:0] i_offset, // For signed quantization offset
    input logic [DATA_WIDTH-1:0] i_pad_h, // Vertical padding size
    input logic [DATA_WIDTH-1:0] i_pad_w, // Horizontal padding size

    // SPAD related signals
    input logic i_spad_write_en,
    input logic [SPAD_DATA_WIDTH-1:0] i_spad_data_in,
    input logic [ADDR_WIDTH-1:0] i_spad_write_addr,
    input logic [SPAD_N-1:0] i_spad_write_mask, // We might want to write partial words into the SPAD in the future

    // Tile Reader related signals
    input logic [ADDR_WIDTH-1:0] i_start_addr,
    input logic [ADDR_WIDTH-1:0] i_addr_end,
    output logic o_read_done,

    // Output signals
    output logic [COUNT-1:0][DATA_WIDTH:0] o_data,
    output logic [COUNT-1:0] o_data_valid,

    // Output router signals
    output logic [ADDR_WIDTH-1:0] o_x_s, o_x_e, o_y_s, o_y_e,
    output logic o_xy_valid,
    output logic [ADDR_WIDTH-1:0] o_xy_length,

    // Top level control signals
    output logic [ADDR_WIDTH-1:0] o_s_r, o_t,

    // Status signals
    output logic o_ready,
    output logic o_context_done, // Done with current set of values
    output logic o_done, // Done with all output values
    output logic o_tile_done, // Reset the write pointer in Weight FIFO,
    output logic o_route_en
);
    // SPAD related signals
    // We will move this to top level module
    logic [SPAD_DATA_WIDTH-1:0] spad_data_out;
    logic spad_data_out_valid;
    logic [ADDR_WIDTH-1:0] spad_read_addr;
    logic spad_read_en;

    // Tile Reader related signals
    // Forward this to routers
    logic [ADDR_WIDTH-1:0] tr_addr, tile_addr;
    logic [SPAD_DATA_WIDTH-1:0] tr_data;
    logic tr_data_valid;

    // Controller to Router and Tile Reader
    logic route_en, reg_clear, tr_clear, cntr_clear, tr_stall;

    // From Data Selector to Tile Reader
    logic pad_stall; // If the data selector needs to stall, stall the tile reader

    // Controller to Router Array
    logic fifo_pop_en, fifo_route_done, fifo_empty, fifo_full, fifo_clear, fifo_idle;
    logic [0:KERNEL_LENGTH-1][$clog2(SPAD_N)+ADDR_WIDTH-1:0] dl_sw_addr;
    logic [0:KERNEL_LENGTH-1] dl_sw_pad;
    logic [$clog2(SPAD_N)+ADDR_WIDTH-1:0] dl_start_addr, dl_end_addr;
    logic [ADDR_WIDTH-1:0] dl_id;
    logic dl_addr_write_en;
    
    logic [ADDR_WIDTH-1:0] slots;

    spad #(
        .ADDR_WIDTH(14),
        .SPAD_WIDTH(SPAD_DATA_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SPAD_N(SPAD_N)
    ) ir_spad (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_write_en(i_spad_write_en),
        .i_read_en(spad_read_en),
        .i_data_in(i_spad_data_in),
        .i_write_addr(i_spad_write_addr),
        .i_write_mask(i_spad_write_mask),
        .i_read_addr(spad_read_addr),
        .o_data_out(spad_data_out),
        .o_data_out_valid(spad_data_out_valid)
    );

    tile_reader #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(SPAD_DATA_WIDTH)
    ) ir_tile_reader (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(route_en),
        .i_reg_clear(reg_clear || tr_clear || i_reg_clear),
        .i_stall(tr_stall || pad_stall),
        .i_start_addr(tile_addr),
        .i_addr_end(i_addr_end),
        .i_data_in(spad_data_out),
        .i_data_in_valid(spad_data_out_valid),
        .o_spad_read_en(spad_read_en),
        .o_spad_read_done(o_read_done), // We kind of assume that all the data is in the SPAD
        .o_spad_read_addr(spad_read_addr),
        .o_addr(tr_addr),
        .o_data(tr_data),
        .o_data_valid(tr_data_valid)
    );

    ir_controller #(
        .ROW(COUNT),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SPAD_N(SPAD_N)
    ) ir_controller (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_en(i_en),
        .i_reg_clear(i_reg_clear),
        .i_pop_en(i_fifo_pop_en),
        .i_conv_mode(i_conv_mode),
        .i_i_size(i_i_size),
        .i_o_size(i_o_size),
        .i_i_c_size(i_i_c_size),
        .i_i_c(i_i_c),
        .i_stride(i_stride),
        .i_pad_h({{(ADDR_WIDTH-DATA_WIDTH){1'b0}}, i_pad_h}),
        .i_pad_w({{(ADDR_WIDTH-DATA_WIDTH){1'b0}}, i_pad_w}),
        .i_start_addr(i_start_addr),
        .o_dl_sw_addr(dl_sw_addr),
        .o_dl_sw_pad(dl_sw_pad),
        .o_dl_start_addr(dl_start_addr),
        .o_dl_end_addr(dl_end_addr),
        .o_dl_id(dl_id),
        .o_dl_addr_write_en(dl_addr_write_en),
        .o_x_s(o_x_s),
        .o_x_e(o_x_e),
        .o_y_s(o_y_s),
        .o_y_e(o_y_e),
        .o_xy_valid(o_xy_valid),
        .o_xy_length(o_xy_length),
        .o_route_en(route_en),
        .o_pop_en(fifo_pop_en),
        .o_reg_clear(reg_clear),
        .o_fifo_clear(fifo_clear),
        .o_tr_clear(tr_clear),
        .o_tr_stall(tr_stall),
        .o_cntr_clear(cntr_clear),
        .i_fifo_full(fifo_full),
        .i_fifo_route_done(fifo_route_done),
        .i_fifo_empty(fifo_empty),
        .i_fifo_idle(fifo_idle),
        .o_done(o_done),
        .o_context_done(o_context_done),
        .o_tile_done(o_tile_done),
        .o_ready(o_ready),
        .o_tile_addr(tile_addr),
        .o_s_r(o_s_r),
        .o_t(o_t),
        .i_slots(slots)
    );

    logic [COUNT-1:0][DATA_WIDTH-1:0] input_data;
    data_lane_array #(
        .COUNT(COUNT),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SPAD_DATA_WIDTH(SPAD_DATA_WIDTH),
        .SPAD_N(SPAD_N),
        .MISO_DEPTH(MISO_DEPTH),
        .MPP_DEPTH(KERNEL_LENGTH)
    ) ir_dl_array (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_reg_clear(reg_clear || i_reg_clear),
        .i_cntr_clear(cntr_clear),
        .i_fifo_clear(fifo_clear),
        .i_fifo_ptr_reset(i_fifo_ptr_reset),
        .i_conv_mode(i_conv_mode),
        .i_id(dl_id),
        .i_sw_addr(dl_sw_addr),
        .i_sw_pad(dl_sw_pad),
        .i_start_addr(dl_start_addr),
        .i_end_addr(dl_end_addr),
        .i_addr_write_en(dl_addr_write_en),
        .i_ac_en(route_en),
        .i_data(tr_data),
        .i_addr(tr_addr),
        .i_data_valid(tr_data_valid),
        .i_miso_pop_en(fifo_pop_en),
        .i_p_mode(i_p_mode),
        .i_pad_value(i_offset),
        .o_data(input_data),
        .o_data_valid(o_data_valid),
        .o_fifo_full(fifo_full),
        .o_fifo_empty(fifo_empty),
        .o_route_done(fifo_route_done),
        .o_idle(fifo_idle),
        .o_slots(slots),
        .o_stall(pad_stall)
    );

    genvar ii;
    generate
        for (ii=0; ii < COUNT; ii++) begin
            assign o_data[ii] = (o_data_valid[ii]) ? 
                                ({input_data[ii][DATA_WIDTH-1], input_data[ii]} - {i_offset[DATA_WIDTH-1], i_offset})
                                : '0;
        end
    endgenerate

    assign o_route_en = route_en;
    /*
    // Debug: Display o_data one cycle after fifo_pop_en is asserted
    logic fifo_pop_en_r = 0;
    always @(posedge i_clk) begin
        fifo_pop_en_r <= fifo_pop_en;
        if (fifo_pop_en_r) begin
            $display("[%0t] o_data (after fifo_pop_en): %h", $time, o_data);
        end
    end
    */
endmodule