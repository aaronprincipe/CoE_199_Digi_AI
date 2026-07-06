// DMA Controller for ML Accelerators
// AXI4-Lite Slave, with an AXI4 Master and then different channels for communication
// You can search different youtube tutorials that talk about the basics of AXI, and the reads n write protocols

//     `define DATA_WIDTH 8
//     `define SPAD_DATA_WIDTH 32
//     `define SPAD_N 4
//     `define ADDR_WIDTH 16
//     `define ROWS 8
//     `define COLUMNS 8
//     `define MISO_DEPTH 16
//     `define MPP_DEPTH 9

// Register mapped channels, base = channel_index * 'h20
//   +0x00  SRC_ADDR0 [31:0]   source address
//   +0x04  DST_ADDR  [31:0]   destination address
//   +0x08  BYTE_LEN  [31:0]   transfer length in bytes
//   +0x0C  CTRL      [31:0]   bit0=START (auto-clears), bit1=reserved
//   +0x10  STATUS    [31:0]   bit0=BUSY, bit1=DONE (W1C)
//   +0x14  SPAD_SEL  [2:0]   target SPAD for this transfer:
//                             000=weights 001=ifmaps 010=bias
//                             011=scale   100=shift
// Btw here is the reference for the initial set up: https://github.com/donlon/axi-dma-controller/tree/main
// Paper refence that I use more (this is really good!!!): https://jtec.utem.edu.my/jtec/article/view/5774

// Another note: W1C means write 1 to clear

`timescale 1 ns / 1 ps
module DMA_Controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,   // find the AXI Master Data Width
    parameter NUM_CHANNEL = 4,   // need to tell which of the blocks are being spoken to 
    parameter MAX_AXI_BURST = 32 // double check the ARLen and AWLen max bits, but these are the beats of the axi burst len
    )(
        input wire clk, nrst,
    
        // --- AXI4-Lite Slave, CPU communication ---
        // Note: lower case signals are for axi lite, the upper case are all interface
        // then all the ready signals are registers that will communicate with the RISC-V processor 
        input wire [15:0] s_axil_awaddr, // valid addresses and valid for writing operations
        input wire        s_axil_awvalid, 
        output reg        s_axil_awready,
        input wire [31:0] s_axil_wdata,  // actual data writing and to see if if ready to receive valid data
        input wire        s_axil_wvalid,
        output reg        s_axil_wready,
        output reg [1:0]  s_axil_bresp,  // to see if the write was successful or not in the write response channel
        output reg        s_axil_bvalid, 
        input wire        s_axil_bready,
        input wire [15:0] s_axil_araddr,  // read address channels
        input wire        s_axil_arvalid,
        output reg        s_axil_arready,
        output reg [31:0] s_axil_rdata,   // read data channels
        output reg [1:0]  s_axil_rresp,
        output reg        s_axil_rvalid,  
        input  wire       s_axil_rready,
    
        // --- AXI4 Master Interface, where we move the data around in the bus ---
        // Read Channels: from the memory to the rest
        output reg [ADDR_WIDTH-1 : 0] M_AXI_ARADDR, // source address that the DMA will read from
        output reg [7:0]              M_AXI_ARLEN,  // burst length, how many beats to send 
        output reg                    M_AXI_ARVALID,
        input wire                    M_AXI_ARREADY,
        output reg [2:0]              M_AXI_ARSIZE,
        output reg [1:0]              M_AXI_ARBURST,

        input wire [DATA_WIDTH-1 : 0] M_AXI_RDATA,  // actual data from the memory that will be sent to the bus
        input wire                    M_AXI_RVALID,
        input wire                    M_AXI_RLAST,  // indicate the last data in the AXI burst
        output reg                    M_AXI_RREADY,
    
        // Write Channels: sending data to the memory
        output reg [ADDR_WIDTH-1 : 0] M_AXI_AWADDR, // destination address to save the data in 
        output reg [7:0]              M_AXI_AWLEN,
        output reg [2:0]              M_AXI_AWSIZE,
        output reg [1:0]              M_AXI_AWBURST,
        output reg                    M_AXI_AWVALID,
        input wire                    M_AXI_AWREADY,

        output reg [DATA_WIDTH-1 : 0] M_AXI_WDATA,  // data that we will write to the destination address
        output reg                    M_AXI_WVALID,
        output reg                    M_AXI_WLAST,  // what the last piece of data we will write to is in the burst
        input wire                    M_AXI_WREADY,

        input wire [1:0]              M_AXI_BRESP, 
        input wire                    M_AXI_BVALID, // confirm that the data is valid and ready
        output reg                    M_AXI_BREADY,
    
        // --- CPU Interrupt Signal ---
        // after the DMA is done send the interrupt req to the processor
        //output reg [NUM_CHANNEL-1 : 0] interrupt_req // note: need to replace this maybe to fit the polling feature
        
        // SPAD select: valid during S_WDATA, tells top.sv which SPAD to write to
        // Encoding: 000=weights 001=ifmaps 010=bias 011=scale 100=shift
        output wire [2:0]  M_SPAD_SEL,

        // --- MIG 7 Series Signals ---
        // WSTRB: write strobe: 1 bit per byte, all 1s = full beat valid
        // Required by MIG AXI slave
        output wire [DATA_WIDTH/8-1:0] M_AXI_WSTRB,

        // AXI IDs: single master, all in-order, tied to zero
        // MIG requires these even without out-of-order transactions
        output wire [3:0]  M_AXI_ARID,
        output wire [3:0]  M_AXI_AWID,
        input  wire [3:0]  M_AXI_RID,   // returned by MIG, not used
        input  wire [3:0]  M_AXI_BID   // returned by MIG, not used

        // DDR calibration done - do not fire any transfer until HIGH
        // Connect to MIG init_calib_complete (~100us after reset)
        //input  wire        i_ddr_calib_done
    );
        // Constants 
        localparam BPB  = DATA_WIDTH / 8;           // bytes per beat = 8
        localparam BMAX = MAX_AXI_BURST * BPB;      // max bytes per burst = 256
        localparam LBPB = $clog2(BPB);              // log base 2 (8) = 3 for the ARSIZE, AWSIZE
        
        // Register select indices (bits [4:2] of AXI-Lite address)
        localparam [2:0] R_SRC=3'd0, R_DST=3'd1, R_LEN=3'd2, R_CTRL=3'd3, R_STATUS=3'd4, R_SPAD=3'd5;
        localparam [2:0]
            S_IDLE  = 3'd0, S_RADDR = 3'd1, S_RDATA = 3'd2,
            S_WADDR = 3'd3, S_WDATA = 3'd4, S_WRESP = 3'd5, S_DONE  = 3'd6;
         
        // ---------------------------------------------------------------------------
        // Channel description regs written by AXI-Lite slave (CPU side)
        // The master FSM never writes these, single writer per register.
        // ---------------------------------------------------------------------------
        reg [31:0] cfg_src      [0:NUM_CHANNEL-1];
        reg [31:0] cfg_dst      [0:NUM_CHANNEL-1];
        reg [31:0] cfg_len      [0:NUM_CHANNEL-1];
        reg [31:0] cfg_ctrl     [0:NUM_CHANNEL-1]; // bit0=START request, bit1=IRQ_EN not in use anymore
        reg [31:0] reg_status   [0:NUM_CHANNEL-1]; // bit0=BUSY, bit1=DONE (W1C)
        reg [2:0]  cfg_spad_sel [0:NUM_CHANNEL-1]; // which SPAD this channel targets
        // cfg_ctrl[i][0] is SET by CPU write, CLEARED by master FSM handshake flag
         
        // ---------------------------------------------------------------------------
        // AXI-Lite write path: only drives cfg_* registers
        // What this does is it latches the AW addr so that AW and W are different arrivals
        // ---------------------------------------------------------------------------
        reg [15:0] aw_lat;
        reg        aw_pend;
        reg [NUM_CHANNEL-1:0] start_toggle;
        reg [NUM_CHANNEL-1:0] status_clear_toggle;
         
        always @(posedge clk or negedge nrst) begin : p_axil_wr
            integer i;
            if (!nrst) begin
                s_axil_awready <= 0; s_axil_wready <= 0;
                s_axil_bvalid  <= 0; s_axil_bresp  <= 0;
                aw_pend <= 0; aw_lat <= 0;
                start_toggle <= 0;
                status_clear_toggle <= 0;
                for (i = 0; i < NUM_CHANNEL; i = i + 1) begin
                    cfg_src[i] <= 0; cfg_dst[i] <= 0;
                    cfg_len[i] <= 0; cfg_ctrl[i] <= 0;
                    cfg_spad_sel[i] <= 3'b000;  // default to weights SPAD
                end
            end else begin
                s_axil_awready <= 0;
                s_axil_wready  <= 0;
         
                // Latch AW address
                if (s_axil_awvalid && !aw_pend) begin
                    s_axil_awready <= 1;
                    aw_lat  <= s_axil_awaddr;
                    aw_pend <= 1;
                end
         
                // Process W once we have the address
                if (s_axil_wvalid && aw_pend) begin
                    s_axil_wready <= 1;
                    aw_pend <= 0;
                    begin : wdec
                        reg [1:0] ch; reg [2:0] rg;
                        ch = aw_lat[6:5];   // bits[6:5] → channel 0-3
                        rg = aw_lat[4:2];   // bits[4:2] → register index
                        case (rg)
                            R_SRC:    cfg_src[ch]    <= s_axil_wdata;
                            R_DST:    cfg_dst[ch]    <= s_axil_wdata;
                            R_LEN:    cfg_len[ch]    <= s_axil_wdata;
                            R_CTRL: begin
                            // Auto-clear. Makes sure CR is not stuck at 1
                                cfg_ctrl[ch] <= 32'h0;
                                // Redirect the cfg_ctrl writing to only the Main FSM. 
                                // Avoids Synthesis errors.
                                /* Do a toggle instead of storing START as a sticky cfg_ctrl bit.
                                When the CPU writes CTRL.START=1 for a channel, start_toggle[ch] flips.
                                The main FSM checks if start_toggle changed compared to start_seen_toggle.
                                If it changed, the FSM treats that as a new DMA start command. */
                                if (s_axil_wdata[0]) begin
                                    case (ch)
                                        2'd0: start_toggle[0] <= ~start_toggle[0];
                                        2'd1: start_toggle[1] <= ~start_toggle[1];
                                        2'd2: start_toggle[2] <= ~start_toggle[2];
                                        2'd3: start_toggle[3] <= ~start_toggle[3];
                                        default: ;
                                    endcase
                                end
                            end
                            R_STATUS: begin
                            /* Same idea for clearing DONE.
                            When the CPU writes STATUS.DONE=1, status_clear_toggle[ch] flips.
                            The FSM notices the flip and clears the DONE bit itself. */
                                if (s_axil_wdata[1]) begin
                                    case (ch)
                                        2'd0: status_clear_toggle[0] <= ~status_clear_toggle[0];
                                        2'd1: status_clear_toggle[1] <= ~status_clear_toggle[1];
                                        2'd2: status_clear_toggle[2] <= ~status_clear_toggle[2];
                                        2'd3: status_clear_toggle[3] <= ~status_clear_toggle[3];
                                        default: ;
                                    endcase
                                end
                            end
                            R_SPAD:   cfg_spad_sel[ch] <= s_axil_wdata[2:0]; // 3 bits only
                            default: ;
                        endcase
                    end
                    s_axil_bvalid <= 1;
                    s_axil_bresp  <= 2'b00;
                end
         
                if (s_axil_bvalid && s_axil_bready) s_axil_bvalid <= 0;
            end
        end
         
        // ---------------------------------------------------------------------------
        // AXI-Lite read path CPU polling the STATUS
        // rvalid stays high until the rready bit is seen,
        // and that means the AXI handshake is correct
        // ---------------------------------------------------------------------------
        always @(posedge clk or negedge nrst) begin : p_axil_rd
            if (!nrst) begin
                s_axil_arready<=0; s_axil_rvalid<=0; s_axil_rdata<=0; s_axil_rresp<=0;
            end else begin
                s_axil_arready <= 0;
                if (s_axil_arvalid && !s_axil_rvalid) begin
                    s_axil_arready <= 1;
                    begin : rdec
                        reg [1:0] ch; 
                        reg [2:0] rg;
                        ch = s_axil_araddr[6:5]; rg = s_axil_araddr[4:2];
                        case (rg)
                            R_SRC:    s_axil_rdata <= cfg_src[ch];
                            R_DST:    s_axil_rdata <= cfg_dst[ch];
                            R_LEN:    s_axil_rdata <= cfg_len[ch];
                            R_CTRL:   s_axil_rdata <= cfg_ctrl[ch];
                            R_STATUS: s_axil_rdata <= reg_status[ch];
                            R_SPAD:   s_axil_rdata <= {29'd0, cfg_spad_sel[ch]};
                            default:  s_axil_rdata <= 32'hB0BA_CAFE;
                        endcase
                    end
                    s_axil_rresp <= 2'b00; s_axil_rvalid <= 1;
                end
                if (s_axil_rvalid && s_axil_rready) s_axil_rvalid <= 0;
            end
        end
         
        // ---------------------------------------------------------------------------
        // Handshake flags: CPU to FSM via cfg_ctrl[i][0]
        // The FSM polls cfg_ctrl[i][0]. When it sees a rising request on an idle
        // channel it snapshots the descriptor then clears cfg_ctrl[i][0].
        // pending[i] is internal to the master FSM block single writer.
        // ---------------------------------------------------------------------------
         
        // Arbiter (combinational)
        // pending is declared inside p_master; we need a wire for the arbiter
        // Use a generate-time combinational assign outside the always block.
        reg  [NUM_CHANNEL-1:0] pending;        // declared here, written only by p_master
        reg  [NUM_CHANNEL-1:0] start_seen_toggle;
        reg  [NUM_CHANNEL-1:0] status_clear_seen_toggle;
        wire arb_valid = |pending;
        wire [1:0] arb_ch = pending[0] ? 2'd0 :
                            pending[1] ? 2'd1 :
                            pending[2] ? 2'd2 : 2'd3;
         
        // Working registers for the active transfer
        reg [31:0] w_src [0:NUM_CHANNEL-1];
        reg [31:0] w_dst [0:NUM_CHANNEL-1];
        reg [31:0] w_rem [0:NUM_CHANNEL-1];   // remaining bytes
        reg [2:0]  w_spad_sel [0:NUM_CHANNEL-1]; // snapshot of cfg_spad_sel at START
         
        // Beat FIFO, holds one full AXI Burst
        reg [DATA_WIDTH-1:0] fifo [0:MAX_AXI_BURST-1];
        reg [5:0] fw, fr; //write, read pointers!
         
        // FSM state + active channel
        reg [2:0]  mst;
        reg [1:0]  m_ch;
        reg [7:0]  m_blen;      // beats-1 this (current) burst
        reg [31:0] m_bytes;     // bytes this burst
        
        // Master FSM
        // pending, reg_status, writes for src, dest, rem
        // autoclear cfg_ctrl, and all AXI4 master ports
        always @(posedge clk or negedge nrst) begin : p_master
            integer i;
            if (!nrst) begin
                mst <= S_IDLE; m_ch <= 0; m_blen <= 0; m_bytes <= 0;
                fw <= 0; fr <= 0;
                pending <= 0; start_seen_toggle <= 0; status_clear_seen_toggle <= 0; //interrupt_req <= 0;
                for (i = 0; i < NUM_CHANNEL; i = i + 1) begin
                    w_src[i] <= 0; w_dst[i] <= 0; w_rem[i] <= 0; w_spad_sel[i] <= 3'b000;
                    reg_status[i] <= 0;
                end
                M_AXI_ARVALID<=0; M_AXI_RREADY<=0;
                M_AXI_AWVALID<=0; M_AXI_WVALID<=0; M_AXI_WLAST<=0; M_AXI_BREADY<=0;
                M_AXI_ARADDR<=0;  M_AXI_AWADDR<=0;
                M_AXI_ARLEN<=0;   M_AXI_AWLEN<=0;
                M_AXI_ARSIZE<=LBPB[2:0]; M_AXI_AWSIZE<=LBPB[2:0];
                M_AXI_ARBURST<=2'b01; M_AXI_AWBURST<=2'b01;
                M_AXI_WDATA<=0;
            end else begin 
                //interrupt_req <= 0;
         
                // ---- Start-bit detector: runs every cycle, for all channels ----
                // Only accepts a new request if channel is not already pending/active
                for (i = 0; i < NUM_CHANNEL; i = i + 1) begin
                    if (status_clear_toggle[i] != status_clear_seen_toggle[i]) begin
                        reg_status[i] <= reg_status[i] & ~32'h2;
                        status_clear_seen_toggle[i] <= status_clear_toggle[i];
                    end

                    // Guard: do not snapshot until DDR is ready
                    // Without this the DMA hangs in S_RADDR forever
                    // if fired before MIG init_calib_complete goes high
                    if ((start_toggle[i] != start_seen_toggle[i]) && !pending[i] &&
                        !(mst != S_IDLE && m_ch == i[1:0])) begin
                        w_src[i]      <= cfg_src[i];
                        w_dst[i]      <= cfg_dst[i];
                        w_rem[i]      <= cfg_len[i];
                        w_spad_sel[i] <= cfg_spad_sel[i]; // snapshot spad target
                        reg_status[i] <= 32'h1;         // BUSY
                        start_seen_toggle[i] <= start_toggle[i];
                        pending[i]     <= 1;
                    end
                end
         
                // ---- Master FSM ----
                case (mst)
         
                    S_IDLE: begin
                        if (arb_valid) begin
                            m_ch  <= arb_ch;
                            mst   <= S_RADDR;
                        end
                    end
         
                    S_RADDR: begin
                        // Compute burst size  
                        // num_beats = ceil(w_rem / BPB)
                        // ARLEN = num_beats - 1
                        // m_bytes = num_beats * BPB (actual bytes in the burst on the bus)
                        if (w_rem[m_ch] >= BMAX) begin
                            m_blen  <= MAX_AXI_BURST - 1;
                            m_bytes <= BMAX;
                        end else begin
                            // For small transfers: round up bytes to beats, then calculate actual burst bytes
                            // num_beats = (w_rem + BPB - 1) / BPB
                            // m_bytes = num_beats * BPB
                            m_blen  <= ((w_rem[m_ch] + (BPB-1)) / BPB) - 1;
                            m_bytes <= ((w_rem[m_ch] + (BPB-1)) / BPB) * BPB;
                        end
                        M_AXI_ARADDR  <= w_src[m_ch];
                        M_AXI_ARLEN   <= (w_rem[m_ch] >= BMAX) ?
                                          MAX_AXI_BURST - 1 :
                                          ((w_rem[m_ch] + (BPB-1)) / BPB) - 1;
                        M_AXI_ARSIZE  <= LBPB[2:0];
                        M_AXI_ARBURST <= 2'b01;
                        M_AXI_ARVALID <= 1;
                        fw <= 0;
         
                        if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                            M_AXI_ARVALID <= 0;
                            M_AXI_RREADY  <= 1;
                            mst <= S_RDATA;
                        end
                    end
         
                    S_RDATA: begin
                        if (M_AXI_RVALID && M_AXI_RREADY) begin
                            // Byte-swap: convert CPU little-endian {a0,a1,a2,a3} to accelerator big-endian {a3,a2,a1,a0}
                            // Similarly, converts big-endian from accelerator to little-endian for CPU
                            // Assumes 32b words. If DATA_WIDTH changes, this logic needs to be updated.
                            // Actually this should be done in the adapters instead, move this logic there next time.
                            fifo[fw] <= {M_AXI_RDATA[7:0], M_AXI_RDATA[15:8], M_AXI_RDATA[23:16], M_AXI_RDATA[31:24]};
                            fw       <= fw + 1;
                            if (M_AXI_RLAST) begin
                                M_AXI_RREADY  <= 0;
                                fr            <= 0;
                                M_AXI_AWADDR  <= w_dst[m_ch];
                                M_AXI_AWLEN   <= m_blen;
                                M_AXI_AWSIZE  <= LBPB[2:0];
                                M_AXI_AWBURST <= 2'b01;
                                M_AXI_AWVALID <= 1;
                                mst <= S_WADDR;
                            end
                        end
                    end
         
                    S_WADDR: begin
                        if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                            M_AXI_AWVALID <= 0;
                            M_AXI_WDATA   <= fifo[0];
                            M_AXI_WLAST   <= (m_blen == 0);
                            M_AXI_WVALID  <= 1;
                            fr <= 1;
                            mst <= S_WDATA;
                        end
                    end
         
                    S_WDATA: begin
                        if (M_AXI_WVALID && M_AXI_WREADY) begin
                            if (M_AXI_WLAST) begin
                                M_AXI_WVALID <= 0;
                                M_AXI_WLAST  <= 0;
                                M_AXI_BREADY <= 1;
                                mst <= S_WRESP;
                            end else begin
                                M_AXI_WDATA  <= fifo[fr];
                                M_AXI_WLAST  <= (fr == m_blen);
                                fr <= fr + 1;
                            end
                        end
                    end
         
                    S_WRESP: begin
                        if (M_AXI_BVALID && M_AXI_BREADY) begin
                            M_AXI_BREADY     <= 0;
                            w_src[m_ch]      <= w_src[m_ch] + m_bytes;
                            w_dst[m_ch]      <= w_dst[m_ch] + m_bytes;
                            w_rem[m_ch]      <= w_rem[m_ch] - m_bytes;
                            mst <= (w_rem[m_ch] <= m_bytes) ? S_DONE : S_RADDR;
                        end
                    end
         
                    S_DONE: begin
                        reg_status[m_ch]        <= 32'h2;   // DONE=1, BUSY=0
                        pending[m_ch]           <= 0;       // release the bus
                        //if (cfg_ctrl[m_ch][1])            // IRQ_EN
                            //interrupt_req[m_ch] <= 1;
                        mst <= S_IDLE;
                    end
         
                    default: mst <= S_IDLE;
                endcase
            end
        end

// M_SPAD_SEL is valid whenever the master FSM is in S_WDATA
// top.sv uses this to route i_write_en to the correct SPAD
assign M_SPAD_SEL = w_spad_sel[m_ch];

// MIG compatibility: constant assignments
// WSTRB: all bytes always valid, DMA only does full-beat writes
assign M_AXI_WSTRB = {(DATA_WIDTH/8){1'b1}};  // 8'hFF for 64-bit bus

// AXI IDs: single master, no out-of-order, tie to zero
assign M_AXI_ARID  = 4'd0;
assign M_AXI_AWID  = 4'd0;

endmodule
