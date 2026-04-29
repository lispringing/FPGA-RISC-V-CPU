module top(
    input  wire clk_50m,
    input  wire rst_n,
    output wire led_test,
    output wire uart_tx
);

wire rst = ~rst_n;

// LED
reg [24:0] cnt;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) cnt <= 0;
    else cnt <= cnt + 1;
end
assign led_test = cnt[24];

// BUS
wire        wb_cyc;
wire        wb_stb;
wire        wb_we;
wire [31:0] wb_adr;
wire [31:0] wb_dat_w;
wire [31:0] wb_dat_r;
wire        wb_ack;

// UART
wire        uart_sel = (wb_adr[31:28] == 4'h1);
wire [31:0] uart_rdata;
wire        uart_ack;

// RAM
wire        ram_sel  = (wb_adr[31:28] == 4'h0);
wire [31:0] ram_rdata;
wire        ram_ack;

assign wb_dat_r = uart_sel ? uart_rdata : ram_rdata;
assign wb_ack   = uart_sel ? uart_ack   : ram_ack;

// CPU
VexRiscv u_cpu (
    .clk(clk_50m),
    .rst(rst),

    .wishbone_cyc  (wb_cyc),
    .wishbone_stb  (wb_stb),
    .wishbone_we   (wb_we),
    .wishbone_adr  (wb_adr),
    .wishbone_dat_w(wb_dat_w),
    .wishbone_dat_r(wb_dat_r),
    .wishbone_ack  (wb_ack)
);

// RAM
wb_ram u_ram (
    .clk(clk_50m),
    .rst(rst),
    .wb_cyc(wb_cyc & ram_sel),
    .wb_stb(wb_stb & ram_sel),
    .wb_we(wb_we),
    .wb_adr(wb_adr),
    .wb_dat_w(wb_dat_w),
    .wb_dat_r(ram_rdata),
    .wb_ack(ram_ack)
);

// UART
uart_wb #(
    .CLK_FREQ(50000000),
    .BAUD(115200)
) u_uart (
    .clk(clk_50m),
    .rst(rst),
    .wb_cyc(wb_cyc & uart_sel),
    .wb_stb(wb_stb & uart_sel),
    .wb_we(wb_we),
    .wb_adr(wb_adr),
    .wb_dat_w(wb_dat_w),
    .wb_dat_r(uart_rdata),
    .wb_ack(uart_ack),
    .uart_tx(uart_tx)
);

endmodule