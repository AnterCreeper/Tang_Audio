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
    if (!en)
    begin
        pclk_cnt <= 0;
        pclk <= 0;
    end else
    begin
        if (pclk_cnt != div)
            pclk_cnt <= pclk_cnt + 1;
        else
        begin
            pclk_cnt <= 0;
            pclk <= ~pclk;
        end
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
    spi_mosi <= 1'b1;
end

assign spi_clk = cke ? pclk : 0;

always @(negedge pclk or negedge en)
begin
    if (!en)
    begin
        cke <= 0;
        rs <= 0;
        spi_mosi <= 1'b1;
    end else
    begin
        cke <= 1;
        if (counter == 8) begin
            rs <= 1;
        end else
        begin
            spi_mosi <= tx[counter];
        end
    end
end

always @(posedge pclk or negedge en)
begin
    if (!en)
    begin
        rx <= 0;
        counter <= 4'hf;
    end else
    begin
        rx[counter] <= spi_miso;
        counter <= counter + 1;
    end
end
endmodule

module rom(
    input[11:0] addr,
    output reg[15:0] inst
);

//instr:
`define jnz 4'h0 //jnz imm (if A!=0 set PC=imm)
`define js  4'h1 //js imm (if A<0 set PC=imm)
`define add 4'h2 //add imm (A=A+imm)
`define mov 4'h3 //mov imm (A=imm)
`define tx  4'h4 //tx (transfer imm)
`define ta  4'h5 //ta (transfer A)
`define lt  4'h6 //lt (load from %A and transfer)
`define ra  4'h7 //ra (receive to A)
`define rs  4'h8 //rs (receive and store to %A)
`define cs  4'h9 //cs (flip CS)
`define stb 4'ha //stb imm (A <= A | imm)
`define rsb 4'hb //rsb imm (A <= A & (~imm))
`define wsr 4'hc //wsr imm (reg[imm] <= A)
`define rsr 4'hd //rsr imm (A <= reg[imm])
`define ccd 4'he //ccd (change clock div)
`define hlt 4'hf //hlt (set busy = 0 and wait for request)

always @(*)
begin
    case(addr)

//clock sync
    12'h00: inst <= {12'h00a, `mov};
    12'h01: inst <= {12'h0ff, `tx};  //L0
    12'h02: inst <= {12'hfff, `add};
    12'h03: inst <= {12'h001, `jnz}; //jnz L0

//cmd0
    12'h04: inst <= {12'h000, `cs};
    12'h05: inst <= {12'h040, `tx};
    12'h06: inst <= {12'h000, `tx};
    12'h07: inst <= {12'h000, `tx};
    12'h08: inst <= {12'h000, `tx};
    12'h09: inst <= {12'h000, `tx};
    12'h0a: inst <= {12'h095, `tx};
    12'h0b: inst <= {12'h000, `ra};  //L1
    12'h0c: inst <= {12'hfff, `add};
    12'h0d: inst <= {12'h00b, `jnz}; //jnz L1
    12'h0e: inst <= {12'h000, `cs};
    12'h0f: inst <= {12'h0ff, `tx};

//cmd8
    12'h10: inst <= {12'h000, `cs};
    12'h11: inst <= {12'h048, `tx};
    12'h12: inst <= {12'h000, `tx};
    12'h13: inst <= {12'h000, `tx};
    12'h14: inst <= {12'h001, `tx};
    12'h15: inst <= {12'h0aa, `tx};
    12'h16: inst <= {12'h087, `tx};
    12'h17: inst <= {12'h000, `ra};  //L2
    12'h18: inst <= {12'hfff, `add};
    12'h19: inst <= {12'h017, `jnz}; //jnz L2
    12'h1a: inst <= {12'h0ff, `tx};
    12'h1b: inst <= {12'h0ff, `tx};
    12'h1c: inst <= {12'h0ff, `tx};
    12'h1d: inst <= {12'h0ff, `tx};  //ignore them.
    12'h1e: inst <= {12'h000, `cs};
    12'h1f: inst <= {12'h0ff, `tx};

//cmd55
    12'h20: inst <= {12'h000, `cs};  //L3
    12'h21: inst <= {12'h077, `tx};
    12'h22: inst <= {12'h000, `tx};
    12'h23: inst <= {12'h000, `tx};
    12'h24: inst <= {12'h000, `tx};
    12'h25: inst <= {12'h000, `tx};
    12'h26: inst <= {12'h065, `tx};
    12'h27: inst <= {12'h000, `ra};  //L4
    12'h28: inst <= {12'hfff, `add};
    12'h29: inst <= {12'h027, `jnz}; //jnz L4
    12'h2a: inst <= {12'h000, `cs};
    12'h2b: inst <= {12'h0ff, `tx};
//acmd41
    12'h2c: inst <= {12'h000, `cs};
    12'h2d: inst <= {12'h069, `tx};
    12'h2e: inst <= {12'h040, `tx};
    12'h2f: inst <= {12'h000, `tx};
    12'h30: inst <= {12'h000, `tx};
    12'h31: inst <= {12'h000, `tx};
    12'h32: inst <= {12'h077, `tx};
    12'h33: inst <= {12'h000, `ra};  //L5
    12'h34: inst <= {12'h033, `js};  //js L5
    12'h35: inst <= {12'h0ff, `tx};
    12'h36: inst <= {12'h0ff, `tx};
    12'h37: inst <= {12'h0ff, `tx};
    12'h38: inst <= {12'h0ff, `tx};  //ignore them.
    12'h39: inst <= {12'h000, `cs};
    12'h3a: inst <= {12'h0ff, `tx};
    12'h3b: inst <= {12'h020, `jnz}; //jnz L3

//set clock divider and status register
    12'h3c: inst <= {12'h000, `ccd};
    12'h3d: inst <= {12'h001, `mov};
    12'h3e: inst <= {12'h004, `wsr};
    
//read, send cmd17
    12'h3f: inst <= {12'h000 ,`cs};  //L6
    12'h40: inst <= {12'h051 ,`tx};
    12'h41: inst <= {12'h000 ,`rsr};
    12'h42: inst <= {12'h000 ,`ta};
    12'h43: inst <= {12'h001 ,`rsr};
    12'h44: inst <= {12'h000 ,`ta};
    12'h45: inst <= {12'h002 ,`rsr};
    12'h46: inst <= {12'h000 ,`ta};
    12'h47: inst <= {12'h003 ,`rsr};
    12'h48: inst <= {12'h000 ,`ta};
    12'h49: inst <= {12'h0ff ,`tx};
    12'h4a: inst <= {12'h000 ,`ra};  //L7
    12'h4b: inst <= {12'h04a ,`jnz}; //jnz L7
    12'h4c: inst <= {12'h000 ,`ra};  //L8
    12'h4d: inst <= {12'h002 ,`add};
    12'h4e: inst <= {12'h04c ,`jnz}; //jnz L8
    12'h4f: inst <= {12'h200 ,`mov};
    12'h50: inst <= {12'hfff ,`add}; //L9
    12'h51: inst <= {12'h000 ,`rs};
    12'h52: inst <= {12'h050 ,`jnz}; //jnz L9
    12'h53: inst <= {12'h0ff ,`tx};
    12'h54: inst <= {12'h0ff ,`tx};
    12'h55: inst <= {12'h000 ,`cs};
    12'h56: inst <= {12'h0ff ,`tx};

//halt and loop
    12'h57: inst <= {12'h000 ,`hlt};
    12'h58: inst <= {12'hfff ,`mov};
    12'h59: inst <= {12'h03f ,`jnz}; //jnz L6
    
    default: 
            inst <= {12'h000 ,`add};
            
    endcase
end

endmodule

`define SPI_FAST_DIV 3
`define SPI_SLOW_DIV 128

module sdhci(
    input iclk,
    input done,
    
    output valid,
    output reg busy,

    input rd,
    input[31:0] rd_addr,
    
    output reg wr,
    output reg[8:0] wr_addr,
    output reg[7:0] wr_data,
    
    output reg spi_cs,
    output spi_clk,
    output spi_mosi,
    input spi_miso
);

initial
begin
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
wire[11:0] imm;
wire[3:0] opcode;
assign imm = inst[15:4];
assign opcode = inst[3:0];

reg[2:0] ls_type;
reg[7:0] sr[7:0];
//sr[3] sr[2] sr[1] sr[0] maddress
//sr[4] mstatus

assign valid = sr[4][0];

initial begin
    fsm <= 0;
    pc <= 0;
    A <= 0;
    B <= 0;
    ls_type <= 0;
    sr[0] <= 0;
    sr[1] <= 0;
    sr[2] <= 0;
    sr[3] <= 0;
    sr[4] <= 0;
end

rom mm_sd(
    .addr(pc),
    .inst(inst)
);

always @(posedge iclk)
begin
    if(done)
    begin
    if(!busy) begin
        if (rd) begin
            busy <= 1;
            sr[0] <= rd_addr[31:24];
            sr[1] <= rd_addr[23:16];
            sr[2] <= rd_addr[15:8];
            sr[3] <= rd_addr[7:0];
        end
    end else
    begin
        if (fsm == 0)
        begin
            wr <= 0;
            wr_addr <= 0;
            case(opcode)
            `jnz: if (A != 0) pc <= imm; else pc <= pc + 1;
            `js:  if (A[11])  pc <= imm; else pc <= pc + 1;
            `add: begin A <= A + imm; pc <= pc + 1; end
            `mov: begin A <= imm; pc <= pc + 1; end
            `tx:  begin fsm <= 1; ls_type <= 3'b000; end
            `ta:  begin fsm <= 1; ls_type <= 3'b001; end
            `lt:  begin fsm <= 1; ls_type <= 3'b010; end
            `ra:  begin fsm <= 1; ls_type <= 3'b101; end
            `rs:  begin fsm <= 1; ls_type <= 3'b110; end
            `cs:  begin spi_cs <= ~spi_cs; pc <= pc + 1; end
            `stb: begin A <= A | imm; pc <= pc + 1; end
            `rsb: begin A <= A & (~imm); pc <= pc + 1; end
            `wsr: begin sr[imm] <= A; pc <= pc + 1; end
            `rsr: begin A <= sr[imm]; pc <= pc + 1; end
            `ccd: begin div <= `SPI_FAST_DIV; pc <= pc + 1; end
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
                case(ls_type[2:0])
                3'b000: tx_data <= imm[7:0];
                3'b001: tx_data <= A[7:0];
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
                case(ls_type[2:0])
                3'b101:
                begin
                    A <= {{4{B[7]}}, B};
                end
                3'b110:
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
    input en,

    input wr,
    input[8:0] wr_addr,
    input[7:0] wr_data,
    
    input rd_sel,
    input[8:0] rd_addr,
    output[7:0] rd_data
);

reg sel;

always @(posedge rd_sel)
begin
    sel <= ~sel;
end

wire[8:0] addr0, addr1;
wire[7:0] rd_data0, rd_data1;

wire[8:0] rd_addr_wrap; //swap endian.
assign rd_addr_wrap = {rd_addr[8:1], ~rd_addr[0]};
//assign rd_addr_wrap = rd_addr;

assign addr0 = sel ? rd_addr_wrap : wr_addr;
assign addr1 = sel ? wr_addr : rd_addr_wrap;

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
    .ce(en), //input ce
    .reset(1'b0), //input reset
    .wre(wr0), //input wre
    .ad(addr0), //input [8:0] ad
    .din(wr_data0) //input [7:0] din
);

Gowin_SP data1(
    .dout(rd_data1), //output [7:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(en), //input ce
    .reset(1'b0), //input reset
    .wre(wr1), //input wre
    .ad(addr1), //input [8:0] ad
    .din(wr_data1) //input [7:0] din
);

endmodule

module ram_list(
    input clk,
    input en,

    input wr,
    input[8:0] wr_addr,
    input[7:0] wr_data,
    
    input[6:0] rd_addr,
    output[31:0] rd_data
);

Gowin_SDPB data(
        .dout(rd_data), //output [31:0] dout
        .clka(clk), //input clka
        .cea(wr), //input cea
        .reseta(1'b0), //input reseta
        .clkb(clk), //input clkb
        .ceb(en), //input ceb
        .resetb(1'b0), //input resetb
        .oce(1'b1), //input oce
        .ada(wr_addr), //input [8:0] ada
        .din(wr_data), //input [7:0] din
        .adb(rd_addr) //input [6:0] adb
);

/*
wire[6:0] addr;
wire[31:0] rd_data;
wire[7:0] rd_data0, rd_data1, rd_data2, rd_data3;
wire wr0, wr1, wr2, wr3;

assign addr = wr ? wr_addr[8:2] : rd_addr;
assign rd_data = wr ? 32'b0 : {rd_data3, rd_data2, rd_data1, rd_data0};

assign wr0 = wr ? wr_addr[1:0] == 0 : 0;
assign wr1 = wr ? wr_addr[1:0] == 1 : 0;
assign wr2 = wr ? wr_addr[1:0] == 2 : 0;
assign wr3 = wr ? wr_addr[1:0] == 3 : 0;

Gowin_SP1 data0(
    .dout(rd_data0), //output [7:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(en), //input ce
    .reset(1'b0), //input reset
    .wre(wr0), //input wre
    .ad(addr), //input [8:0] ad
    .din(wr_data) //input [7:0] din
);

Gowin_SP1 data1(
    .dout(rd_data1), //output [7:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(en), //input ce
    .reset(1'b0), //input reset
    .wre(wr1), //input wre
    .ad(addr), //input [8:0] ad
    .din(wr_data) //input [7:0] din
);

Gowin_SP1 data2(
    .dout(rd_data2), //output [7:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(en), //input ce
    .reset(1'b0), //input reset
    .wre(wr2), //input wre
    .ad(addr), //input [8:0] ad
    .din(wr_data) //input [7:0] din
);

Gowin_SP1 data3(
    .dout(rd_data3), //output [7:0] dout
    .clk(clk), //input clk
    .oce(1'b1), //input oce
    .ce(en), //input ce
    .reset(1'b0), //input reset
    .wre(wr3), //input wre
    .ad(addr), //input [8:0] ad
    .din(wr_data) //input [7:0] din
);
*/

endmodule

module audio(
//internal
    input clk_27,
    output busy,
    output done,
    output valid,
    output idle,
    output irq_n,
    output irq_s,

//CLK
    input iclk,

//GPIO
    input btn_s,
    input btn_n,
    input msel,
    input interrupt,

//SPI
    output io_spi_cs,
    output io_spi_clk,
    output io_spi_mosi,
    input io_spi_miso,

//I2S
    output io_i2s_bclk,
    output io_i2s_lrclk,
    output io_i2s_data,

//I2C
    output io_i2c_scl,
    inout io_i2c_sda,

//DMIC
    input dmic_clk,
    input dmic_data,

//USB
    input ftdi_clk,
    input ftdi_rxf_n,
    input ftdi_txe_n,

    output ftdi_oe_n,
    output ftdi_rd_n,
    output ftdi_wr_n,

    inout[7:0] ftdi_data
);

wire valid;

wire wr;
wire[8:0] wr_addr;
wire[7:0] wr_data;

wire rd_sel;
wire[8:0] rd_addr;
wire[7:0] rd_data;

reg idle;

reg fetch;
reg[31:0] fetch_addr;

initial
begin
    fetch <= 0;
    fetch_addr <= 32'hffffffff;
end

i2c_hci i2c0(
    .iCLK(clk_27),
    .I2C_SCLK(io_i2c_scl),
    .I2C_SDAT(io_i2c_sda),
    .done(done)
);

reg init_done;
initial init_done = 0;

wire ram_wr, list_wr;
wire[8:0] ram_wr_addr, list_wr_addr;
wire[7:0] ram_wr_data, list_wr_data;

assign ram_wr  = init_done ? wr : 0;
assign ram_wr_addr = init_done ? wr_addr : 0;
assign ram_wr_data = init_done ? wr_data : 0;

assign list_wr  = init_done ? 0 : wr;
assign list_wr_addr = init_done ? 0 : wr_addr;
assign list_wr_data = init_done ? 0 : wr_data;

reg[6:0] list_rd_addr;
initial list_rd_addr = 0;
wire[31:0] list_rd_data;

ram shared_ram(
    .clk(iclk),
    .en(init_done),

    .wr(ram_wr),
    .wr_addr(ram_wr_addr),
    .wr_data(ram_wr_data),
    
    .rd_sel(rd_sel),
    .rd_addr(rd_addr),
    .rd_data(rd_data)
);

ram_list l0(
    .clk(iclk),
    .en(valid),

    .wr(list_wr),
    .wr_addr(list_wr_addr),
    .wr_data(list_wr_data),
    
    .rd_addr(list_rd_addr),
    .rd_data(list_rd_data)
);

sdhci io_sdhci(
    .iclk(iclk),
    .done(done),

    .valid(valid),
    .busy(busy),

    .rd(fetch),
    .rd_addr(fetch_addr),
    
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
    .en(init_done && !idle),

    .rd_sel(rd_sel),
    .rd_addr(rd_addr),
    .rd_data(rd_data),

    .i2s_bclk(io_i2s_bclk),
    .i2s_lrclk(io_i2s_lrclk),
    .i2s_data(io_i2s_data)
);

reg fetch_rst;
initial fetch_rst = 0;

reg irq_n, irq_s;

reg irq_n_rst;
initial irq_n_rst = 0;

reg irq_s_rst;
initial irq_s_rst = 0;

always @(posedge iclk or negedge btn_n)
begin
    if (!btn_n)
    begin
        irq_n <= 1;
    end else
    begin
        if (irq_n_rst) irq_n <= 0;
    end
end

always @(posedge iclk or negedge btn_s)
begin
    if (!btn_s)
    begin
        irq_s <= 1;
    end else
    begin
        if (irq_s_rst) irq_s <= 0;
    end
end

reg idle_set_call, idle_set_flag;
initial 
begin
    idle_set_call = 0;
    idle_set_flag = 0;
end

always @(posedge iclk)
begin
    if(rd_sel) begin
        fetch_rst <= 1;
        if (fetch_rst)
        begin
            fetch <= 0;
            idle_set_call <= 0;
        end else
        begin
            fetch <= 1;
            if (irq_n_rst && !irq_n)
            begin
                irq_n_rst <= 0;
                if (!msel) 
                    list_rd_addr <= list_rd_addr + 1;
                else 
                    list_rd_addr <= {~list_rd_addr[5:0], list_rd_addr[6] ^ list_rd_addr[5]}; //Pseudo Random
                fetch_addr <= list_rd_data;
            end else
            begin
                fetch_addr <= fetch_addr + 1;
            end
            if (irq_n) irq_n_rst <= 1;
            if (idle_set_flag) idle_set_call <= 1;
        end
    end else
    begin
        fetch_rst <= 0;
        fetch <= 0;
    end
end

reg[25:0] idle_cnt;

always @(posedge iclk or posedge idle_set_call)
begin
    if (idle_set_call)
    begin
        idle <= 1;
        idle_set_flag <= 0;
    end else
    begin
        if (idle_cnt[25])
        begin
            idle_cnt <= 0;
            if (irq_s) irq_s_rst <= 1;
        end else
        begin
            idle_cnt <= idle_cnt + 1;
        end
        if (irq_s_rst && !irq_s) 
        begin
            if (idle) idle <= 0;
            else idle_set_flag <= 1;
            irq_s_rst <= 0;
        end
    end
end

always @(posedge iclk)
begin
    if (!busy) init_done <= 1;
end

endmodule
