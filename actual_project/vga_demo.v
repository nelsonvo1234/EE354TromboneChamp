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
	reg [3:0]	SSD;
	wire [3:0]	SSD0;
	reg [7:0]  	SSD_CATHODES;
initial DIV_CLK = 0;

reg [27:0] win_reset_counter;
reg [21:0] win_reset_hold;
initial begin
    win_reset_counter = 0;
    win_reset_hold = 0;
end

wire win_reset = (win_reset_hold != 0);
wire game_reset = reset || win_reset;

always @(posedge ClkPort or posedge reset) begin
    if (reset)
        DIV_CLK <= 0;
    else
        DIV_CLK <= DIV_CLK + 1;
end

wire clk = DIV_CLK[1];
wire player_clk = DIV_CLK[19];
wire all_berries_collected;

wire [2:0] gameState;

localparam
INITIAL = 3'b001,
GAME	= 3'b010,
WIN	= 3'b10;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        win_reset_counter <= 0;
        win_reset_hold <= 0;
        gameState <= INITIAL;
    end 
    switch(gameState)
    INITIAL: 
        gameState <= GAME;
    GAME: 
        if(all_beries_collected) begin
            win_reset_counter <= win_reset_counter + 1;
        end

        if(win_reset_counter == 28'd249999999) begin
            win_reset_counter <= 0;
            win_reset_hold <= {22{1'b1}};
        end
    WIN: 

    else if (win_reset_hold != 0) begin
        win_reset_counter <= 0;
        win_reset_hold <= win_reset_hold - 1;
    end else if (all_berries_collected) begin
        if (win_reset_counter == 28'd249999999) begin
            win_reset_counter <= 0;
            win_reset_hold <= {22{1'b1}};
        end else begin
            win_reset_counter <= win_reset_counter + 1;
        end
    end else begin
        win_reset_counter <= 0;
    end
end

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
    .rst(game_reset),
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
    .playerX(x),
    .playerY(y),
    .nextX(nextX),
    .nextY(nextY),
    .clk(clk),
    .rst(game_reset),
    .collide_left(collide_left),
    .collide_right(collide_right),
    .collide_top(collide_top),
    .collide_bottom(collide_bottom),
    .hit_spike(hit_spike),
    .collect_berry(collect_berry),
    .all_berries_collected(all_berries_collected),
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

wire player_running = (BtnL || BtnR) && collide_bottom;
wire [3:0] anim_phase = DIV_CLK[23:20];
wire [2:0] frame7 =
    (anim_phase < 4'd7)  ? anim_phase[2:0] :
    (anim_phase < 4'd14) ? (anim_phase - 4'd7) :
                           3'd0;
wire [3:0] run_frame = (anim_phase < 4'd12) ? anim_phase : (anim_phase - 4'd12);

wire [9:0] player_sprite_y = (y > 10'd16) ? (y - 10'd16) : 10'd0;
wire draw_player =
    (CounterX >= x && CounterX < x + 10'd16 &&
     CounterY >= player_sprite_y && CounterY < player_sprite_y + 10'd32);

wire [3:0] player_row = (CounterY - player_sprite_y) >> 1;
wire [3:0] player_col_raw = CounterX - x;
wire [3:0] player_col = facing_left ? (4'd15 - player_col_raw) : player_col_raw;

wire berry0_area = (tile_x >= 6'd5  && tile_x <= 6'd6  && tile_y >= 5'd24 && tile_y <= 5'd25);
wire berry1_area = (tile_x >= 6'd18 && tile_x <= 6'd19 && tile_y >= 5'd16 && tile_y <= 5'd17);
wire berry2_area = (tile_x >= 6'd30 && tile_x <= 6'd31 && tile_y >= 5'd13 && tile_y <= 5'd14);
wire berry3_area = (tile_x >= 6'd10 && tile_x <= 6'd11 && tile_y >= 5'd20 && tile_y <= 5'd21);
wire berry4_area = (tile_x >= 6'd24 && tile_x <= 6'd25 && tile_y >= 5'd10 && tile_y <= 5'd11);
wire [9:0] berry_base_x =
    berry0_area ? 10'd80 :
    berry1_area ? 10'd288 :
    berry2_area ? 10'd480 :
    berry3_area ? 10'd160 :
                  10'd384;
wire [9:0] berry_base_y =
    berry0_area ? 10'd384 :
    berry1_area ? 10'd256 :
    berry2_area ? 10'd208 :
    berry3_area ? 10'd320 :
                  10'd160;

wire [3:0] berry_row = (CounterY - berry_base_y) >> 1;
wire [3:0] berry_col = (CounterX - berry_base_x) >> 1;
wire [3:0] tile_row = CounterY[3:0];
wire [3:0] tile_col = CounterX[3:0];

wire [11:0] idle_color, run_color, strawberry_color, spike_color;
wire idle_opaque, run_opaque, strawberry_opaque, spike_opaque;

madeline_idle_rom idle_rom (
    .frame(frame7),
    .row(player_row),
    .col(player_col),
    .color_data(idle_color),
    .opaque(idle_opaque)
);

run_slow_rom run_rom (
    .frame(run_frame),
    .row(player_row),
    .col(player_col),
    .color_data(run_color),
    .opaque(run_opaque)
);

strawberry_rom berry_rom (
    .frame(frame7),
    .row(berry_row),
    .col(berry_col),
    .color_data(strawberry_color),
    .opaque(strawberry_opaque)
);

spike_sprite_rom spike_rom (
    .frame(1'b0),
    .row(tile_row),
    .col(tile_col),
    .color_data(spike_color),
    .opaque(spike_opaque)
);

wire [11:0] player_color = player_running ? run_color : idle_color;
wire player_opaque = player_running ? run_opaque : idle_opaque;

wire [8:0] bg_x = CounterX[8:0];
wire [8:0] dist_far = (bg_x > 9'd150) ? (bg_x - 9'd150) : (9'd150 - bg_x);
wire [8:0] dist_mid = (bg_x > 9'd350) ? (bg_x - 9'd350) : (9'd350 - bg_x);
wire [9:0] far_ridge = 10'd330 - {2'b00, dist_far[8:1]};
wire [9:0] mid_ridge = 10'd380 - {2'b00, dist_mid[8:1]};
wire snow_pixel = (CounterY < 10'd230) &&
    (((CounterX[5:0] ^ CounterY[5:0] ^ DIV_CLK[25:20]) == 6'b001011) ||
     ((CounterX[6:1] + CounterY[6:1] + DIV_CLK[24:19]) == 6'b101101));

wire [11:0] background_color =
    snow_pixel              ? 12'hfff :
    (CounterY > mid_ridge)  ? 12'h245 :
    (CounterY > far_ridge)  ? 12'h579 :
    (CounterY < 10'd90)    ? 12'h123 :
    (CounterY < 10'd180)   ? 12'h236 :
    (CounterY < 10'd300)   ? 12'h58a :
                              12'h8bd;

wire [7:0] confetti_phase =
    {1'b0, CounterX[6:0]} + {1'b0, CounterY[6:0]} + {1'b0, DIV_CLK[25:19]};
wire celebration_pixel =
    all_berries_collected &&
    CounterY < 10'd260 &&
    confetti_phase[5:0] < 6'd3;
wire [11:0] celebration_color =
    confetti_phase[7:6] == 2'b00 ? 12'hf2b :
    confetti_phase[7:6] == 2'b01 ? 12'hff3 :
    confetti_phase[7:6] == 2'b10 ? 12'h3ff :
                                   12'hf7f;

wire [11:0] pixel_color =
    celebration_pixel                    ? celebration_color :
    (draw_player && player_opaque)         ? player_color :
    (is_berry && strawberry_opaque)        ? strawberry_color :
    (is_spike && spike_opaque)             ? spike_color :
    is_solid                               ? 12'h0f0 :
                                             background_color;

wire [3:0] r = pixel_color[11:8];
wire [3:0] g = pixel_color[7:4];
wire [3:0] b = pixel_color[3:0];

assign vgaRed   = r & {4{inDisplayArea}};
assign vgaGreen = g & {4{inDisplayArea}};
assign vgaBlue  = b & {4{inDisplayArea}};

//////////////////////////////////////////////////////////////
// SCORE
//////////////////////////////////////////////////////////////
reg [7:0] score;
initial score = 0;

always @(posedge clk) begin
    if (game_reset || hit_spike)
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
// SSD -> display score
//////////////////////////////////////////////////////////////
	assign SSD0 = score[3:0];

assign An0 = 1'b0;
assign {An7, An6, An5, An4, An3, An2, An1} = 7'b1111111;

always @ (SSD0)
begin : SSD_SCAN_OUT
    SSD = SSD0;
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
