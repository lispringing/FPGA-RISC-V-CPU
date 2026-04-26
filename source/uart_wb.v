module uart_wb
#(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)(
    input  wire        clk,
    input  wire        rst,

    // Wishbone 从设备接口
    input  wire        wb_cyc,
    input  wire        wb_stb,
    input  wire        wb_we,
    input  wire [31:0] wb_adr,
    input  wire [31:0] wb_dat_w,
    output reg  [31:0] wb_dat_r,
    output reg         wb_ack,

    // 物理串口引脚
    output wire        uart_tx
);

localparam BAUD_DIV = CLK_FREQ / BAUD;

reg [15:0] cnt;
reg [3:0]  bit_cnt;
reg [7:0]  tx_data;
reg        tx_en;
reg        tx_reg;

assign uart_tx = tx_reg;

// 应答 & 读数据
always @(posedge clk or posedge rst) begin
    if(rst) begin
        wb_ack  <= 1'b0;
        wb_dat_r<= 32'd0;
    end else begin
        wb_ack <= wb_cyc & wb_stb;
        wb_dat_r<= 32'd0;
    end
end

// 写寄存器：0x00 = 发送字节
always @(posedge clk or posedge rst) begin
    if(rst) begin
        tx_en   <= 1'b0;
        tx_data <= 8'd0;
    end else begin
        if(wb_cyc & wb_stb & wb_we && wb_adr[3:0] == 4'h0) begin
            tx_en   <= 1'b1;
            tx_data <= wb_dat_w[7:0];
        end else begin
            tx_en   <= 1'b0;
        end
    end
end

// 串口发送时序
always @(posedge clk or posedge rst) begin
    if(rst) begin
        cnt     <= 16'd0;
        bit_cnt <= 4'd0;
        tx_reg  <= 1'b1;
    end else begin
        if(tx_en) begin
            cnt     <= 16'd0;
            bit_cnt <= 4'd0;
            tx_reg  <= 1'b0;
        end else begin
            if(cnt < BAUD_DIV - 1) begin
                cnt <= cnt + 1'd1;
            end else begin
                cnt <= 16'd0;
                case(bit_cnt)
                    4'd0: tx_reg <= 1'b0;
                    4'd1: tx_reg <= tx_data[0];
                    4'd2: tx_reg <= tx_data[1];
                    4'd3: tx_reg <= tx_data[2];
                    4'd4: tx_reg <= tx_data[3];
                    4'd5: tx_reg <= tx_data[4];
                    4'd6: tx_reg <= tx_data[5];
                    4'd7: tx_reg <= tx_data[6];
                    4'd8: tx_reg <= tx_data[7];
                    default: tx_reg <= 1'b1;
                endcase
                if(bit_cnt <= 4'd9) bit_cnt <= bit_cnt + 1'd1;
            end
        end
    end
end

endmodule