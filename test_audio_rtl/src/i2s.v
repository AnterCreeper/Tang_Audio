module i2s(
    input iclk,
    input en,

    output reg rd_sel,
    output reg[8:0] rd_addr,
    input[7:0] rd_data,

    output i2s_bclk,
    output reg i2s_lrclk,
    output reg i2s_data,
    
    output test
);

reg[3:0] fsm;
reg[4:0] div;

initial begin
    i2s_data <= 0;
    i2s_lrclk <= 1;
    fsm <= 0;
    div <= 0;
    rd_sel <= 0;
    rd_addr <= 0;
end

reg tx;
reg cke;

initial
begin
    tx <= 0;
    cke <= 0;
end

reg pclk;
reg[3:0] pclk_div;

initial
begin
    pclk <= 0;
    pclk_div <= 0;
end

assign test = i2s_lrclk;

always @(posedge iclk)
begin
    if (pclk_div == 7)
    begin
        pclk_div <= 0;
        pclk <= ~pclk;
    end else
    begin
        pclk_div <= pclk_div + 1;
    end
end

assign i2s_bclk = cke ? pclk : 0;

always @(negedge pclk)
begin
    if (en)
    begin
        if (tx)
        begin
            i2s_data <= rd_data[fsm[2:0]];
            if (fsm != 0) fsm <= fsm - 1;
            if (fsm == 0 || fsm == 8)
            begin
                rd_sel <= rd_addr == 511;
                rd_addr <= rd_addr + 1;
            end else
            begin
                rd_sel <= 0;
            end
        end else
        begin
            i2s_data <= 0;
        end
        
        if (div == 31)
        begin
            i2s_lrclk <= ~i2s_lrclk;
            tx <= 1;
            cke <= 1;
            fsm <= 15;
            div <= 0;
        end else
        begin
            if (div == 15) tx <= 0;
            if (div == 16) cke <= 0;
            div <= div + 1;
        end
    end
end

endmodule

/*
module i2s_tb();
reg iclk;
initial iclk = 0;
always #1 iclk = ~iclk;

wire sel;
reg en;

wire[8:0] addr;
wire[7:0] data;

wire bclk;
wire lrclk;
wire dout;

initial
begin
    en <= 0;
    #16;
    en <= 1;
    #65536;
end

ram r0(
    .clk(iclk),

    .rd_sel(sel),
    .rd_addr(addr),
    .rd_data(data)
);

i2s i0(
    .iclk(iclk),
    .en(en),

    .rd_sel(sel),
    .rd_addr(addr),
    .rd_data(data),

    .i2s_bclk(bclk),
    .i2s_lrclk(lrclk),
    .i2s_data(dout)
);
endmodule
*/