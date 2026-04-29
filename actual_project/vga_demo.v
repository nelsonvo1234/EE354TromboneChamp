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
// CLOCK
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
wire player_clk = DIV_CLK[19];

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
// PLAYER + WORLD
//////////////////////////////////////////////////////////////
wire [9:0] x, y;
wire [9:0] nextX, nextY;

wire collide_left, collide_right, collide_top, collide_bottom;
wire hit_spike, collect_berry;

wire [5:0] tile_x = CounterX >> 4;
wire [4:0] tile_y = CounterY >> 4;
wire [1:0] tile;

wire facing_left;

player p1 (
    .clk(player_clk),
    .rst(reset),
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
    .hit_spike(hit_spike),   
    .facing_left(facing_left)
);

world w (
    .x_next(nextX),
    .y_next(nextY),
    .clk(clk),
    .collide_left(collide_left),
    .collide_right(collide_right),
    .collide_top(collide_top),
    .collide_bottom(collide_bottom),
    .hit_spike(hit_spike),
    .collect_berry(collect_berry),
    .tile_x(tile_x),
    .tile_y(tile_y),
    .tile_out(tile)
);

//////////////////////////////////////////////////////////////
// VGA DRAWING
//////////////////////////////////////////////////////////////
wire is_solid = (tile == 2'b01);
wire is_spike = (tile == 2'b10);
wire is_berry = (tile == 2'b11);

wire draw_player =
    (CounterX >= x && CounterX < x + 20 &&
     CounterY >= y && CounterY < y + 20);

wire [3:0] r =
    draw_player ? 4'b1111 :
    is_berry    ? 4'b1111 :
    is_spike    ? 4'b1111 : 4'b0000;

wire [3:0] g =
    draw_player ? 4'b0000 :
    is_berry    ? 4'b1111 :
    is_solid    ? 4'b1111 : 4'b0000;

wire [3:0] b = 4'b0000;

assign vgaRed   = r & {4{inDisplayArea}};
assign vgaGreen = g & {4{inDisplayArea}};
assign vgaBlue  = b & {4{inDisplayArea}};

//////////////////////////////////////////////////////////////
// SCORE
//////////////////////////////////////////////////////////////
reg [7:0] score;
always @(posedge clk) begin
    if (reset)
        score <= 0;
    else if (collect_berry)
        score <= score + 1;
end

//////////////////////////////////////////////////////////////
// LEDS
//////////////////////////////////////////////////////////////
assign {Ld0,Ld1,Ld2,Ld3,Ld4,Ld5,Ld6} =
       {Sw0,Sw1,BtnU,BtnD,BtnL,BtnR,BtnC};

assign {Ld7,Ld8,Ld9,Ld10,Ld11,Ld12,Ld13,Ld14,Ld15} = 0;

//////////////////////////////////////////////////////////////
// SSD -> display collides
//////////////////////////////////////////////////////////////
assign {An0,An1,An2,An3,An4,An5,An6,An7} = 8'hFF;
assign {Ca,Cb,Cc,Cd,Ce,Cf,Cg,Dp} = 8'hFF;

//////////////////////////////////////////////////////////////
assign QuadSpiFlashCS = 1'b1;

endmodule