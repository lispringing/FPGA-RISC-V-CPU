module top(
    input  wire clk_50m,
    input  wire rst_n,
    output wire led_test,
    output wire uart_tx
);

wire cpu_clk;
wire sys_rst_n;

assign cpu_clk   = clk_50m;
assign sys_rst_n = rst_n;
wire rst_high = ~sys_rst_n;

// LED 心跳
reg [24:0] cnt;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) cnt <= 25'd0;
    else       cnt <= cnt + 1'd1;
end
assign led_test = cnt[24];

// ==================== 全局Wishbone ====================
wire        wb_cyc;
wire        wb_stb;
wire        wb_we;
wire [31:0] wb_adr;
wire [31:0] wb_dat_w;
wire [31:0] wb_dat_r_ram;
wire [31:0] wb_dat_r_uart;
wire        wb_ack_ram;
wire        wb_ack_uart;

// 设备选择
wire sel_ram  = (wb_adr[31:28] == 4'h0);
wire sel_uart = (wb_adr[31:28] == 4'h1);

reg [31:0] wb_dat_r;
reg        wb_ack;
always @(*) begin
    wb_dat_r = 32'd0;
    wb_ack   = 1'b0;
    if(sel_ram)  begin wb_dat_r = wb_dat_r_ram;  wb_ack = wb_ack_ram; end
    if(sel_uart) begin wb_dat_r = wb_dat_r_uart; wb_ack = wb_ack_uart; end
end

// ==================== RISC-V 软核 ====================
VexRiscv u_cpu (
    .clk(cpu_clk),
    .rst(rst_high),

    .wishbone_cyc  (wb_cyc),
    .wishbone_stb  (wb_stb),
    .wishbone_we   (wb_we),
    .wishbone_adr  (wb_adr),
    .wishbone_dat_w(wb_dat_w),
    .wishbone_dat_r(wb_dat_r),
    .wishbone_ack  (wb_ack)
);

// ==================== RAM 内存 ====================
wb_ram #(.DEPTH(16384)) u_ram (
    .clk(cpu_clk),
    .rst(rst_high),

    .wb_cyc  (wb_cyc & sel_ram),
    .wb_stb  (wb_stb & sel_ram),
    .wb_we   (wb_we),
    .wb_adr  (wb_adr),
    .wb_dat_w(wb_dat_w),
    .wb_dat_r(wb_dat_r_ram),
    .wb_ack  (wb_ack_ram)
);

// ==================== UART 串口 ====================
uart_wb #(.CLK_FREQ(50000000),.BAUD(115200)) u_uart (
    .clk(cpu_clk),
    .rst(rst_high),

    .wb_cyc  (wb_cyc & sel_uart),
    .wb_stb  (wb_stb & sel_uart),
    .wb_we   (wb_we),
    .wb_adr  (wb_adr),
    .wb_dat_w(wb_dat_w),
    .wb_dat_r(wb_dat_r_uart),
    .wb_ack  (wb_ack_uart),

    .uart_tx(uart_tx)
);

endmodule