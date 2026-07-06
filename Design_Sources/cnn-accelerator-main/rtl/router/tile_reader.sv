module tile_reader #(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 64
) (
    input  logic                  i_clk,
    input  logic                  i_nrst,
    input  logic                  i_en,
    input  logic                  i_reg_clear,
    input  logic                  i_stall,

    input  logic [ADDR_WIDTH-1:0] i_start_addr,
    input  logic [ADDR_WIDTH-1:0] i_addr_end,

    input  logic [DATA_WIDTH-1:0] i_data_in,
    input  logic                  i_data_in_valid,
    output logic                  o_spad_read_en,
    output logic                  o_spad_read_done,
    output logic [ADDR_WIDTH-1:0] o_spad_read_addr,

    output logic [ADDR_WIDTH-1:0] o_addr,
    output logic [DATA_WIDTH-1:0] o_data,
    output logic                  o_data_valid
);

    logic [ADDR_WIDTH-1:0] reg_counter;
    logic [ADDR_WIDTH-1:0] reg_read_addr;
    logic [ADDR_WIDTH-1:0] reg_addr_pipe;
    logic [ADDR_WIDTH-1:0] next_read_addr;

    // Stall buffer – captures the SPAD result that arrived while output was stalled
    logic [DATA_WIDTH-1:0] buf_data;
    logic [ADDR_WIDTH-1:0] buf_addr;
    logic                  buf_valid;

    assign next_read_addr = i_start_addr + reg_counter;

    // =======================================================================
    // SPAD read control – freeze completely during stall
    // =======================================================================
    always_ff @(posedge i_clk) begin
        if (~i_nrst) begin
            reg_counter      <= '0;
            reg_read_addr    <= '0;   
            o_spad_read_en   <= 1'b0;
            o_spad_read_done <= 1'b0;
        end else if (i_reg_clear) begin
            reg_counter      <= '0;
            reg_read_addr    <= '0;
            o_spad_read_en   <= 1'b0;
            o_spad_read_done <= 1'b0;
        end else if (i_en & ~o_spad_read_done & ~i_stall) begin
            if (next_read_addr <= i_addr_end) begin
                o_spad_read_en <= 1'b1;
                reg_read_addr  <= next_read_addr;
                reg_counter    <= reg_counter + 1'b1;
            end else if (o_spad_read_en) begin
                // Last read already issued, wait for final data
                o_spad_read_en <= 1'b0;
            end else begin
                // Final data has returned → transaction done
                reg_counter      <= '0;
                reg_read_addr    <= '0;
                o_spad_read_done <= 1'b1;
            end
        end
    end

    // =======================================================================
    // Address pipeline – captures the address that was actually sent to SPAD
    // on the same cycle the read is issued.  reg_read_addr holds the *current*
    // address before it is updated to the next one.
    // =======================================================================
    always_ff @(posedge i_clk) begin
        if (~i_nrst || i_reg_clear) begin
            reg_addr_pipe <= '0;    
        end else if (o_spad_read_en & ~i_stall) begin
            // A read is being issued right now, and the output side is not stalled.
            // reg_read_addr still has the address that will be used for this read.
            reg_addr_pipe <= reg_read_addr;
        end
    end

    // =======================================================================
    // Stall buffer – captures any valid SPAD data that returns while the
    // output is stalled.  Only used when i_en is high (the transaction is
    // active).
    // =======================================================================
    always_ff @(posedge i_clk) begin
        if (~i_nrst || i_reg_clear) begin
            buf_valid <= 1'b0;
            buf_data  <= '0;
            buf_addr  <= '0;
        end else begin
            // Capture when stalled and i_en is still high
            if (i_stall & i_en & i_data_in_valid & ~buf_valid) begin
                buf_valid <= 1'b1;
                buf_data  <= i_data_in;
                buf_addr  <= reg_addr_pipe;   // address of the read that just returned
            end else if (~i_stall & buf_valid) begin
                // Buffer has been consumed (see output block), clear it next cycle
                buf_valid <= 1'b0;
            end
        end
    end

    // =======================================================================
    // Data output – only active when i_en high and not stalled.
    // Buffered data has priority over live SPAD data.
    // =======================================================================
    always_ff @(posedge i_clk) begin
        if (~i_nrst) begin
            o_data       <= '0;
            o_data_valid <= 1'b0;
            o_addr       <= '0;
        end else if (i_reg_clear) begin
            o_data       <= '0;
            o_data_valid <= 1'b0;
            o_addr       <= '0;
        end else if (i_en & ~i_stall) begin
            if (buf_valid) begin
                o_data       <= buf_data;
                o_addr       <= buf_addr;
                o_data_valid <= 1'b1;
            end else begin
                o_data       <= i_data_in;
                o_data_valid <= i_data_in_valid;
                o_addr       <= reg_addr_pipe;
            end
        end
        // When (i_en == 0) or (i_stall == 1), outputs remain unchanged.
    end

    assign o_spad_read_addr = reg_read_addr;

endmodule