module wb_ram
#(
    parameter DEPTH = 16384
)(
    input  wire clk,
    input  wire rst,

    input  wire        wb_cyc,
    input  wire        wb_stb,
    input  wire        wb_we,
    input  wire [31:0] wb_adr,
    input  wire [31:0] wb_dat_w,
    output reg [31:0] wb_dat_r,
    output reg         wb_ack
);

reg [31:0] mem [0:DEPTH-1];
wire [31:0] addr = wb_adr >> 2;

initial begin
    mem[0] = 32'h0000006F;
    $readmemh("main.hex", mem);
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        wb_ack  <= 1'b0;
        wb_dat_r<= 32'd0;
    end else begin
        wb_ack <= wb_cyc & wb_stb;
        if(wb_cyc & wb_stb) begin
            if(wb_we) mem[addr] <= wb_dat_w;
            wb_dat_r <= mem[addr];
        end
    end
end

endmodule