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
wire [1:0] 	ssdscan_clk;
	reg [3:0]	SSD;
	wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;
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

wire [9:0] left_o, right_o, top_o, bottom_o;

wire [1:0] tile_o;

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
    .nextX(nextX),
    .nextY(nextY),
    .clk(clk),
    .collide_left(collide_left),
    .collide_right(collide_right),
    .collide_top(collide_top),
    .collide_bottom(collide_bottom),
    .hit_spike(hit_spike),
    .collect_berry(collect_berry),
    .tile_x(tile_x),
    .tile_y(tile_y),
    .tile_out(tile),
    .left_o(left_o),
    .right_o(right_o),
    .top_o(top_o),
    .bottom_o(bottom_o),
    .tile_o(tile_o)
);

//////////////////////////////////////////////////////////////
// VGA DRAWING
//////////////////////////////////////////////////////////////
wire is_solid = (tile == 2'b01);
wire is_spike = (tile == 2'b10);
wire is_berry = (tile == 2'b11);

wire draw_player =
    (CounterX >= x && CounterX < x + 16 &&
     CounterY >= y && CounterY < y + 16);

wire nextPos =     (CounterX >= nextX && CounterX < nextX + 15 &&
     CounterY >= nextY && CounterY < nextY + 15);

wire [3:0] r =
    draw_player ? 4'b1111 :
    is_berry    ? 4'b1111 :
    is_spike    ? 4'b1111 : 4'b0000;

wire [3:0] g =
    draw_player ? 4'b0000 :
    is_berry    ? 4'b1111 :
    is_solid    ? 4'b1111 : 4'b0000;

wire [3:0] b = nextPos ? 4'b1111 : 4'b0000;

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
assign {Ld7, Ld8, Ld9, Ld10} = {collide_left, collide_right, collide_bottom, collide_top};

assign {Ld11, Ld12} = {tile_o[0], tile_o[1]};

assign {Ld13,Ld14,Ld15} = 0;

//////////////////////////////////////////////////////////////
// SSD -> display collides
//////////////////////////////////////////////////////////////
	assign SSD3 = left_o >> 4;
	assign SSD2 = left_o;
	assign SSD1 = top_o >> 4;
	assign SSD0 = top_o;
assign ssdscan_clk = DIV_CLK[19:18];

assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
assign An2	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
assign An3	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11


assign {An7, An6, An5, An4} = 4'b1111;

always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
begin : SSD_SCAN_OUT
	case (ssdscan_clk) 
			  2'b00: SSD = SSD0;
			  2'b01: SSD = SSD1;
			  2'b10: SSD = SSD2;
			  2'b11: SSD = SSD3;
	endcase 
end

	// Following is Hex-to-SSD conversion
always @ (SSD) 
begin : HEX_TO_SSD
	case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abcdefg,Dp
		4'b0000: SSD_CATHODES = 8'b00000011; // 0
		4'b0001: SSD_CATHODES = 8'b10011111; // 1
		4'b0010: SSD_CATHODES = 8'b00100101; // 2
		4'b0011: SSD_CATHODES = 8'b00001101; // 3
		4'b0100: SSD_CATHODES = 8'b10011001; // 4
		4'b0101: SSD_CATHODES = 8'b01001001; // 5
		4'b0110: SSD_CATHODES = 8'b01000001; // 6
		4'b0111: SSD_CATHODES = 8'b00011111; // 7
		4'b1000: SSD_CATHODES = 8'b00000001; // 8
		4'b1001: SSD_CATHODES = 8'b00001001; // 9
		4'b1010: SSD_CATHODES = 8'b00010001; // A
		4'b1011: SSD_CATHODES = 8'b11000001; // B
		4'b1100: SSD_CATHODES = 8'b01100011; // C
		4'b1101: SSD_CATHODES = 8'b10000101; // D
		4'b1110: SSD_CATHODES = 8'b01100001; // E
		4'b1111: SSD_CATHODES = 8'b01110001; // F    
		default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
	endcase
end	
	
	// reg [7:0]  SSD_CATHODES;
assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

//////////////////////////////////////////////////////////////
assign QuadSpiFlashCS = 1'b1;

endmodule