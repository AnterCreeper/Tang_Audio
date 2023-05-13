module spi_phy(
    input iclk,
    input[7:0] div,

    input wr,
    input[7:0] wr_data,
    
    output reg rd,
    output reg[7:0] rd_data,

    output spi_clk,
    output reg spi_mosi,
    input spi_miso
);

reg en;
reg cke;
reg rs;
reg[7:0] tx;
reg[7:0] rx;

reg pclk;
reg[7:0] pclk_cnt;

initial
begin
    en <= 0;
    rs <= 0;
    tx <= 0;
    rx <= 0;
    
    pclk <= 0;
    pclk_cnt <= 0;
end

always @(posedge iclk or negedge en)
begin
    if (en)
    begin
        if (pclk_cnt != div)
            pclk_cnt <= pclk_cnt + 1;
        else
        begin
            pclk_cnt <= 0;
            pclk <= ~pclk;
        end
    end else
    begin
        pclk_cnt <= 0;
        pclk <= 0;
    end
end

always @(posedge iclk)
begin
    if (rs) begin
        en <= 0;
        rd <= 1;
        rd_data <= {rx[0], rx[1], rx[2], rx[3],
                rx[4], rx[5], rx[6], rx[7]};
        tx <= 0;
    end else 
    begin
        rd <= 0;
        rd_data <= 0;
        if (wr) 
        begin
            en <= 1;
            tx <= {wr_data[0], wr_data[1], wr_data[2], wr_data[3],
                wr_data[4], wr_data[5], wr_data[6], wr_data[7]};
        end
    end
end

reg[3:0] counter;

initial
begin
    cke <= 0;
    counter <= 0;
    spi_mosi <= 1'b1;
end

assign spi_clk = cke ? pclk : 0;

always @(negedge pclk or negedge en)
begin
    if (en)
    begin
        cke <= 1;
        if (counter == 8) begin
            rs <= 1;
        end else
        begin
            spi_mosi <= tx[counter];
        end
    end else
    begin
        cke <= 0;
        rs <= 0;
        spi_mosi <= 1'b1;
    end
end

always @(posedge pclk or negedge en)
begin
    if (en)
    begin
        rx[counter] <= spi_miso;
        counter <= counter + 1;
    end
    else
    begin
        rx <= 0;
        counter <= 4'hf;
    end
end
endmodule

module rom(
    input[11:0] addr,
    output reg[15:0] inst
);

//instr:
//0x0: nop
//0x1: jnz X (if A!=0 set PC=X)
//0x2: js X (if A<0 set PC=X)
//0x2: sub X (A=A-X)
//0x3: mov X (A=X)
//0x4: tx X (transfer X)
//0x5: lt (load *A and transfer)
//0x6: rx (receive and store to A)
//0x7: rs (receive and store to A*)
//0x8: cs (flip CS)
//0x9: val (set valid = 1 and change clock div)
//0xa: hlt (set busy = 0 and stall)

`define nop 4'h0
`define jnz 4'h1
`define js  4'h2
`define sub 4'h3
`define mov 4'h4
`define tx  4'h5
`define lt  4'h6
`define rx  4'h7
`define rs  4'h8
`define cs  4'h9
`define val 4'ha
`define hlt 4'hb

always @(*)
begin
    case(addr)

//clock sync
    12'h00: inst <= {12'h00a, `mov};
    12'h01: inst <= {12'h0ff, `tx};  //A
    12'h02: inst <= {12'h001, `sub};
    12'h03: inst <= {12'h001, `jnz}; //jnz A

//CMD0
    12'h04: inst <= {12'h000, `cs};
    12'h05: inst <= {12'h040, `tx};
    12'h06: inst <= {12'h000, `tx};
    12'h07: inst <= {12'h000, `tx};
    12'h08: inst <= {12'h000, `tx};
    12'h09: inst <= {12'h000, `tx};
    12'h0a: inst <= {12'h095, `tx};
    12'h0b: inst <= {12'h000, `rx};  //B
    12'h0c: inst <= {12'h001, `sub};
    12'h0d: inst <= {12'h00b, `jnz}; //jnz B
    12'h0e: inst <= {12'h000, `cs};
    12'h0f: inst <= {12'h0ff, `tx};

//CMD8
    12'h10: inst <= {12'h000 ,`cs};
    12'h11: inst <= {12'h048 ,`tx};
    12'h12: inst <= {12'h000 ,`tx};
    12'h13: inst <= {12'h000 ,`tx};
    12'h14: inst <= {12'h001 ,`tx};
    12'h15: inst <= {12'h0aa ,`tx};
    12'h16: inst <= {12'h087 ,`tx};
    12'h17: inst <= {12'h000, `rx};  //C
    12'h18: inst <= {12'h001, `sub};
    12'h19: inst <= {12'h017, `jnz}; //jnz C
    12'h1a: inst <= {12'h0ff ,`tx};
    12'h1b: inst <= {12'h0ff ,`tx};
    12'h1c: inst <= {12'h0ff ,`tx};
    12'h1d: inst <= {12'h0ff ,`tx};  //ignore them, since that if it doesn't support, but what we can do?
    12'h1e: inst <= {12'h000 ,`cs};
    12'h1f: inst <= {12'h0ff ,`tx};

//CMD55
    12'h20: inst <= {12'h000 ,`cs};  //D
    12'h21: inst <= {12'h077 ,`tx};
    12'h22: inst <= {12'h000 ,`tx};
    12'h23: inst <= {12'h000 ,`tx};
    12'h24: inst <= {12'h000 ,`tx};
    12'h25: inst <= {12'h000 ,`tx};
    12'h26: inst <= {12'h065 ,`tx};
    12'h27: inst <= {12'h000, `rx};  //E
    12'h28: inst <= {12'h001, `sub};
    12'h29: inst <= {12'h027, `jnz}; //jnz E
    12'h2a: inst <= {12'h000 ,`cs};
    12'h2b: inst <= {12'h0ff ,`tx};

//ACMD41
    12'h2c: inst <= {12'h000 ,`cs};
    12'h2d: inst <= {12'h069 ,`tx};
    12'h2e: inst <= {12'h040 ,`tx};
    12'h2f: inst <= {12'h000 ,`tx};
    12'h30: inst <= {12'h000 ,`tx};
    12'h31: inst <= {12'h000 ,`tx};
    12'h32: inst <= {12'h077 ,`tx};
    12'h33: inst <= {12'h000 ,`rx};  //F
    12'h34: inst <= {12'h033 ,`js};  //js F
    12'h35: inst <= {12'h0ff ,`tx};
    12'h36: inst <= {12'h0ff ,`tx};
    12'h37: inst <= {12'h0ff ,`tx};
    12'h38: inst <= {12'h0ff ,`tx};  //ignore them, since that if it doesn't support, but what we can do?
    12'h39: inst <= {12'h000 ,`cs};
    12'h3a: inst <= {12'h0ff ,`tx};
    12'h3b: inst <= {12'h020 ,`jnz}; //jnz D

//set valid flag
    12'h3c: inst <= {12'h000 ,`val};

//read, CMD17
    12'h3d: inst <= {12'h000 ,`hlt}; //G
    12'h3e: inst <= {12'h000 ,`cs};
    12'h3f: inst <= {12'h051 ,`tx};
    12'h40: inst <= {12'h004 ,`mov};
    12'h41: inst <= {12'h001 ,`sub}; //H
    12'h42: inst <= {12'h000 ,`lt};
    12'h43: inst <= {12'h041 ,`jnz}; //jnz H
    12'h44: inst <= {12'h0ff ,`tx};
    12'h45: inst <= {12'h000 ,`rx};  //I
    12'h46: inst <= {12'h045 ,`jnz}; //jnz I
    12'h47: inst <= {12'h000 ,`rx};  //J
    12'h48: inst <= {12'hffe ,`sub};
    12'h49: inst <= {12'h047 ,`jnz}; //jnz J
    12'h4a: inst <= {12'h200 ,`mov};
    12'h4b: inst <= {12'h001 ,`sub}; //K
    12'h4c: inst <= {12'h000 ,`rs};
    12'h4d: inst <= {12'h04b ,`jnz}; //jnz K
    12'h4e: inst <= {12'h0ff ,`tx};
    12'h4f: inst <= {12'h0ff ,`tx};
    12'h50: inst <= {12'h000 ,`cs};
    12'h51: inst <= {12'h0ff ,`tx};
    12'h52: inst <= {12'h0ff ,`mov};
    12'h53: inst <= {12'h03d ,`jnz}; //jnz G

    default: inst <= 16'h0000;
    endcase
end

endmodule

`define SPI_FAST_DIV 3
`define SPI_SLOW_DIV 128

module sdhci(
    input iclk,
    input done,

    output reg valid,
    output reg busy,

    input rd,
    input[31:0] rd_addr,
    
    output reg wr,
    output reg[8:0] wr_addr,
    output reg[7:0] wr_data,
    
    output reg spi_cs,
    output spi_clk,
    output spi_mosi,
    input spi_miso,

    output[5:0] test
);

initial
begin
    valid <= 0;
    busy <= 1;
    wr <= 0;
    wr_addr <= 0;
    wr_data <= 0;
    
    spi_cs <= 1'b1;
end

reg[7:0] div;

reg tx;
reg[7:0] tx_data;
wire rx;
wire[7:0] rx_data;

initial
begin
    div <= `SPI_SLOW_DIV;
    tx <= 0;
    tx_data <= 0;
end

spi_phy io_sd(
    .iclk(iclk),
    .div(div),

    .wr(tx),
    .wr_data(tx_data),
    
    .rd(rx),
    .rd_data(rx_data),

    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso)
);

reg[1:0] fsm;

reg[11:0] pc;
reg[11:0] A;
reg[7:0] B;

wire[15:0] inst;
//15:4(da) 3:0(op)
reg[7:0] dst[3:0];

reg[1:0] ls_type;

assign test = pc[5:0];

initial begin
    fsm <= 0;
    pc <= 0;
    A <= 0;
    B <= 0;
    ls_type <= 0;
    dst[0] <= 0;
    dst[1] <= 0;
    dst[2] <= 0;
    dst[3] <= 0;
end

rom mm_sd(
    .addr(pc),
    .inst(inst)
);

always @(posedge iclk)
begin
    if(done)
begin
    if(busy == 0) begin
        if (rd) begin
            busy <= 1;
            dst[3] <= rd_addr[31:24];
            dst[2] <= rd_addr[23:16];
            dst[1] <= rd_addr[15:8];
            dst[0] <= rd_addr[7:0];
        end
    end else
    begin
        if (fsm == 0)
        begin
            wr <= 0;
            wr_addr <= 0;
            case(inst[3:0])
            `jnz: if (A != 0) pc <= inst[15:4]; else pc <= pc + 1;
            `js:  if (A[11])  pc <= inst[15:4]; else pc <= pc + 1;
            `sub: begin A <= A - inst[15:4]; pc <= pc + 1; end
            `mov: begin A <= inst[15:4]; pc <= pc + 1; end
            `tx:  begin fsm <= 1; ls_type <= 3'b00; end
            `lt:  begin fsm <= 1; ls_type <= 3'b01; end
            `rx:  begin fsm <= 1; ls_type <= 3'b10; end
            `rs:  begin fsm <= 1; ls_type <= 3'b11; end
            `cs:  begin spi_cs <= ~spi_cs; pc <= pc + 1; end
            `val: begin valid <= 1; div <= `SPI_FAST_DIV; pc <= pc + 1; end
            `hlt: begin busy <= 0; pc <= pc + 1; end
            default: pc <= pc + 1;
            endcase
        end else
        begin
            case(fsm)
            1: //load
            begin
                fsm <= 2;
                tx <= 1;
                case(ls_type[1:0])
                2'b00: tx_data <= inst[11:4];
                2'b01: tx_data <= dst[A[1:0]];
                default: tx_data <= 8'hFF;
                endcase
            end
            2: //tx & rx
            begin
                tx <= 0;
                tx_data <= 0;
                if (rx)
                begin
                    fsm <= 3;
                    B <= rx_data;
                end
            end
            3: //store
            begin
                fsm <= 0;
                pc <= pc + 1;
                case(ls_type[1:0])
                2'b10:
                begin
                    A <= {{4{B[7]}}, B};
                end
                2'b11:
                begin
                    wr <= 1;
                    wr_addr <= ~A;
                    wr_data <= B;
                end
                endcase
            end
            endcase
        end
    end
end
end

endmodule

module ram(
    input clk,
    input done,

    input wr,
    input[8:0] wr_addr,
    input[7:0] wr_data,
    
    input rd_sel,
    input[8:0] rd_addr,
    output[7:0] rd_data
);

reg sel;

initial
begin
    sel <= 0;
end


always @(posedge rd_sel)
begin
    sel <= ~sel;
end

wire[8:0] addr0, addr1;
wire[7:0] rd_data0, rd_data1;

assign addr0 = sel ? rd_addr : wr_addr;
assign addr1 = sel ? wr_addr : rd_addr;

assign rd_data = sel ? rd_data0 : rd_data1;

wire wr0, wr1;
wire[7:0] wr_data0, wr_data1;

assign wr0 = sel ? 0 : wr;
assign wr1 = sel ? wr : 0;

assign wr_data0 = sel ? 0 : wr_data;
assign wr_data1 = sel ? wr_data : 0;

Gowin_SP data0(
    .dout(rd_data0), //output [7:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(done), //input ce
    .reset(1'b0), //input reset
    .wre(wr0), //input wre
    .ad(addr0), //input [8:0] ad
    .din(wr_data0) //input [7:0] din
);

Gowin_SP data1(
    .dout(rd_data1), //output [7:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(done), //input ce
    .reset(1'b0), //input reset
    .wre(wr1), //input wre
    .ad(addr1), //input [8:0] ad
    .din(wr_data1) //input [7:0] din
);

/*
blk_mem_gen_0 data0(
    .clka(clk),
    .ena(done),
    .wea(wr0),
    .addra(addr0),
    .dina(wr_data0),
    .douta(rd_data0)
);

blk_mem_gen_0 data1(
    .clka(clk),
    .ena(done),
    .wea(wr1),
    .addra(addr1),
    .dina(wr_data1),
    .douta(rd_data1)
);
*/

/*
reg[7:0] data[1:0][511:0];

always @(posedge clk)
begin
    if (done)
    begin
        if(wr) data[sel][wr_addr] <= wr_data;
        rd_data <= data[~sel][rd_addr];
    end
end
*/
endmodule

module audio(
    input clk_27,
    input iclk,

    output busy,
    output done,
    output valid,
    output test1,
    output test2,
    output test3,

    output io_spi_cs,
    output io_spi_clk,
    output io_spi_mosi,
    input io_spi_miso,
    
    output io_i2s_bclk,
    output io_i2s_lrclk,
    output io_i2s_data,
    
    output io_i2c_scl,
    inout io_i2c_sda
);

wire valid;

wire wr;
wire[8:0] wr_addr;
wire[7:0] wr_data;

reg fetch;
reg[23:0] fetch_addr;

wire rd_sel;
wire[8:0] rd_addr;
wire[7:0] rd_data;

assign test2 = io_spi_cs;
assign test3 = io_spi_miso;

initial
begin
    fetch <= 0;
    fetch_addr <= 24'hffffff;
end

i2c_hci i2c0(
    .iCLK(clk_27),
    .I2C_SCLK(io_i2c_scl),
    .I2C_SDAT(io_i2c_sda),
    .done(done)
);

ram shared_ram(
    .clk(iclk),
    .done(done),

    .wr(wr),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    
    .rd_sel(rd_sel),
    .rd_addr(rd_addr),
    .rd_data(rd_data)
);

sdhci io_sdhci(
    .iclk(iclk),
    .done(done),

    .valid(valid),
    .busy(busy),

    .rd(fetch),
    .rd_addr({8'h0, fetch_addr}),
    
    .wr(wr),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    
    .spi_cs(io_spi_cs),
    .spi_clk(io_spi_clk),
    .spi_mosi(io_spi_mosi),
    .spi_miso(io_spi_miso)
);

i2s io_i2s(
    .iclk(iclk),
    .en(valid),

    .rd_sel(rd_sel),
    .rd_addr(rd_addr),
    .rd_data(rd_data),

    .i2s_bclk(io_i2s_bclk),
    .i2s_lrclk(io_i2s_lrclk),
    .i2s_data(io_i2s_data),
    .test(test1)
);

reg fetch_rst;
initial fetch_rst = 0;

always @(posedge iclk)
begin
    if(rd_sel) begin
        fetch_rst <= 1;
        if (fetch_rst)
        begin
            fetch <= 0;
        end else
        begin
            fetch <= 1;
            fetch_addr <= fetch_addr + 1;
        end
    end else
    begin
        fetch_rst <= 0;
        fetch <= 0;
    end
end
endmodule