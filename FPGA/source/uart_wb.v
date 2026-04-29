module uart_wb
#(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)
(
    input  wire        clk,
    input  wire        rst,

    input  wire        wb_cyc,
    input  wire        wb_stb,
    input  wire        wb_we,
    input  wire [31:0] wb_adr,
    input  wire [31:0] wb_dat_w,
    output reg  [31:0] wb_dat_r,
    output reg         wb_ack,

    output wire        uart_tx
);

localparam DIV = CLK_FREQ / BAUD;

reg [15:0] cnt;
reg [3:0]  bit_cnt;
reg [7:0]  data;
reg        busy;
reg        tx;

assign uart_tx = tx;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        wb_ack  <= 0;
        wb_dat_r<= 0;
        tx      <= 1;
        cnt     <= 0;
        bit_cnt <= 0;
        data    <= 0;
        busy    <= 0;
    end else begin
        wb_ack <= wb_cyc & wb_stb & ~busy;

        if(!busy) begin
            tx <= 1;
            if(wb_cyc & wb_stb & wb_we) begin
                data  <= wb_dat_w[7:0];
                busy  <= 1;
                cnt   <= 0;
                bit_cnt <= 0;
            end
        end else begin
            if(cnt < DIV - 1) begin
                cnt <= cnt + 1;
            end else begin
                cnt <= 0;
                case(bit_cnt)
                    0: tx <= 0;
                    1: tx <= data[0];
                    2: tx <= data[1];
                    3: tx <= data[2];
                    4: tx <= data[3];
                    5: tx <= data[4];
                    6: tx <= data[5];
                    7: tx <= data[6];
                    8: tx <= data[7];
                    default: begin
                        tx <= 1;
                        busy <= 0;
                    end
                endcase
                bit_cnt <= bit_cnt + 1;
            end
        end
    end
end

endmodule