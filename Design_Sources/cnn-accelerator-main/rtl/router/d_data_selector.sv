`timescale 1ns / 1ps

module d_data_selector #(
    parameter int SPAD_DATA_WIDTH = 64,
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 8,
    parameter int SPAD_N = SPAD_DATA_WIDTH / DATA_WIDTH,
    parameter int MPP_DEPTH = 9
) (
    input logic i_clk,
    input logic i_nrst,
    input logic i_reg_clear,
    input logic i_en,
    input logic [DATA_WIDTH-1:0] i_pad_value, // Value to use for padded inputs

    // Controller signals
    // Write to MPP FIFO
    input [0:MPP_DEPTH-1][$clog2(SPAD_N)+ADDR_WIDTH-1:0] i_sw_addr,
    input logic [0:MPP_DEPTH-1] i_sw_pad,
    input logic i_addr_write_en,

    // Spad signals
    input logic [SPAD_DATA_WIDTH-1:0] i_spad_data,
    input logic [0:SPAD_N-1][$clog2(SPAD_N)+ADDR_WIDTH-1:0] i_spad_addr,
    input logic i_data_valid,

    // Data selector signals
    // Write to MISO FIFO
    output logic [SPAD_N-1:0] o_data_hit,
    output logic [SPAD_DATA_WIDTH-1:0] o_data,
    output logic o_route_done,

    // Stall signal to tile reader. If the hit data is a padding entry, we need to stall the tile reader.
    output logic o_stall
);
    logic [0:SPAD_N-1][DATA_WIDTH-1:0] spad_data;
    logic [0:SPAD_N-1][$clog2(SPAD_N)+ADDR_WIDTH-1:0] spad_addr;
    logic [0:MPP_DEPTH-1][$clog2(SPAD_N)+ADDR_WIDTH:0] mpp_data_in;
    logic [SPAD_N-1:0][$clog2(SPAD_N)+ADDR_WIDTH:0] peek_addr_packed;
    logic [SPAD_N-1:0] peek_pad;
    logic [SPAD_N-1:0][$clog2(SPAD_N)+ADDR_WIDTH-1:0] peek_addr;
    logic [SPAD_N-1:0] peek_valid;

    genvar ii;
    generate
        for (ii=0; ii < SPAD_N; ii++) begin
            assign spad_data[ii] = i_spad_data[ii*DATA_WIDTH+:DATA_WIDTH];
            assign peek_pad[ii] = peek_addr_packed[ii][$clog2(SPAD_N)+ADDR_WIDTH];
            assign peek_addr[ii] = peek_addr_packed[ii][$clog2(SPAD_N)+ADDR_WIDTH-1:0];
        end
    endgenerate

    genvar jj;
    generate
        for (jj=0; jj < MPP_DEPTH; jj++) begin
            assign mpp_data_in[jj] = {i_sw_pad[jj], i_sw_addr[jj]};
        end
    endgenerate

    assign spad_addr = i_spad_addr;

    logic [SPAD_N-1:0] addr_hit [SPAD_N-1:0];
    logic [SPAD_N-1:0] f_addr_hit, ordered_hit;
    logic [SPAD_N-1:0][DATA_WIDTH-1:0] data_hit, f_data_hit;

    logic mpp_pop_en;
    assign mpp_pop_en = f_addr_hit[0];

    logic mpp_empty;

    mpp_fifo #(
        .DEPTH(MPP_DEPTH),
        .DATA_WIDTH($clog2(SPAD_N)+ADDR_WIDTH+1), // Each entry contains the pad bit and the byte address of a SPAD data element
        .DATA_LENGTH(MPP_DEPTH),
        .PEEK_WIDTH(SPAD_N)
    ) mpp_fifo (
        .i_clk(i_clk),
        .i_nrst(i_nrst),
        .i_clear(i_reg_clear),
        .i_write_en(i_addr_write_en),
        .i_data_in(mpp_data_in),
        .i_pop_en(mpp_pop_en),
        .i_data_hit(ordered_hit),
        .o_peek_data(peek_addr_packed),
        .o_peek_valid(peek_valid),
        .o_empty(mpp_empty),
        .o_full()
    );

    // Address comparator
    // ~o_route_done
    always_comb begin
        if (i_en & i_data_valid & ~mpp_empty) begin
            for (int j = 0; j < SPAD_N; j++) begin // j is the index for peek_addr
                data_hit[j] = '0;

                for (int i = 0; i < SPAD_N; i++) begin // i is the index for spad_addr
                    addr_hit[j][i] = 0;
                end

                if (peek_valid[j]) begin
                    if (peek_pad[j]) begin
                        // Padding entry: guaranteed hit
                        data_hit[j] = i_pad_value; // Use the specified padding value for padded inputs

                        for (int i = 0; i < SPAD_N; i++) begin
                            addr_hit[j][i] = 1;
                        end
                    end
                    else begin
                        for (int i = 0; i < SPAD_N; i++) begin
                            if (spad_addr[i] == peek_addr[j]) begin
                                addr_hit[j][i] = 1;
                                data_hit[j] = spad_data[i];
                            end
                        end
                    end
                end
            end
        end else begin
            for (int i = 0; i < SPAD_N; i++) begin
                for (int j = 0; j < SPAD_N; j++) begin
                    addr_hit[j][i] = 0;
                end
            end

            for (int i = 0; i < SPAD_N; i++) begin
                data_hit[i] = 0;
            end
        end

        for (int j = 0; j < SPAD_N; j++) begin
            f_addr_hit[j] = | addr_hit[j];
        end

        ordered_hit[0] = f_addr_hit[0]; // First entry can be valid as long as it hits, no need to wait for previous entries
        for (int j = 1; j < SPAD_N; j++) begin // Ensure order of hits matches order in MPP FIFO
            ordered_hit[j] = f_addr_hit[j] & ordered_hit[j-1];
        end

        for (int i = 0; i < SPAD_N; i++) begin
            if (ordered_hit[i]) begin
                f_data_hit[i] = data_hit[i];
            end else begin
                f_data_hit[i] = 0;
            end
        end
    end

    always_comb begin
        o_data_hit = ordered_hit;
        o_data = f_data_hit;
        o_stall = | (ordered_hit & peek_pad); // If the hit data is a padding entry, stall the tile reader. 
        o_route_done = mpp_empty;
    end
endmodule