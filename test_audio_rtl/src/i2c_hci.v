module i2c_hci (	//	Host Side
    iCLK,
    done,
    I2C_SCLK,
    I2C_SDAT
);

//	Host Side
input		iCLK;
//	I2C Side
output		I2C_SCLK;
inout		I2C_SDAT;

output done;

//	Internal Registers/Wires
reg	[8:0]	mI2C_CLK_DIV;
reg	[23:0]	mI2C_DATA;

reg			mI2C_CTRL_CLK;
reg			mI2C_GO;
wire		mI2C_END;
wire		mI2C_ACK;

reg	[23:0]	LUT_DATA;
reg	[7:0]	LUT_INDEX;

reg	[3:0]	mSetup_ST;

reg done;

//	Clock Setting
parameter	CLK_Freq	=	27000000;	//	27	MHz
parameter	I2C_Freq	=	100000;		//	100	KHz
//	LUT Data Number
parameter	LUT_SIZE	=	69;

initial begin
    done <= 0;
    mI2C_CTRL_CLK	<=	0;
    mI2C_CLK_DIV	<=	0;
    LUT_INDEX	<=	0;
    mSetup_ST	<=	0;
    mI2C_GO		<=	0;
end

always @(posedge iCLK)
begin
    if (mI2C_CLK_DIV == 270)
    begin
        mI2C_CLK_DIV	<=	0;
        mI2C_CTRL_CLK	<= ~mI2C_CTRL_CLK;
    end
    else
    begin
        mI2C_CLK_DIV	<=	mI2C_CLK_DIV+1;
    end
end

I2C_Controller u0 (
    .CLOCK(mI2C_CTRL_CLK),          //	Controller Work Clock
    .I2C_SCLK(I2C_SCLK),			//	I2C CLOCK
    .I2C_SDAT(I2C_SDAT),			//	I2C DATA
    .I2C_DATA(mI2C_DATA),			//	DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
    .GO(mI2C_GO),					//	GO transfor
    .END(mI2C_END),					//	END transfor 
    .ACK(mI2C_ACK)					//	ACK
);

always @(posedge mI2C_CTRL_CLK)
begin
    if (LUT_INDEX < LUT_SIZE)
    begin
        case(mSetup_ST)
        0:
        begin
            mI2C_DATA	<=	LUT_DATA;
            mI2C_GO		<=	1;
            mSetup_ST	<=	1;
        end
        1:
        begin
            if (mI2C_END)
            begin
                if(!mI2C_ACK)
                    mSetup_ST	<=	2;
                else
                    mSetup_ST	<=	0;
                mI2C_GO		<=	0;
            end
        end
        2:
        begin
            LUT_INDEX	<=	LUT_INDEX + 1;
            mSetup_ST	<=	0;
        end
        endcase
    end
    else
    begin
        done <= 1;
        LUT_INDEX <= LUT_INDEX;
    end
end

always @(*)
begin
	case(LUT_INDEX)
	//	Config Data
	0	:	LUT_DATA	<=	24'h200227;
	1	:	LUT_DATA	<=	24'h2003e8;
	2	:	LUT_DATA	<=	24'h200410;
	3	:	LUT_DATA	<=	24'h200749;
	4	:	LUT_DATA	<=	24'h200880;
    5   :   LUT_DATA    <=  24'h200910;
	6	:	LUT_DATA	<=	24'h200a08;
    7	:	LUT_DATA	<=	24'hc00253;
	8	:	LUT_DATA	<=	24'hc00300;
	9	:	LUT_DATA	<=	24'hc00420;
	10	:	LUT_DATA	<=	24'hc00700;
	11	:	LUT_DATA	<=	24'hc00f00;
	12	:	LUT_DATA	<=	24'hc0100f;
	13	:	LUT_DATA	<=	24'hc0110d;
	14	:	LUT_DATA	<=	24'hc0120e;
	15	:	LUT_DATA	<=	24'hc0138c;
	16	:	LUT_DATA	<=	24'hc0148c;
	17	:	LUT_DATA	<=	24'hc0158c;
	18	:	LUT_DATA	<=	24'hc0168c;
	19	:	LUT_DATA	<=	24'hc0178c;
	20	:	LUT_DATA	<=	24'hc01a00;
	21	:	LUT_DATA	<=	24'hc01b01;
	22	:	LUT_DATA	<=	24'hc01c00;
	23	:	LUT_DATA	<=	24'hc01d10;
	24	:	LUT_DATA	<=	24'hc01e00;
	25	:	LUT_DATA	<=	24'hc01f00;
	26	:	LUT_DATA	<=	24'hc02000;
	27	:	LUT_DATA	<=	24'hc02100;
	28	:	LUT_DATA	<=	24'hc02a00;
	29	:	LUT_DATA	<=	24'hc02b01;
	30	:	LUT_DATA	<=	24'hc02c00;
	31	:	LUT_DATA	<=	24'hc02d8e;
	32	:	LUT_DATA	<=	24'hc02e00;
	33	:	LUT_DATA	<=	24'hc02f00;
	34	:	LUT_DATA	<=	24'hc03000;
	35	:	LUT_DATA	<=	24'hc03100;
	36	:	LUT_DATA	<=	24'hc03200;
	37	:	LUT_DATA	<=	24'hc03301;
	38	:	LUT_DATA	<=	24'hc03400;
	39	:	LUT_DATA	<=	24'hc03522;
	40	:	LUT_DATA	<=	24'hc03600;
	41	:	LUT_DATA	<=	24'hc03700;
	42	:	LUT_DATA	<=	24'hc03800;
	43	:	LUT_DATA	<=	24'hc03900;
	44	:	LUT_DATA	<=	24'hc03a00;
	45	:	LUT_DATA	<=	24'hc03b01;
	46	:	LUT_DATA	<=	24'hc03c00;
	47	:	LUT_DATA	<=	24'hc03d07;
	48	:	LUT_DATA	<=	24'hc03e00;
	49	:	LUT_DATA	<=	24'hc03f00;
	50	:	LUT_DATA	<=	24'hc04000;
	51	:	LUT_DATA	<=	24'hc04100;
	52	:	LUT_DATA	<=	24'hc05a00;
	53	:	LUT_DATA	<=	24'hc05b00;
	54	:	LUT_DATA	<=	24'hc09500;
	55	:	LUT_DATA	<=	24'hc09600;
	56	:	LUT_DATA	<=	24'hc09700;
	57	:	LUT_DATA	<=	24'hc09800;
	58	:	LUT_DATA	<=	24'hc09900;
	59	:	LUT_DATA	<=	24'hc09a00;
	60	:	LUT_DATA	<=	24'hc09b00;
	61	:	LUT_DATA	<=	24'hc0a200;
	62	:	LUT_DATA	<=	24'hc0a300;
	63	:	LUT_DATA	<=	24'hc0a400;
	64	:	LUT_DATA	<=	24'hc0a500;
	65	:	LUT_DATA	<=	24'hc0a600;
	66	:	LUT_DATA	<=	24'hc0a700;
	67	:	LUT_DATA	<=	24'hc0b712;
	68	:	LUT_DATA	<=	24'h2005fd;
	default:	LUT_DATA	<=	24'h200220;
	endcase
end
endmodule 
