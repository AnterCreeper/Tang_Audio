module audio_tb();

reg clk0;
reg clk1;

wire busy;    
wire done;
wire valid;
wire test1;
wire test2;
wire test3;

wire spi_cs;
wire spi_clk;
wire spi_mosi;
reg spi_miso;

wire io_i2s_bclk;
wire io_i2s_lrclk;
wire io_i2s_data;

    wire io_i2c_scl,
    inout io_i2c_sda;
    
audio au(
    .clk_27(clk0),
    .iclk(clk1),

    .busy(busy),
    .done(done),
    .valid(valid),
    .test1(test1),
    .test2(test2),
    .test3(test3),

    .io_spi_cs(spi_cs),
    output io_spi_clk,
    output io_spi_mosi,
    input io_spi_miso,
    
    output io_i2s_bclk,
    output io_i2s_lrclk,
    output io_i2s_data,
    
    output io_i2c_scl,
    inout io_i2c_sda
);

endmodule
