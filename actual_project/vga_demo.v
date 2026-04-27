`timescale 1ns / 1ps

module vga_demo(
    input ClkPort,

    input Sw0, Sw1,
    input BtnU, BtnD, BtnL, BtnR, BtnC,

    output Hsync, Vsync,
    output [3:0] vgaRed, vgaGreen, vgaBlue,

    output Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7,
    output Ld8, Ld9, Ld10, Ld11, Ld12, Ld13, Ld14, Ld15,

    output An0, An1, An2, An3, An4, An5, An6, An7,
    output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,

    output QuadSpiFlashCS
);

//////////////////////////////////////////////////////////////
// CLOCK / RESET
//////////////////////////////////////////////////////////////
wire reset = Sw0;
reg [27:0] DIV_CLK;

always @(posedge ClkPort or posedge reset) begin
    if (reset)
        DIV_CLK <= 0;
    else
        DIV_CLK <= DIV_CLK + 1;
end

wire clk = DIV_CLK[1];
wire player_clk = DIV_CLK[20];   // slow movement

//////////////////////////////////////////////////////////////
// VGA SYNC
//////////////////////////////////////////////////////////////
wire inDisplayArea;
wire [9:0] CounterX;
wire [9:0] CounterY;

hvsync_generator syncgen(
    .clk(clk),
    .reset(reset),
    .vga_h_sync(Hsync),
    .vga_v_sync(Vsync),
    .inDisplayArea(inDisplayArea),
    .CounterX(CounterX),
    .CounterY(CounterY)
);

//////////////////////////////////////////////////////////////
// PLAYER MODULE
//////////////////////////////////////////////////////////////
wire [9:0] x;
wire [9:0] y;
wire [9:0] nextX;
wire [9:0] nextY;

wire collide_left, collide_right, collide_top, collide_bottom;


wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump;
wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath;

wire [5:0] tile_x = CounterX >> 4;
wire [4:0] tile_y = CounterY >> 4;
wire tile;

player p1 (
    .clk(player_clk),
    .rst(reset),
    .SW0(Sw0),
    .BtnC(BtnC),
    .BtnL(BtnL),
    .BtnR(BtnR),
    .BtnU(BtnU),
    .BtnD(BtnD),
    .x(x),
    .y(y),
	.nextX(nextX),
	.nextY(nextY),

	.collide_left(collide_left),
	.collide_right(collide_right),
	.collide_top(collide_top),
	.collide_bottom(collide_bottom),

    .Qinit(Qinit), .Qidle(Qidle), .Qleft(Qleft), .Qright(Qright),
    .Qdown(Qdown), .Qjump(Qjump),
    .Qupleft(Qupleft), .Qupright(Qupright),
    .Qdownleft(Qdownleft), .Qdownright(Qdownright),
    .Qdeath(Qdeath)
);

// ONE world instance
world w(
    // collision interface
    .x_next(nextX),
    .y_next(nextY),
    .collide_left(collide_left),
    .collide_right(collide_right),
    .collide_top(collide_top),
    .collide_bottom(collide_bottom),

    // rendering interface
    .tile_x(tile_x),
    .tile_y(tile_y),
    .tile_out(tile)
);

//////////////////////////////////////////////////////////////
// VGA DRAWING
//////////////////////////////////////////////////////////////
wire draw_player =
    (CounterX >= x && CounterX <= x + 20 &&
     CounterY >= y && CounterY <= y + 20);



wire draw_tile = (tile == 2'b01);
wire R = draw_player;
assign G = {4{draw_tile & inDisplayArea}};
wire B = 1'b0;

assign vgaRed   = {4{R & inDisplayArea}};
assign vgaGreen = {4{G & inDisplayArea}};
assign vgaBlue  = {4{B & inDisplayArea}};

//////////////////////////////////////////////////////////////
// LEDS
//////////////////////////////////////////////////////////////
assign Ld0  = Sw0;
assign Ld1  = Sw1;
assign Ld2  = BtnU;
assign Ld3  = BtnD;
assign Ld4  = BtnL;
assign Ld5  = BtnR;
assign Ld6  = BtnC;
assign Ld7  = 1'b0;
assign Ld8  = 1'b0;
assign Ld9  = 1'b0;
assign Ld10 = 1'b0;
assign Ld11 = 1'b0;
assign Ld12 = 1'b0;
assign Ld13 = 1'b0;
assign Ld14 = 1'b0;
assign Ld15 = 1'b0;

//////////////////////////////////////////////////////////////
// SSD (OFF)
//////////////////////////////////////////////////////////////
assign An0 = 1'b1;
assign An1 = 1'b1;
assign An2 = 1'b1;
assign An3 = 1'b1;
assign An4 = 1'b1;
assign An5 = 1'b1;
assign An6 = 1'b1;
assign An7 = 1'b1;

assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = 8'b11111111;

//////////////////////////////////////////////////////////////
// REQUIRED
//////////////////////////////////////////////////////////////
assign QuadSpiFlashCS = 1'b1;

endmodule