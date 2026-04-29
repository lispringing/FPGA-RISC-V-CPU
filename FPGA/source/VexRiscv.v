module VexRiscv (
    input  wire        clk,
    input  wire        rst,

    output reg         wishbone_cyc,
    output reg         wishbone_stb,
    output reg         wishbone_we,
    output reg  [31:0] wishbone_adr,
    output reg  [31:0] wishbone_dat_w,
    input  wire [31:0] wishbone_dat_r,
    input  wire        wishbone_ack
);

reg [31:0] pc;
reg [31:0] inst;
reg [3:0]  state;
reg [31:0] delay_cnt;
reg [3:0]  char_idx;

localparam FETCH     = 0;
localparam IDLE_WAIT = 1;
localparam SEND_CHAR = 2;

// Òª·¢ËÍµÄ×Ö·û´®: H e l l o \n
wire [7:0] char_table [0:5];
assign char_table[0] = "H";
assign char_table[1] = "e";
assign char_table[2] = "l";
assign char_table[3] = "l";
assign char_table[4] = "o";
assign char_table[5] = 8'h0A;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        pc             <= 32'd0;
        wishbone_cyc   <= 1'b0;
        wishbone_stb   <= 1'b0;
        wishbone_we    <= 1'b0;
        wishbone_adr   <= 32'd0;
        wishbone_dat_w <= 32'd0;
        state          <= IDLE_WAIT;
        delay_cnt      <= 32'd0;
        char_idx       <= 4'd0;
    end else begin
        case(state)
            // ¼ä¸ôÑÓÊ±£¬·ÀÖ¹Ë¢ÆÁ
            IDLE_WAIT: begin
                wishbone_cyc <= 1'b0;
                wishbone_stb <= 1'b0;
                wishbone_we  <= 1'b0;
                delay_cnt <= delay_cnt + 1'd1;
                if(delay_cnt >= 32'd2500000) begin
                    delay_cnt <= 32'd0;
                    char_idx  <= 4'd0;
                    state     <= SEND_CHAR;
                end
            end

            // Öð¸ö·¢×Ö·û
            SEND_CHAR: begin
                wishbone_cyc   <= 1'b1;
                wishbone_stb   <= 1'b1;
                wishbone_we    <= 1'b1;
                wishbone_adr   <= 32'h10000000;
                wishbone_dat_w <= {24'd0, char_table[char_idx]};

                if(wishbone_ack) begin
                    wishbone_cyc <= 1'b0;
                    wishbone_stb <= 1'b0;
                    wishbone_we  <= 1'b0;
                    if(char_idx < 4'd5) begin
                        char_idx <= char_idx + 1'd1;
                    end else begin
                        state <= IDLE_WAIT;
                    end
                end
            end

            default: state <= IDLE_WAIT;
        endcase
    end
end

endmodule