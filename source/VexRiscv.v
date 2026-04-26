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
reg [31:0] regfile [31:0];
reg [1:0] state;

localparam FETCH = 0;
localparam EXEC  = 1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        pc <= 32'h00000000;
        wishbone_cyc <= 1'b0;
        wishbone_stb <= 1'b0;
        wishbone_we <= 1'b0;
        wishbone_adr <= 32'h0;
        wishbone_dat_w <= 32'h0;
        state <= FETCH;
    end else begin
        case (state)
            FETCH: begin
                wishbone_cyc <= 1'b1;
                wishbone_stb <= 1'b1;
                wishbone_we <= 1'b0;
                wishbone_adr <= pc;

                if (wishbone_ack) begin
                    inst <= wishbone_dat_r;
                    state <= EXEC;
                    wishbone_cyc <= 1'b0;
                    wishbone_stb <= 1'b0;
                end
            end

            EXEC: begin
                pc <= pc + 32'd4;
                state <= FETCH;
            end
        endcase
    end
end

// ¼Ä´æÆ÷³õÊ¼»¯
integer i;
initial begin
    for(i=0; i<32; i=i+1)
        regfile[i] = 32'h00000000;
end

endmodule