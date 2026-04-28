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
	.facing_left(facing_left)
);

// ONE world instance
timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, btnU, btnD,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	input ClkPort, Sw0, btnU, btnD, Sw0, Sw1;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] position;
	
	always @(posedge DIV_CLK[21])
		begin
			if(reset)
				position<=240;
			else if(btnD && ~btnU)
				position<=position+2;
			else if(btnU && ~btnD)
				position<=position-2;	
		end

	wire R = CounterY>=(position-10) && CounterY<=(position+10) && CounterX[8:5]==7;
	wire G = CounterX>100 && CounterX<200 && CounterY[5:3]==7;
	wire B = 0;
	
	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	define QI 			2'b00
	define QGAME_1 	2'b01
	define QGAME_2 	2'b10
	define QDONE 		2'b11
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	reg [1:0] state;
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = (p1_score == 4'b1010);
	assign LD1 = (p2_score == 4'b1010);
	
	assign LD2 = start;
	assign LD4 = reset;
	
	assign LD3 = (state == QI);
	assign LD5 = (state == QGAME_1);	
	assign LD6 = (state == QGAME_2);
	assign LD7 = (state == QDONE);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = 4'b1111;
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = position[3:0];
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule


please explain this
explain the vga stuff please
module player(
    input wire clk,
    input wire rst,
    input SW0, BtnC, BtnL, BtnR, BtnU, BtnD,

    output reg [9:0] x,
    output reg [9:0] y

//    output Qinit, Qidle, Qleft, Qright, Qdown, Qjump, Qupleft, Qupright, Qdownleft, Qdownright, Qdeath;
)
reg [10:0] state;
localparam
INIT = 11'b00000000001,
IDLE = 11'b00000000010,
LEFT = 11'b00000000100,
RIGHT = 11'b00000001000,
DOWN = 11'b00000010000,
JUMP = 11'b00000100000,
UPLEFT = 11'b00001000000,
UPRIGHT = 11'b00010000000,
DOWNLEFT = 11'b00100000000,
DOWNRIGHT = 11'b010000000000,
DEATH = 11'b10000000000,
UNK = 11'bXXXXXXXXXXX;

assign {Qinit, Qidle, Qleft, Qright, Qdown, Qjump, Qupleft, Qupright, Qdownleft, Qdownright, Qdeath} = state;

reg jumpflag, dashflag;
reg [10:0] jumpcount, dashcount; //how long it will jump and dash for
always @(posedge clk)begin
    if(rst) begin
        state <= INIT;
        x <= 10;
        y <= 10;
        jumpflag <= 0;
    end
    else begin
        case(state)
            INIT:
                begin
                    //actions
                    x<=0;
                    y<=0;
                    jumpflag <=0;
                    //rtl
                    state <= IDLE;
                end
            IDLE:
                begin
                    //actions: x and y don't change (unless there is gravity)

                    //gravity code:

                    jumpflag <= 0; //no conditions for now for testing

                    //rtl
                    if(BtnL)begin //debounce these later
                        state <= LEFT;
                    end
                    if(BtnR)begin
                        state<=RIGHT;
                    end
                    if(BtnU)begin
                        state <= JUMP;
                    end
                    if(BtnD)begin
                        state <=DOWN;
                    end
                    if(BtnU & BtnL)begin
                        state <=UPLEFT;
                    end
                    if(BtnU & BtnR)begin
                        state <= UPRIGHT;
                    end
                    if (BtnD & BtnL)begin
                        state <= DOWNLEFT;
                    end
                    if (BtnD & BtnR)begin
                        state <= DOWNRIGHT;
                    end

                end
            LEFT:
                begin
                    //
                    if(x>=0)begin
                        x<=x-1;
                    end
                    //rtl
                    if(!BtnL)begin
                        state<=IDLE;
                    end

                end
            RIGHT:
                begin
                    if(x<= 0'b11111111111)begin
                        x<=x+1;
                    end
                    //rtl
                    if(!BtnR)begin
                        state <= IDLE;
                    end
                end
            DOWN: 
                begin
                    if(x>=0)
                        y <= y-1;
                    
                    //rtl
                    if(!BtnD)
                        state <= IDLE;
                    
                end
            JUMP:
                begin
                    if(y<=0'b11111111111)begin
                        y<= y+20;
                        jumpflag <= 1; //cannot jump again until this becomes 0
                    end
                    state <= IDLE;
                end
            UPLEFT:
                begin
                    jumpflag <= 1;
                    if(y<=0'b11111111111)
                        y <= y + 20;
                    if( x>=0)
                        x <= x - 1;
                    //rtl
                    if(BtnL)
                        state <= LEFT; //keep moving left even after jump if left is still pressed 
                    else
                        state <= IDLE;
                end
            UPRIGHT:
                begin
                    jumpflag <= 1;
                    if(y<=0'b11111111111)
                        y <= y + 20;
                    if( x<=0'b11111111111)
                        x <= x + 1;
                    //rtl
                    if(BtnL)
                        state <= RIGHT; //keep on moving right even post jump until BtnL not pressed
                    else
                        state <= IDLE;
                end
            DOWNLEFT:
                begin
                    if(y>=0)
                        y <= y - 1;
                    if( x>=0)
                        x <= x - 1;
                    if(!BtnD & !BtnL)
                        state <= IDLE;
                    else if (BtnL & !BtnD)
                        state <= LEFT;
                    else if (!BtnL & BtnD)
                         state <= DOWN;
                end
            DOWNRIGHT:
                begin
                    if(y>=0)
                        y <= y - 1;
                    if( x<=0'b11111111111)
                        x <= x + 1;
                    if(!BtnD & !BtnR)
                        state <= IDLE;
                    else if (BtnR & !BtnD)
                        state <= LEFT;
                    else if (!BtnR & BtnD)
                         state <= DOWN;
                end
            DEATH: 
                begin
                end
        endcase
    end
end
endmodule

what's the syntax error
please just fix it
timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, btnU, btnD, btnL, btnR, btnC,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	input ClkPort, Sw0, btnU, btnD, btnC, btL, btnR, Sw0, Sw1;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] x;
	reg [9:0] y;


	
	player(.clk(clk), .rst(rst), .SW0(SW0), .BtnC(btnC), ,BtnL(btnL), .BtnR(btnR), .BtnU(btnU), .BtnD(btnD), .x(x), .y(y),

    Qinit, Qidle, Qleft, Qright, Qdown, Qjump, Qupleft, Qupright, Qdownleft, Qdownright, Qdeath;
);


	wire R = CounterY>=(y-10) && CounterY<=(y+10) && CounterX>=(x-10) && CounterX<=(x+10);
	wire G = CounterX>100 && CounterX<200 && CounterY[5:3]==7;
	wire B = 0;
	
	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	define QI 			2'b00
	define QGAME_1 	2'b01
	define QGAME_2 	2'b10
	define QDONE 		2'b11
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	reg [1:0] state;
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = (p1_score == 4'b1010);
	assign LD1 = (p2_score == 4'b1010);
	
	assign LD2 = start;
	assign LD4 = reset;
	
	assign LD3 = (state == QI);
	assign LD5 = (state == QGAME_1);	
	assign LD6 = (state == QGAME_2);
	assign LD7 = (state == QDONE);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = 4'b1111;
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = position[3:0];
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule

fix this one
bitstream generation failing
[DRC NSTD-1] Unspecified I/O Standard: 23 out of 36 logical ports use I/O standard (IOSTANDARD) value 'DEFAULT', instead of a user assigned specific value. This may cause I/O contention or incompatibility with the board power or connectivity affecting performance, signal integrity or in extreme cases cause damage to the device or the components to which it is connected. To correct this violation, specify all I/O standards. This design will fail to generate a bitstream unless all logical ports have a user specified I/O standard value defined. To allow bitstream creation with unspecified I/O standard values (not recommended), use this command: set_property SEVERITY {Warning} [get_drc_checks NSTD-1].  NOTE: When using the Vivado Runs infrastructure (e.g. launch_runs Tcl command), add this command to a .tcl file and add that file as a pre-hook for write_bitstream step for the implementation run. Problem ports: LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7, Mt_St_oe_bar, Mt_St_we_bar, Mt_ce_bar, St_ce_bar, St_rp_bar, Sw0, btnD... and (the first 15 of 23 listed).
is it because of vga_demo.v?
### Nexys N4 to Nexys A7 XDC conversion script: 
### Author : Sharath Krishnan - sharath@usc.edu 

set_property PACKAGE_PIN E3 [get_ports ClkPort]							
	set_property IOSTANDARD LVCMOS33 [get_ports ClkPort]
	create_clock -add -name ClkPort -period 10.00 [get_ports ClkPort]

set_property PACKAGE_PIN T10 [get_ports {Ca}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Ca}]

set_property PACKAGE_PIN R10 [get_ports {Cb}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cb}]

set_property PACKAGE_PIN K16 [get_ports {Cc}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cc}]

set_property PACKAGE_PIN K13 [get_ports {Cd}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cd}]

set_property PACKAGE_PIN P15 [get_ports {Ce}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Ce}]

set_property PACKAGE_PIN T11 [get_ports {Cf}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cf}]

set_property PACKAGE_PIN L18 [get_ports {Cg}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {Cg}]

set_property PACKAGE_PIN H15 [get_ports Dp] 
	set_property IOSTANDARD LVCMOS33 [get_ports Dp]

set_property PACKAGE_PIN J17 [get_ports {An0}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An0}]

set_property PACKAGE_PIN J18 [get_ports {An1}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An1}]

set_property PACKAGE_PIN T9 [get_ports {An2}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An2}]

set_property PACKAGE_PIN J14 [get_ports {An3}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An3}]

set_property PACKAGE_PIN P14 [get_ports {An4}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An4}]

set_property PACKAGE_PIN T14 [get_ports {An5}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An5}]

set_property PACKAGE_PIN K2 [get_ports {An6}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An6}]

set_property PACKAGE_PIN U13 [get_ports {An7}] 
	set_property IOSTANDARD LVCMOS33 [get_ports {An7}]

set_property PACKAGE_PIN N17 [get_ports BtnC] 
	set_property IOSTANDARD LVCMOS33 [get_ports BtnC]

set_property PACKAGE_PIN M18 [get_ports BtnU] 
	set_property IOSTANDARD LVCMOS33 [get_ports BtnU]

set_property PACKAGE_PIN A3 [get_ports {vgaR[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaR[0]}]

set_property PACKAGE_PIN B4 [get_ports {vgaR[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaR[1]}]

set_property PACKAGE_PIN C5 [get_ports {vgaR[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaR[2]}]

set_property PACKAGE_PIN A4 [get_ports {vgaR[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaR[3]}]

set_property PACKAGE_PIN B7 [get_ports {vgaB[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaB[0]}]

set_property PACKAGE_PIN C7 [get_ports {vgaB[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaB[1]}]

set_property PACKAGE_PIN D7 [get_ports {vgaB[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaB[2]}]

set_property PACKAGE_PIN D8 [get_ports {vgaB[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaB[3]}]

set_property PACKAGE_PIN C6 [get_ports {vgaG[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaG[0]}]

set_property PACKAGE_PIN A5 [get_ports {vgaG[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaG[1]}]

set_property PACKAGE_PIN B6 [get_ports {vgaG[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaG[2]}]

set_property PACKAGE_PIN A6 [get_ports {vgaG[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vgaG[3]}]

set_property PACKAGE_PIN B11 [get_ports hSync]						
	set_property IOSTANDARD LVCMOS33 [get_ports hSync]

set_property PACKAGE_PIN B12 [get_ports vSync]						
	set_property IOSTANDARD LVCMOS33 [get_ports vSync]

set_property PACKAGE_PIN L13 [get_ports QuadSpiFlashCS]					
	set_property IOSTANDARD LVCMOS33 [get_ports QuadSpiFlashCS]

set_property PACKAGE_PIN L18 [get_ports RamCS]					
	set_property IOSTANDARD LVCMOS33 [get_ports RamCS]

set_property PACKAGE_PIN H14 [get_ports MemOE]					
	set_property IOSTANDARD LVCMOS33 [get_ports MemOE]

set_property PACKAGE_PIN R11 [get_ports MemWR]					
	set_property IOSTANDARD LVCMOS33 [get_ports MemWR]

ok fix my vga_demo.v\
[DRC NSTD-1] Unspecified I/O Standard: 17 out of 45 logical ports use I/O standard (IOSTANDARD) value 'DEFAULT', instead of a user assigned specific value. This may cause I/O contention or incompatibility with the board power or connectivity affecting performance, signal integrity or in extreme cases cause damage to the device or the components to which it is connected. To correct this violation, specify all I/O standards. This design will fail to generate a bitstream unless all logical ports have a user specified I/O standard value defined. To allow bitstream creation with unspecified I/O standard values (not recommended), use this command: set_property SEVERITY {Warning} [get_drc_checks NSTD-1].  NOTE: When using the Vivado Runs infrastructure (e.g. launch_runs Tcl command), add this command to a .tcl file and add that file as a pre-hook for write_bitstream step for the implementation run. Problem ports: BtnD, BtnL, BtnR, LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7, Mt_St_oe_bar, Mt_St_we_bar, Mt_ce_bar, St_ce_bar... and (the first 15 of 17 listed).
ok, remove them then
you've seen the xdc, fix the vga_demo.v
new xdc
## https://github.com/Digilent/digilent-xdc/blob/master/Nexys-4-Master.xdc    
## This file is a general .xdc for the Nexys4 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Revised test_nexys4_verilog.xdc to suit ee354_detour_top.xdc 
## Basically commented out the unused 15 switches Sw15-Sw1 
##           and also commented out the four buttons BtnL, BtnU, BtnR, and BtnD
## Gandhi 1/21/2020

# Clock signal
#Bank = 35, Pin name = IO_L12P_T1_MRCC_35,					Sch name = CLK100MHZ
set_property PACKAGE_PIN E3 [get_ports ClkPort]							
	set_property IOSTANDARD LVCMOS33 [get_ports ClkPort]
	create_clock -add -name ClkPort -period 10.00 [get_ports ClkPort]
 
# Switches
#Bank = 34, Pin name = IO_L21P_T3_DQS_34,					Sch name = Sw0
set_property PACKAGE_PIN J15 [get_ports {Sw0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw0}]
#Bank = 34, Pin name = IO_25_34,							Sch name = Sw1
set_property PACKAGE_PIN L16 [get_ports {Sw1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw1}]
#Bank = 34, Pin name = IO_L23P_T3_34,						Sch name = Sw2
set_property PACKAGE_PIN M13 [get_ports {Sw2}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw2}]
#Bank = 34, Pin name = IO_L19P_T3_34,						Sch name = Sw3
set_property PACKAGE_PIN R15 [get_ports {Sw3}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw3}]
#Bank = 34, Pin name = IO_L19N_T3_VREF_34,					Sch name = Sw4
set_property PACKAGE_PIN R17 [get_ports {Sw4}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw4}]
#Bank = 34, Pin name = IO_L20P_T3_34,						Sch name = Sw5
set_property PACKAGE_PIN T18 [get_ports {Sw5}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw5}]
#Bank = 34, Pin name = IO_L20N_T3_34,						Sch name = Sw6
set_property PACKAGE_PIN U18 [get_ports {Sw6}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw6}]
#Bank = 34, Pin name = IO_L10P_T1_34,						Sch name = Sw7
set_property PACKAGE_PIN R13 [get_ports {Sw7}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw7}]
#Bank = 34, Pin name = IO_L8P_T1-34,						Sch name = Sw8
set_property PACKAGE_PIN T8 [get_ports {Sw8}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw8}]
#Bank = 34, Pin name = IO_L9N_T1_DQS_34,					Sch name = Sw9
set_property PACKAGE_PIN U8 [get_ports {Sw9}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw9}]
#Bank = 34, Pin name = IO_L9P_T1_DQS_34,					Sch name = Sw10
set_property PACKAGE_PIN R16 [get_ports {Sw10}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw10}]
#Bank = 34, Pin name = IO_L11N_T1_MRCC_34,					Sch name = Sw11
set_property PACKAGE_PIN T13 [get_ports {Sw11}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw11}]
#Bank = 34, Pin name = IO_L17N_T2_34,						Sch name = Sw12
set_property PACKAGE_PIN H6 [get_ports {Sw12}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw12}]
#Bank = 34, Pin name = IO_L11P_T1_SRCC_34,					Sch name = Sw13
set_property PACKAGE_PIN U12 [get_ports {Sw13}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw13}]
#Bank = 34, Pin name = IO_L14N_T2_SRCC_34,					Sch name = Sw14
set_property PACKAGE_PIN U11 [get_ports {Sw14}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw14}]
#Bank = 34, Pin name = IO_L14P_T2_SRCC_34,					Sch name = Sw15
set_property PACKAGE_PIN V10 [get_ports {Sw15}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw15}]
	
set_false_path -through [get_nets {Sw0}]
set_false_path -through [get_nets {Sw1}]
set_false_path -through [get_nets {Sw2}]
set_false_path -through [get_nets {Sw3}]
set_false_path -through [get_nets {Sw4}]
set_false_path -through [get_nets {Sw5}]
set_false_path -through [get_nets {Sw6}]
set_false_path -through [get_nets {Sw7}]
set_false_path -through [get_nets {Sw8}]
set_false_path -through [get_nets {Sw9}]
set_false_path -through [get_nets {Sw10}]
set_false_path -through [get_nets {Sw11}]
set_false_path -through [get_nets {Sw12}]
set_false_path -through [get_nets {Sw13}]
set_false_path -through [get_nets {Sw14}]
set_false_path -through [get_nets {Sw15}]
 


# LEDs
#Bank = 34, Pin name = IO_L24N_T3_34,						Sch name = LED0
set_property PACKAGE_PIN H17 [get_ports {Ld0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld0}]
#Bank = 34, Pin name = IO_L21N_T3_DQS_34,					Sch name = LED1
set_property PACKAGE_PIN K15 [get_ports {Ld1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld1}]
#Bank = 34, Pin name = IO_L24P_T3_34,						Sch name = LED2
set_property PACKAGE_PIN J13 [get_ports {Ld2}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld2}]
#Bank = 34, Pin name = IO_L23N_T3_34,						Sch name = LED3
set_property PACKAGE_PIN N14 [get_ports {Ld3}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld3}]
#Bank = 34, Pin name = IO_L12P_T1_MRCC_34,					Sch name = LED4
set_property PACKAGE_PIN R18 [get_ports {Ld4}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld4}]
#Bank = 34, Pin name = IO_L12N_T1_MRCC_34,					Sch	name = LED5
set_property PACKAGE_PIN V17 [get_ports {Ld5}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld5}]
#Bank = 34, Pin name = IO_L22P_T3_34,						Sch name = LED6
set_property PACKAGE_PIN U17 [get_ports {Ld6}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld6}]
#Bank = 34, Pin name = IO_L22N_T3_34,						Sch name = LED7
set_property PACKAGE_PIN U16 [get_ports {Ld7}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld7}]
#Bank = 34, Pin name = IO_L10N_T1_34,						Sch name = LED8
set_property PACKAGE_PIN V16 [get_ports {Ld8}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld8}]
#Bank = 34, Pin name = IO_L8N_T1_34,						Sch name = LED9
set_property PACKAGE_PIN T15 [get_ports {Ld9}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld9}]
#Bank = 34, Pin name = IO_L7N_T1_34,						Sch name = LED10
set_property PACKAGE_PIN U14 [get_ports {Ld10}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld10}]
#Bank = 34, Pin name = IO_L17P_T2_34,						Sch name = LED11
set_property PACKAGE_PIN T16 [get_ports {Ld11}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld11}]
#Bank = 34, Pin name = IO_L13N_T2_MRCC_34,					Sch name = LED12
set_property PACKAGE_PIN V15 [get_ports {Ld12}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld12}]
#Bank = 34, Pin name = IO_L7P_T1_34,						Sch name = LED13
set_property PACKAGE_PIN V14 [get_ports {Ld13}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld13}]
#Bank = 34, Pin name = IO_L15N_T2_DQS_34,					Sch name = LED14
set_property PACKAGE_PIN V12 [get_ports {Ld14}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld14}]
#Bank = 34, Pin name = IO_L15P_T2_DQS_34,					Sch name = LED15
set_property PACKAGE_PIN V11 [get_ports {Ld15}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld15}]
	
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld0}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld1}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld2}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld3}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld4}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld5}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld6}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld7}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld8}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld9}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld10}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld11}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld12}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld13}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld14}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld15}]]

##Bank = 34, Pin name = IO_L5P_T0_34,						Sch name = LED16_R
#set_property PACKAGE_PIN K5 [get_ports RGB1_Red]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB1_Red]
##Bank = 15, Pin name = IO_L5P_T0_AD9P_15,					Sch name = LED16_G
#set_property PACKAGE_PIN F13 [get_ports RGB1_Green]				
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB1_Green]
##Bank = 35, Pin name = IO_L19N_T3_VREF_35,					Sch name = LED16_B
#set_property PACKAGE_PIN F6 [get_ports RGB1_Blue]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB1_Blue]
##Bank = 34, Pin name = IO_0_34,								Sch name = LED17_R
#set_property PACKAGE_PIN K6 [get_ports RGB2_Red]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB2_Red]
##Bank = 35, Pin name = IO_24P_T3_35,						Sch name =  LED17_G
#set_property PACKAGE_PIN H6 [get_ports RGB2_Green]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB2_Green]
##Bank = CONFIG, Pin name = IO_L3N_T0_DQS_EMCCLK_14,			Sch name = LED17_B
#set_property PACKAGE_PIN L16 [get_ports RGB2_Blue]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB2_Blue]



#7 segment display
#Bank = 34, Pin name = IO_L2N_T0_34,						Sch name = Ca
set_property PACKAGE_PIN T10 [get_ports {Ca}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ca}]
#Bank = 34, Pin name = IO_L3N_T0_DQS_34,					Sch name = Cb
set_property PACKAGE_PIN R10 [get_ports {Cb}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cb}]
#Bank = 34, Pin name = IO_L6N_T0_VREF_34,					Sch name = Cc
set_property PACKAGE_PIN K16 [get_ports {Cc}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cc}]
#Bank = 34, Pin name = IO_L5N_T0_34,						Sch name = Cd
set_property PACKAGE_PIN K13 [get_ports {Cd}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cd}]
#Bank = 34, Pin name = IO_L2P_T0_34,						Sch name = Ce
set_property PACKAGE_PIN P15 [get_ports {Ce}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ce}]
#Bank = 34, Pin name = IO_L4N_T0_34,						Sch name = Cf
set_property PACKAGE_PIN T11 [get_ports {Cf}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cf}]
#Bank = 34, Pin name = IO_L6P_T0_34,						Sch name = Cg
set_property PACKAGE_PIN L18 [get_ports {Cg}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cg}]

#Bank = 34, Pin name = IO_L16P_T2_34,						Sch name = Dp
set_property PACKAGE_PIN H15 [get_ports Dp]							
	set_property IOSTANDARD LVCMOS33 [get_ports Dp]

#Bank = 34, Pin name = IO_L18N_T2_34,						Sch name = An0
set_property PACKAGE_PIN J17 [get_ports {An0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An0}]
#Bank = 34, Pin name = IO_L18P_T2_34,						Sch name = An1
set_property PACKAGE_PIN J18 [get_ports {An1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An1}]
#Bank = 34, Pin name = IO_L4P_T0_34,						Sch name = An2
set_property PACKAGE_PIN T9 [get_ports {An2}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An2}]
#Bank = 34, Pin name = IO_L13_T2_MRCC_34,					Sch name = An3
set_property PACKAGE_PIN J14 [get_ports {An3}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An3}]
#Bank = 34, Pin name = IO_L3P_T0_DQS_34,					Sch name = An4
set_property PACKAGE_PIN P14 [get_ports {An4}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An4}]
#Bank = 34, Pin name = IO_L16N_T2_34,						Sch name = An5
set_property PACKAGE_PIN T14 [get_ports {An5}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An5}]
#Bank = 34, Pin name = IO_L1P_T0_34,						Sch name = An6
set_property PACKAGE_PIN K2 [get_ports {An6}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An6}]
#Bank = 34, Pin name = IO_L1N_T034,							Sch name = An7
set_property PACKAGE_PIN U13 [get_ports {An7}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An7}]

set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ca}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cb}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cc}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cd}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ce}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cf}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cg}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Dp}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An0}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An1}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An2}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An3}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An4}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An5}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An6}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An7}]]

#Buttons
##Bank = 15, Pin name = IO_L3P_T0_DQS_AD1P_15,				Sch name = CPU_RESET
#set_property PACKAGE_PIN C12 [get_ports btnCpuReset]				
#	set_property IOSTANDARD LVCMOS33 [get_ports btnCpuReset]
#Bank = 15, Pin name = IO_L11N_T1_SRCC_15,					Sch name = BTNC
set_property PACKAGE_PIN N17 [get_ports BtnC]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnC]
#Bank = 15, Pin name = IO_L14P_T2_SRCC_15,					Sch name = BTNU
set_property PACKAGE_PIN M18 [get_ports BtnU]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnU]
#Bank = CONFIG, Pin name = IO_L15N_T2_DQS_DOUT_CSO_B_14,	Sch name = BTNL
set_property PACKAGE_PIN P17 [get_ports BtnL]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnL]
#Bank = 14, Pin name = IO_25_14,							Sch name = BTNR
set_property PACKAGE_PIN M17 [get_ports BtnR]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnR]
#Bank = 14, Pin name = IO_L21P_T3_DQS_14,					Sch name = BTND
set_property PACKAGE_PIN P18 [get_ports BtnD]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnD]

set_false_path -through [get_nets {BtnC}]
set_false_path -through [get_nets {BtnU}]
set_false_path -through [get_nets {BtnL}]
set_false_path -through [get_nets {BtnR}]
set_false_path -through [get_nets {BtnD}]

##Pmod Header JA
##Bank = 15, Pin name = IO_L1N_T0_AD0N_15,					Sch name = JA1
#set_property PACKAGE_PIN B13 [get_ports {JA[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[0]}]
##Bank = 15, Pin name = IO_L5N_T0_AD9N_15,					Sch name = JA2
#set_property PACKAGE_PIN F14 [get_ports {JA[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[1]}]
##Bank = 15, Pin name = IO_L16N_T2_A27_15,					Sch name = JA3
#set_property PACKAGE_PIN D17 [get_ports {JA[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[2]}]
##Bank = 15, Pin name = IO_L16P_T2_A28_15,					Sch name = JA4
#set_property PACKAGE_PIN E17 [get_ports {JA[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[3]}]
##Bank = 15, Pin name = IO_0_15,								Sch name = JA7
#set_property PACKAGE_PIN G13 [get_ports {JA[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[4]}]
##Bank = 15, Pin name = IO_L20N_T3_A19_15,					Sch name = JA8
#set_property PACKAGE_PIN C17 [get_ports {JA[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[5]}]
##Bank = 15, Pin name = IO_L21N_T3_A17_15,					Sch name = JA9
#set_property PACKAGE_PIN D18 [get_ports {JA[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[6]}]
##Bank = 15, Pin name = IO_L21P_T3_DQS_15,					Sch name = JA10
#set_property PACKAGE_PIN E18 [get_ports {JA[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[7]}]



##Pmod Header JB
##Bank = 15, Pin name = IO_L15N_T2_DQS_ADV_B_15,				Sch name = JB1
#set_property PACKAGE_PIN G14 [get_ports {JB[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[0]}]
##Bank = 14, Pin name = IO_L13P_T2_MRCC_14,					Sch name = JB2
#set_property PACKAGE_PIN P15 [get_ports {JB[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[1]}]
##Bank = 14, Pin name = IO_L21N_T3_DQS_A06_D22_14,			Sch name = JB3
#set_property PACKAGE_PIN V11 [get_ports {JB[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[2]}]
##Bank = CONFIG, Pin name = IO_L16P_T2_CSI_B_14,				Sch name = JB4
#set_property PACKAGE_PIN V15 [get_ports {JB[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[3]}]
##Bank = 15, Pin name = IO_25_15,							Sch name = JB7
#set_property PACKAGE_PIN K16 [get_ports {JB[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[4]}]
##Bank = CONFIG, Pin name = IO_L15P_T2_DQS_RWR_B_14,			Sch name = JB8
#set_property PACKAGE_PIN R16 [get_ports {JB[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[5]}]
##Bank = 14, Pin name = IO_L24P_T3_A01_D17_14,				Sch name = JB9
#set_property PACKAGE_PIN T9 [get_ports {JB[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[6]}]
##Bank = 14, Pin name = IO_L19N_T3_A09_D25_VREF_14,			Sch name = JB10 
#set_property PACKAGE_PIN U11 [get_ports {JB[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[7]}]
 


##Pmod Header JC
##Bank = 35, Pin name = IO_L23P_T3_35,						Sch name = JC1
#set_property PACKAGE_PIN K2 [get_ports {JC[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[0]}]
##Bank = 35, Pin name = IO_L6P_T0_35,						Sch name = JC2
#set_property PACKAGE_PIN E7 [get_ports {JC[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[1]}]
##Bank = 35, Pin name = IO_L22P_T3_35,						Sch name = JC3
#set_property PACKAGE_PIN J3 [get_ports {JC[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[2]}]
##Bank = 35, Pin name = IO_L21P_T3_DQS_35,					Sch name = JC4
#set_property PACKAGE_PIN J4 [get_ports {JC[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[3]}]
##Bank = 35, Pin name = IO_L23N_T3_35,						Sch name = JC7
#set_property PACKAGE_PIN K1 [get_ports {JC[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[4]}]
##Bank = 35, Pin name = IO_L5P_T0_AD13P_35,					Sch name = JC8
#set_property PACKAGE_PIN E6 [get_ports {JC[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[5]}]
##Bank = 35, Pin name = IO_L22N_T3_35,						Sch name = JC9
#set_property PACKAGE_PIN J2 [get_ports {JC[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[6]}]
##Bank = 35, Pin name = IO_L19P_T3_35,						Sch name = JC10
#set_property PACKAGE_PIN G6 [get_ports {JC[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[7]}]
 

 
##Pmod Header JD
##Bank = 35, Pin name = IO_L21N_T2_DQS_35,					Sch name = JD1
#set_property PACKAGE_PIN H4 [get_ports {JD[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[0]}]
##Bank = 35, Pin name = IO_L17P_T2_35,						Sch name = JD2
#set_property PACKAGE_PIN H1 [get_ports {JD[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[1]}]
##Bank = 35, Pin name = IO_L17N_T2_35,						Sch name = JD3
#set_property PACKAGE_PIN G1 [get_ports {JD[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[2]}]
##Bank = 35, Pin name = IO_L20N_T3_35,						Sch name = JD4
#set_property PACKAGE_PIN G3 [get_ports {JD[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[3]}]
##Bank = 35, Pin name = IO_L15P_T2_DQS_35,					Sch name = JD7
#set_property PACKAGE_PIN H2 [get_ports {JD[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[4]}]
##Bank = 35, Pin name = IO_L20P_T3_35,						Sch name = JD8
#set_property PACKAGE_PIN G4 [get_ports {JD[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[5]}]
##Bank = 35, Pin name = IO_L15N_T2_DQS_35,					Sch name = JD9
#set_property PACKAGE_PIN G2 [get_ports {JD[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[6]}]
##Bank = 35, Pin name = IO_L13N_T2_MRCC_35,					Sch name = JD10
#set_property PACKAGE_PIN F3 [get_ports {JD[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[7]}]
 


##Pmod Header JXADC
##Bank = 15, Pin name = IO_L9P_T1_DQS_AD3P_15,				Sch name = XADC1_P -> XA1_P
#set_property PACKAGE_PIN A13 [get_ports {JXADC[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[0]}]
##Bank = 15, Pin name = IO_L8P_T1_AD10P_15,					Sch name = XADC2_P -> XA2_P
#set_property PACKAGE_PIN A15 [get_ports {JXADC[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[1]}]
##Bank = 15, Pin name = IO_L7P_T1_AD2P_15,					Sch name = XADC3_P -> XA3_P
#set_property PACKAGE_PIN B16 [get_ports {JXADC[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[2]}]
##Bank = 15, Pin name = IO_L10P_T1_AD11P_15,					Sch name = XADC4_P -> XA4_P
#set_property PACKAGE_PIN B18 [get_ports {JXADC[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[3]}]
##Bank = 15, Pin name = IO_L9N_T1_DQS_AD3N_15,				Sch name = XADC1_N -> XA1_N
#set_property PACKAGE_PIN A14 [get_ports {JXADC[4]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[4]}]
##Bank = 15, Pin name = IO_L8N_T1_AD10N_15,					Sch name = XADC2_N -> XA2_N
#set_property PACKAGE_PIN A16 [get_ports {JXADC[5]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[5]}]
##Bank = 15, Pin name = IO_L7N_T1_AD2N_15,					Sch name = XADC3_N -> XA3_N 
#set_property PACKAGE_PIN B17 [get_ports {JXADC[6]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[6]}]
##Bank = 15, Pin name = IO_L10N_T1_AD11N_15,					Sch name = XADC4_N -> XA4_N
#set_property PACKAGE_PIN A18 [get_ports {JXADC[7]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[7]}]



##VGA Connector
##Bank = 35, Pin name = IO_L8N_T1_AD14N_35,					Sch name = VGA_R0
#set_property PACKAGE_PIN A3 [get_ports {vgaRed[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[0]}]
##Bank = 35, Pin name = IO_L7N_T1_AD6N_35,					Sch name = VGA_R1
#set_property PACKAGE_PIN B4 [get_ports {vgaRed[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[1]}]
##Bank = 35, Pin name = IO_L1N_T0_AD4N_35,					Sch name = VGA_R2
#set_property PACKAGE_PIN C5 [get_ports {vgaRed[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[2]}]
##Bank = 35, Pin name = IO_L8P_T1_AD14P_35,					Sch name = VGA_R3
#set_property PACKAGE_PIN A4 [get_ports {vgaRed[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[3]}]
##Bank = 35, Pin name = IO_L2P_T0_AD12P_35,					Sch name = VGA_B0
#set_property PACKAGE_PIN B7 [get_ports {vgaBlue[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[0]}]
##Bank = 35, Pin name = IO_L4N_T0_35,						Sch name = VGA_B1
#set_property PACKAGE_PIN C7 [get_ports {vgaBlue[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[1]}]
##Bank = 35, Pin name = IO_L6N_T0_VREF_35,					Sch name = VGA_B2
#set_property PACKAGE_PIN D7 [get_ports {vgaBlue[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[2]}]
##Bank = 35, Pin name = IO_L4P_T0_35,						Sch name = VGA_B3
#set_property PACKAGE_PIN D8 [get_ports {vgaBlue[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[3]}]
##Bank = 35, Pin name = IO_L1P_T0_AD4P_35,					Sch name = VGA_G0
#set_property PACKAGE_PIN C6 [get_ports {vgaGreen[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[0]}]
##Bank = 35, Pin name = IO_L3N_T0_DQS_AD5N_35,				Sch name = VGA_G1
#set_property PACKAGE_PIN A5 [get_ports {vgaGreen[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[1]}]
##Bank = 35, Pin name = IO_L2N_T0_AD12N_35,					Sch name = VGA_G2
#set_property PACKAGE_PIN B6 [get_ports {vgaGreen[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[2]}]
##Bank = 35, Pin name = IO_L3P_T0_DQS_AD5P_35,				Sch name = VGA_G3
#set_property PACKAGE_PIN A6 [get_ports {vgaGreen[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[3]}]
##Bank = 15, Pin name = IO_L4P_T0_15,						Sch name = VGA_HS
#set_property PACKAGE_PIN B11 [get_ports Hsync]						
	#set_property IOSTANDARD LVCMOS33 [get_ports Hsync]
##Bank = 15, Pin name = IO_L3N_T0_DQS_AD1N_15,				Sch name = VGA_VS
#set_property PACKAGE_PIN B12 [get_ports Vsync]						
	#set_property IOSTANDARD LVCMOS33 [get_ports Vsync]



##Micro SD Connector
##Bank = 35, Pin name = IO_L14P_T2_SRCC_35,					Sch name = SD_RESET
#set_property PACKAGE_PIN E2 [get_ports sdReset]					
	#set_property IOSTANDARD LVCMOS33 [get_ports sdReset]
##Bank = 35, Pin name = IO_L9N_T1_DQS_AD7N_35,				Sch name = SD_CD
#set_property PACKAGE_PIN A1 [get_ports sdCD]						
	#set_property IOSTANDARD LVCMOS33 [get_ports sdCD]
##Bank = 35, Pin name = IO_L9P_T1_DQS_AD7P_35,				Sch name = SD_SCK
#set_property PACKAGE_PIN B1 [get_ports sdSCK]						
	#set_property IOSTANDARD LVCMOS33 [get_ports sdSCK]
##Bank = 35, Pin name = IO_L16N_T2_35,						Sch name = SD_CMD
#set_property PACKAGE_PIN C1 [get_ports sdCmd]						
	#set_property IOSTANDARD LVCMOS33 [get_ports sdCmd]
##Bank = 35, Pin name = IO_L16P_T2_35,						Sch name = SD_DAT0
#set_property PACKAGE_PIN C2 [get_ports {sdData[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {sdData[0]}]
##Bank = 35, Pin name = IO_L18N_T2_35,						Sch name = SD_DAT1
#set_property PACKAGE_PIN E1 [get_ports {sdData[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {sdData[1]}]
##Bank = 35, Pin name = IO_L18P_T2_35,						Sch name = SD_DAT2
#set_property PACKAGE_PIN F1 [get_ports {sdData[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {sdData[2]}]
##Bank = 35, Pin name = IO_L14N_T2_SRCC_35,					Sch name = SD_DAT3
#set_property PACKAGE_PIN D2 [get_ports {sdData[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {sdData[3]}]



##Accelerometer
##Bank = 15, Pin name = IO_L6N_T0_VREF_15,					Sch name = ACL_MISO
#set_property PACKAGE_PIN D13 [get_ports aclMISO]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclMISO]
##Bank = 15, Pin name = IO_L2N_T0_AD8N_15,					Sch name = ACL_MOSI
#set_property PACKAGE_PIN B14 [get_ports aclMOSI]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclMOSI]
##Bank = 15, Pin name = IO_L12P_T1_MRCC_15,					Sch name = ACL_SCLK
#set_property PACKAGE_PIN D15 [get_ports aclSCK]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclSCK]
##Bank = 15, Pin name = IO_L12N_T1_MRCC_15,					Sch name = ACL_CSN
#set_property PACKAGE_PIN C15 [get_ports aclSS]						
	#set_property IOSTANDARD LVCMOS33 [get_ports aclSS]
##Bank = 15, Pin name = IO_L20P_T3_A20_15,					Sch name = ACL_INT1
#set_property PACKAGE_PIN C16 [get_ports aclInt1]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclInt1]
##Bank = 15, Pin name = IO_L11P_T1_SRCC_15,					Sch name = ACL_INT2
#set_property PACKAGE_PIN E15 [get_ports aclInt2]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclInt2]



##Temperature Sensor
##Bank = 15, Pin name = IO_L14N_T2_SRCC_15,					Sch name = TMP_SCL
#set_property PACKAGE_PIN F16 [get_ports tmpSCL]					
	#set_property IOSTANDARD LVCMOS33 [get_ports tmpSCL]
##Bank = 15, Pin name = IO_L13N_T2_MRCC_15,					Sch name = TMP_SDA
#set_property PACKAGE_PIN G16 [get_ports tmpSDA]					
	#set_property IOSTANDARD LVCMOS33 [get_ports tmpSDA]
##Bank = 15, Pin name = IO_L1P_T0_AD0P_15,					Sch name = TMP_INT
#set_property PACKAGE_PIN D14 [get_ports tmpInt]					
	#set_property IOSTANDARD LVCMOS33 [get_ports tmpInt]
##Bank = 15, Pin name = IO_L1N_T0_AD0N_15,					Sch name = TMP_CT
#set_property PACKAGE_PIN C14 [get_ports tmpCT]						
	#set_property IOSTANDARD LVCMOS33 [get_ports tmpCT]



##Omnidirectional Microphone
##Bank = 35, Pin name = IO_25_35,							Sch name = M_CLK
#set_property PACKAGE_PIN J5 [get_ports micClk]						
	#set_property IOSTANDARD LVCMOS33 [get_ports micClk]
##Bank = 35, Pin name = IO_L24N_T3_35,						Sch name = M_DATA
#set_property PACKAGE_PIN H5 [get_ports micData]					
	#set_property IOSTANDARD LVCMOS33 [get_ports micData]
##Bank = 35, Pin name = IO_0_35,								Sch name = M_LRSEL
#set_property PACKAGE_PIN F5 [get_ports micLRSel]					
	#set_property IOSTANDARD LVCMOS33 [get_ports micLRSel]



##PWM Audio Amplifier
##Bank = 15, Pin name = IO_L4N_T0_15,						Sch name = AUD_PWM
#set_property PACKAGE_PIN A11 [get_ports ampPWM]					
	#set_property IOSTANDARD LVCMOS33 [get_ports ampPWM]
##Bank = 15, Pin name = IO_L6P_T0_15,						Sch name = AUD_SD
#set_property PACKAGE_PIN D12 [get_ports ampSD]						
	#set_property IOSTANDARD LVCMOS33 [get_ports ampSD]


##USB-RS232 Interface
##Bank = 35, Pin name = IO_L7P_T1_AD6P_35,					Sch name = UART_TXD_IN
#set_property PACKAGE_PIN C4 [get_ports RsRx]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsRx]
##Bank = 35, Pin name = IO_L11N_T1_SRCC_35,					Sch name = UART_RXD_OUT
#set_property PACKAGE_PIN D4 [get_ports RsTx]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsTx]
##Bank = 35, Pin name = IO_L12N_T1_MRCC_35,					Sch name = UART_CTS
#set_property PACKAGE_PIN D3 [get_ports RsCts]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsCts]
##Bank = 35, Pin name = IO_L5N_T0_AD13N_35,					Sch name = UART_RTS
#set_property PACKAGE_PIN E5 [get_ports RsRts]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsRts]



##USB HID (PS/2)
##Bank = 35, Pin name = IO_L13P_T2_MRCC_35,					Sch name = PS2_CLK
#set_property PACKAGE_PIN F4 [get_ports PS2Clk]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Clk]
	#set_property PULLUP true [get_ports PS2Clk]
##Bank = 35, Pin name = IO_L10N_T1_AD15N_35,					Sch name = PS2_DATA
#set_property PACKAGE_PIN B2 [get_ports PS2Data]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Data]	
	#set_property PULLUP true [get_ports PS2Data]



##SMSC Ethernet PHY
##Bank = 16, Pin name = IO_L11P_T1_SRCC_16,					Sch name = ETH_MDC
#set_property PACKAGE_PIN C9 [get_ports PhyMdc]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyMdc]
##Bank = 16, Pin name = IO_L14N_T2_SRCC_16,					Sch name = ETH_MDIO
#set_property PACKAGE_PIN A9 [get_ports PhyMdio]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyMdio]
##Bank = 35, Pin name = IO_L10P_T1_AD15P_35,					Sch name = ETH_RSTN
#set_property PACKAGE_PIN B3 [get_ports PhyRstn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyRstn]
##Bank = 16, Pin name = IO_L6N_T0_VREF_16,					Sch name = ETH_CRSDV
#set_property PACKAGE_PIN D9 [get_ports PhyCrs]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyCrs]
##Bank = 16, Pin name = IO_L13N_T2_MRCC_16,					Sch name = ETH_RXERR
#set_property PACKAGE_PIN C10 [get_ports PhyRxErr]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyRxErr]
##Bank = 16, Pin name = IO_L19N_T3_VREF_16,					Sch name = ETH_RXD0
#set_property PACKAGE_PIN D10 [get_ports {PhyRxd[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {PhyRxd[0]}]
##Bank = 16, Pin name = IO_L13P_T2_MRCC_16,					Sch name = ETH_RXD1
#set_property PACKAGE_PIN C11 [get_ports {PhyRxd[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {PhyRxd[1]}]
##Bank = 16, Pin name = IO_L11N_T1_SRCC_16,					Sch name = ETH_TXEN
#set_property PACKAGE_PIN B9 [get_ports PhyTxEn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyTxEn]
##Bank = 16, Pin name = IO_L14P_T2_SRCC_16,					Sch name = ETH_TXD0
#set_property PACKAGE_PIN A10 [get_ports {PhyTxd[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {PhyTxd[0]}]
##Bank = 16, Pin name = IO_L12N_T1_MRCC_16,					Sch name = ETH_TXD1
#set_property PACKAGE_PIN A8 [get_ports {PhyTxd[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {PhyTxd[1]}]
##Bank = 35, Pin name = IO_L11P_T1_SRCC_35,					Sch name = ETH_REFCLK
#set_property PACKAGE_PIN D5 [get_ports PhyClk50Mhz]				
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyClk50Mhz]
##Bank = 16, Pin name = IO_L12P_T1_MRCC_16,					Sch name = ETH_INTN
#set_property PACKAGE_PIN B8 [get_ports PhyIntn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyIntn]



##Quad SPI Flash
##Bank = CONFIG, Pin name = CCLK_0,							Sch name = QSPI_SCK
#set_property PACKAGE_PIN E9 [get_ports {QspiSCK}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiSCK}]
##Bank = CONFIG, Pin name = IO_L1P_T0_D00_MOSI_14,			Sch name = QSPI_DQ0
#set_property PACKAGE_PIN K17 [get_ports {QspiDB[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[0]}]
##Bank = CONFIG, Pin name = IO_L1N_T0_D01_DIN_14,			Sch name = QSPI_DQ1
#set_property PACKAGE_PIN K18 [get_ports {QspiDB[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[1]}]
##Bank = CONFIG, Pin name = IO_L20_T0_D02_14,				Sch name = QSPI_DQ2
#set_property PACKAGE_PIN L14 [get_ports {QspiDB[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[2]}]
##Bank = CONFIG, Pin name = IO_L2P_T0_D03_14,				Sch name = QSPI_DQ3
#set_property PACKAGE_PIN M14 [get_ports {QspiDB[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[3]}]
#Bank = CONFIG, Pin name = IO_L15N_T2_DQS_DOUT_CSO_B_14,	Sch name = QSPI_CSN
set_property PACKAGE_PIN L13 [get_ports QuadSpiFlashCS]					
	set_property IOSTANDARD LVCMOS33 [get_ports QuadSpiFlashCS]



##Cellular RAM
##Bank = 14, Pin name = IO_L14N_T2_SRCC_14,					Sch name = CRAM_CLK
#set_property PACKAGE_PIN T15 [get_ports RamCLK]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamCLK]
##Bank = 14, Pin name = IO_L23P_T3_A03_D19_14,				Sch name = CRAM_ADVN
#set_property PACKAGE_PIN T13 [get_ports RamADVn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamADVn]
#Bank = 14, Pin name = IO_L4P_T0_D04_14,					Sch name = CRAM_CEN
#set_property PACKAGE_PIN L18 [get_ports RamCS]					
#	set_property IOSTANDARD LVCMOS33 [get_ports RamCS]
##Bank = 15, Pin name = IO_L19P_T3_A22_15,					Sch name = CRAM_CRE
#set_property PACKAGE_PIN J14 [get_ports RamCRE]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamCRE]
#Bank = 15, Pin name = IO_L15P_T2_DQS_15,					Sch name = CRAM_OEN
#set_property PACKAGE_PIN H14 [get_ports MemOE]					
#	set_property IOSTANDARD LVCMOS33 [get_ports MemOE]
#Bank = 14, Pin name = IO_0_14,								Sch name = CRAM_WEN
#set_property PACKAGE_PIN R11 [get_ports MemWR]					
#	set_property IOSTANDARD LVCMOS33 [get_ports MemWR]
##Bank = 15, Pin name = IO_L24N_T3_RS0_15,					Sch name = CRAM_LBN
#set_property PACKAGE_PIN J15 [get_ports RamLBn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamLBn]
##Bank = 15, Pin name = IO_L17N_T2_A25_15,					Sch name = CRAM_UBN
#set_property PACKAGE_PIN J13 [get_ports RamUBn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamUBn
##Bank = 14, Pin name = IO_L14P_T2_SRCC_14,					Sch name = CRAM_WAIT
#set_property PACKAGE_PIN T14 [get_ports RamWait]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamWait]

##Bank = 14, Pin name = IO_L5P_T0_DQ06_14,					Sch name = CRAM_DQ0
#set_property PACKAGE_PIN R12 [get_ports {MemDB[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[0]}]
##Bank = 14, Pin name = IO_L19P_T3_A10_D26_14,				Sch name = CRAM_DQ1
#set_property PACKAGE_PIN T11 [get_ports {MemDB[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[1]}]
##Bank = 14, Pin name = IO_L20P_T3_A08)D24_14,				Sch name = CRAM_DQ2
#set_property PACKAGE_PIN U12 [get_ports {MemDB[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[2]}]
##Bank = 14, Pin name = IO_L5N_T0_D07_14,					Sch name = CRAM_DQ3
#set_property PACKAGE_PIN R13 [get_ports {MemDB[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[3]}]
##Bank = 14, Pin name = IO_L17N_T2_A13_D29_14,				Sch name = CRAM_DQ4
#set_property PACKAGE_PIN U18 [get_ports {MemDB[4]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[4]}]
##Bank = 14, Pin name = IO_L12N_T1_MRCC_14,					Sch name = CRAM_DQ5
#set_property PACKAGE_PIN R17 [get_ports {MemDB[5]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[5]}]
##Bank = 14, Pin name = IO_L7N_T1_D10_14,					Sch name = CRAM_DQ6
#set_property PACKAGE_PIN T18 [get_ports {MemDB[6]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[6]}]
##Bank = 14, Pin name = IO_L7P_T1_D09_14,					Sch name = CRAM_DQ7
#set_property PACKAGE_PIN R18 [get_ports {MemDB[7]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[7]}]
##Bank = 15, Pin name = IO_L22N_T3_A16_15,					Sch name = CRAM_DQ8
#set_property PACKAGE_PIN F18 [get_ports {MemDB[8]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[8]}]
##Bank = 15, Pin name = IO_L22P_T3_A17_15,					Sch name = CRAM_DQ9
#set_property PACKAGE_PIN G18 [get_ports {MemDB[9]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[9]}]
##Bank = 15, Pin name = IO_IO_L18N_T2_A23_15,				Sch name = CRAM_DQ10
#set_property PACKAGE_PIN G17 [get_ports {MemDB[10]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[10]}]
##Bank = 14, Pin name = IO_L4N_T0_D05_14,					Sch name = CRAM_DQ11
#set_property PACKAGE_PIN M18 [get_ports {MemDB[11]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[11]}]
##Bank = 14, Pin name = IO_L10N_T1_D15_14,					Sch name = CRAM_DQ12
#set_property PACKAGE_PIN M17 [get_ports {MemDB[12]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[12]}]
##Bank = 14, Pin name = IO_L9N_T1_DQS_D13_14,				Sch name = CRAM_DQ13
#set_property PACKAGE_PIN P18 [get_ports {MemDB[13]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[13]}]
##Bank = 14, Pin name = IO_L9P_T1_DQS_14,					Sch name = CRAM_DQ14
#set_property PACKAGE_PIN N17 [get_ports {MemDB[14]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[14]}]
##Bank = 14, Pin name = IO_L12P_T1_MRCC_14,					Sch name = CRAM_DQ15
#set_property PACKAGE_PIN P17 [get_ports {MemDB[15]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[15]}]

##Bank = 15, Pin name = IO_L23N_T3_FWE_B_15,					Sch name = CRAM_A0
#set_property PACKAGE_PIN J18 [get_ports {MemAdr[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[0]}]
##Bank = 15, Pin name = IO_L18P_T2_A24_15,					Sch name = CRAM_A1
#set_property PACKAGE_PIN H17 [get_ports {MemAdr[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[1]}]
##Bank = 15, Pin name = IO_L19N_T3_A21_VREF_15,				Sch name = CRAM_A2
#set_property PACKAGE_PIN H15 [get_ports {MemAdr[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[2]}]
##Bank = 15, Pin name = IO_L23P_T3_FOE_B_15,					Sch name = CRAM_A3
#set_property PACKAGE_PIN J17 [get_ports {MemAdr[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[3]}]
##Bank = 15, Pin name = IO_L13P_T2_MRCC_15,					Sch name = CRAM_A4
#set_property PACKAGE_PIN H16 [get_ports {MemAdr[4]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[4]}]
##Bank = 15, Pin name = IO_L24P_T3_RS1_15,					Sch name = CRAM_A5
#set_property PACKAGE_PIN K15 [get_ports {MemAdr[5]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[5]}]
##Bank = 15, Pin name = IO_L17P_T2_A26_15,					Sch name = CRAM_A6
#set_property PACKAGE_PIN K13 [get_ports {MemAdr[6]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[6]}]
##Bank = 14, Pin name = IO_L11P_T1_SRCC_14,					Sch name = CRAM_A7
#set_property PACKAGE_PIN N15 [get_ports {MemAdr[7]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[7]}]
##Bank = 14, Pin name = IO_L16N_T2_SRCC-14,					Sch name = CRAM_A8
#set_property PACKAGE_PIN V16 [get_ports {MemAdr[8]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[8]}]
##Bank = 14, Pin name = IO_L22P_T3_A05_D21_14,				Sch name = CRAM_A9
#set_property PACKAGE_PIN U14 [get_ports {MemAdr[9]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[9]}]
##Bank = 14, Pin name = IO_L22N_T3_A04_D20_14,				Sch name = CRAM_A10
#set_property PACKAGE_PIN V14 [get_ports {MemAdr[10]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[10]}]
##Bank = 14, Pin name = IO_L20N_T3_A07_D23_14,				Sch name = CRAM_A11
#set_property PACKAGE_PIN V12 [get_ports {MemAdr[11]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[11]}]
##Bank = 14, Pin name = IO_L8N_T1_D12_14,					Sch name = CRAM_A12
#set_property PACKAGE_PIN P14 [get_ports {MemAdr[12]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[12]}]
##Bank = 14, Pin name = IO_L18P_T2_A12_D28_14,				Sch name = CRAM_A13
#set_property PACKAGE_PIN U16 [get_ports {MemAdr[13]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[13]}]
##Bank = 14, Pin name = IO_L13N_T2_MRCC_14,					Sch name = CRAM_A14
#set_property PACKAGE_PIN R15 [get_ports {MemAdr[14]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[14]}]
##Bank = 14, Pin name = IO_L8P_T1_D11_14,					Sch name = CRAM_A15
#set_property PACKAGE_PIN N14 [get_ports {MemAdr[15]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[15]}]
##Bank = 14, Pin name = IO_L11N_T1_SRCC_14,					Sch name = CRAM_A16
#set_property PACKAGE_PIN N16 [get_ports {MemAdr[16]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[16]}]
##Bank = 14, Pin name = IO_L6N_T0_D08_VREF_14,				Sch name = CRAM_A17
#set_property PACKAGE_PIN M13 [get_ports {MemAdr[17]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[17]}]
##Bank = 14, Pin name = IO_L18N_T2_A11_D27_14,				Sch name = CRAM_A18
#set_property PACKAGE_PIN V17 [get_ports {MemAdr[18]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[18]}]
##Bank = 14, Pin name = IO_L17P_T2_A14_D30_14,				Sch name = CRAM_A19
#set_property PACKAGE_PIN U17 [get_ports {MemAdr[19]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[19]}]
##Bank = 14, Pin name = IO_L24N_T3_A00_D16_14,				Sch name = CRAM_A20
#set_property PACKAGE_PIN T10 [get_ports {MemAdr[20]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[20]}]
##Bank = 14, Pin name = IO_L10P_T1_D14_14,					Sch name = CRAM_A21
#set_property PACKAGE_PIN M16 [get_ports {MemAdr[21]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[21]}]	
##Bank = 14, Pin name = IO_L23N_T3_A02_D18_14,				Sch name = CRAM_A22
#set_property PACKAGE_PIN U13 [get_ports {MemAdr[22]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[22]}]
## https://github.com/Digilent/digilent-xdc/blob/master/Nexys-4-Master.xdc    
## This file is a general .xdc for the Nexys4 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Revised test_nexys4_verilog.xdc to suit ee354_detour_top.xdc 
## Basically commented out the unused 15 switches Sw15-Sw1 
##           and also commented out the four buttons BtnL, BtnU, BtnR, and BtnD
## Gandhi 1/21/2020

# Clock signal
#Bank = 35, Pin name = IO_L12P_T1_MRCC_35,					Sch name = CLK100MHZ
set_property PACKAGE_PIN E3 [get_ports ClkPort]							
	set_property IOSTANDARD LVCMOS33 [get_ports ClkPort]
	create_clock -add -name ClkPort -period 10.00 [get_ports ClkPort]
 
# Switches
#Bank = 34, Pin name = IO_L21P_T3_DQS_34,					Sch name = Sw0
set_property PACKAGE_PIN J15 [get_ports {Sw0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw0}]
#Bank = 34, Pin name = IO_25_34,							Sch name = Sw1
set_property PACKAGE_PIN L16 [get_ports {Sw1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw1}]
#Bank = 34, Pin name = IO_L23P_T3_34,						Sch name = Sw2
set_property PACKAGE_PIN M13 [get_ports {Sw2}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw2}]
#Bank = 34, Pin name = IO_L19P_T3_34,						Sch name = Sw3
set_property PACKAGE_PIN R15 [get_ports {Sw3}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw3}]
#Bank = 34, Pin name = IO_L19N_T3_VREF_34,					Sch name = Sw4
set_property PACKAGE_PIN R17 [get_ports {Sw4}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw4}]
#Bank = 34, Pin name = IO_L20P_T3_34,						Sch name = Sw5
set_property PACKAGE_PIN T18 [get_ports {Sw5}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw5}]
#Bank = 34, Pin name = IO_L20N_T3_34,						Sch name = Sw6
set_property PACKAGE_PIN U18 [get_ports {Sw6}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw6}]
#Bank = 34, Pin name = IO_L10P_T1_34,						Sch name = Sw7
set_property PACKAGE_PIN R13 [get_ports {Sw7}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw7}]
#Bank = 34, Pin name = IO_L8P_T1-34,						Sch name = Sw8
set_property PACKAGE_PIN T8 [get_ports {Sw8}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw8}]
#Bank = 34, Pin name = IO_L9N_T1_DQS_34,					Sch name = Sw9
set_property PACKAGE_PIN U8 [get_ports {Sw9}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw9}]
#Bank = 34, Pin name = IO_L9P_T1_DQS_34,					Sch name = Sw10
set_property PACKAGE_PIN R16 [get_ports {Sw10}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw10}]
#Bank = 34, Pin name = IO_L11N_T1_MRCC_34,					Sch name = Sw11
set_property PACKAGE_PIN T13 [get_ports {Sw11}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw11}]
#Bank = 34, Pin name = IO_L17N_T2_34,						Sch name = Sw12
set_property PACKAGE_PIN H6 [get_ports {Sw12}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw12}]
#Bank = 34, Pin name = IO_L11P_T1_SRCC_34,					Sch name = Sw13
set_property PACKAGE_PIN U12 [get_ports {Sw13}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw13}]
#Bank = 34, Pin name = IO_L14N_T2_SRCC_34,					Sch name = Sw14
set_property PACKAGE_PIN U11 [get_ports {Sw14}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw14}]
#Bank = 34, Pin name = IO_L14P_T2_SRCC_34,					Sch name = Sw15
set_property PACKAGE_PIN V10 [get_ports {Sw15}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Sw15}]
	
set_false_path -through [get_nets {Sw0}]
set_false_path -through [get_nets {Sw1}]
set_false_path -through [get_nets {Sw2}]
set_false_path -through [get_nets {Sw3}]
set_false_path -through [get_nets {Sw4}]
set_false_path -through [get_nets {Sw5}]
set_false_path -through [get_nets {Sw6}]
set_false_path -through [get_nets {Sw7}]
set_false_path -through [get_nets {Sw8}]
set_false_path -through [get_nets {Sw9}]
set_false_path -through [get_nets {Sw10}]
set_false_path -through [get_nets {Sw11}]
set_false_path -through [get_nets {Sw12}]
set_false_path -through [get_nets {Sw13}]
set_false_path -through [get_nets {Sw14}]
set_false_path -through [get_nets {Sw15}]
 


# LEDs
#Bank = 34, Pin name = IO_L24N_T3_34,						Sch name = LED0
set_property PACKAGE_PIN H17 [get_ports {Ld0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld0}]
#Bank = 34, Pin name = IO_L21N_T3_DQS_34,					Sch name = LED1
set_property PACKAGE_PIN K15 [get_ports {Ld1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld1}]
#Bank = 34, Pin name = IO_L24P_T3_34,						Sch name = LED2
set_property PACKAGE_PIN J13 [get_ports {Ld2}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld2}]
#Bank = 34, Pin name = IO_L23N_T3_34,						Sch name = LED3
set_property PACKAGE_PIN N14 [get_ports {Ld3}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld3}]
#Bank = 34, Pin name = IO_L12P_T1_MRCC_34,					Sch name = LED4
set_property PACKAGE_PIN R18 [get_ports {Ld4}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld4}]
#Bank = 34, Pin name = IO_L12N_T1_MRCC_34,					Sch	name = LED5
set_property PACKAGE_PIN V17 [get_ports {Ld5}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld5}]
#Bank = 34, Pin name = IO_L22P_T3_34,						Sch name = LED6
set_property PACKAGE_PIN U17 [get_ports {Ld6}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld6}]
#Bank = 34, Pin name = IO_L22N_T3_34,						Sch name = LED7
set_property PACKAGE_PIN U16 [get_ports {Ld7}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld7}]
#Bank = 34, Pin name = IO_L10N_T1_34,						Sch name = LED8
set_property PACKAGE_PIN V16 [get_ports {Ld8}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld8}]
#Bank = 34, Pin name = IO_L8N_T1_34,						Sch name = LED9
set_property PACKAGE_PIN T15 [get_ports {Ld9}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld9}]
#Bank = 34, Pin name = IO_L7N_T1_34,						Sch name = LED10
set_property PACKAGE_PIN U14 [get_ports {Ld10}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld10}]
#Bank = 34, Pin name = IO_L17P_T2_34,						Sch name = LED11
set_property PACKAGE_PIN T16 [get_ports {Ld11}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld11}]
#Bank = 34, Pin name = IO_L13N_T2_MRCC_34,					Sch name = LED12
set_property PACKAGE_PIN V15 [get_ports {Ld12}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld12}]
#Bank = 34, Pin name = IO_L7P_T1_34,						Sch name = LED13
set_property PACKAGE_PIN V14 [get_ports {Ld13}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld13}]
#Bank = 34, Pin name = IO_L15N_T2_DQS_34,					Sch name = LED14
set_property PACKAGE_PIN V12 [get_ports {Ld14}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld14}]
#Bank = 34, Pin name = IO_L15P_T2_DQS_34,					Sch name = LED15
set_property PACKAGE_PIN V11 [get_ports {Ld15}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ld15}]
	
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld0}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld1}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld2}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld3}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld4}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld5}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld6}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld7}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld8}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld9}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld10}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld11}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld12}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld13}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld14}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ld15}]]

##Bank = 34, Pin name = IO_L5P_T0_34,						Sch name = LED16_R
#set_property PACKAGE_PIN K5 [get_ports RGB1_Red]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB1_Red]
##Bank = 15, Pin name = IO_L5P_T0_AD9P_15,					Sch name = LED16_G
#set_property PACKAGE_PIN F13 [get_ports RGB1_Green]				
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB1_Green]
##Bank = 35, Pin name = IO_L19N_T3_VREF_35,					Sch name = LED16_B
#set_property PACKAGE_PIN F6 [get_ports RGB1_Blue]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB1_Blue]
##Bank = 34, Pin name = IO_0_34,								Sch name = LED17_R
#set_property PACKAGE_PIN K6 [get_ports RGB2_Red]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB2_Red]
##Bank = 35, Pin name = IO_24P_T3_35,						Sch name =  LED17_G
#set_property PACKAGE_PIN H6 [get_ports RGB2_Green]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB2_Green]
##Bank = CONFIG, Pin name = IO_L3N_T0_DQS_EMCCLK_14,			Sch name = LED17_B
#set_property PACKAGE_PIN L16 [get_ports RGB2_Blue]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RGB2_Blue]



#7 segment display
#Bank = 34, Pin name = IO_L2N_T0_34,						Sch name = Ca
set_property PACKAGE_PIN T10 [get_ports {Ca}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ca}]
#Bank = 34, Pin name = IO_L3N_T0_DQS_34,					Sch name = Cb
set_property PACKAGE_PIN R10 [get_ports {Cb}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cb}]
#Bank = 34, Pin name = IO_L6N_T0_VREF_34,					Sch name = Cc
set_property PACKAGE_PIN K16 [get_ports {Cc}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cc}]
#Bank = 34, Pin name = IO_L5N_T0_34,						Sch name = Cd
set_property PACKAGE_PIN K13 [get_ports {Cd}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cd}]
#Bank = 34, Pin name = IO_L2P_T0_34,						Sch name = Ce
set_property PACKAGE_PIN P15 [get_ports {Ce}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Ce}]
#Bank = 34, Pin name = IO_L4N_T0_34,						Sch name = Cf
set_property PACKAGE_PIN T11 [get_ports {Cf}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cf}]
#Bank = 34, Pin name = IO_L6P_T0_34,						Sch name = Cg
set_property PACKAGE_PIN L18 [get_ports {Cg}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {Cg}]

#Bank = 34, Pin name = IO_L16P_T2_34,						Sch name = Dp
set_property PACKAGE_PIN H15 [get_ports Dp]							
	set_property IOSTANDARD LVCMOS33 [get_ports Dp]

#Bank = 34, Pin name = IO_L18N_T2_34,						Sch name = An0
set_property PACKAGE_PIN J17 [get_ports {An0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An0}]
#Bank = 34, Pin name = IO_L18P_T2_34,						Sch name = An1
set_property PACKAGE_PIN J18 [get_ports {An1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An1}]
#Bank = 34, Pin name = IO_L4P_T0_34,						Sch name = An2
set_property PACKAGE_PIN T9 [get_ports {An2}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An2}]
#Bank = 34, Pin name = IO_L13_T2_MRCC_34,					Sch name = An3
set_property PACKAGE_PIN J14 [get_ports {An3}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An3}]
#Bank = 34, Pin name = IO_L3P_T0_DQS_34,					Sch name = An4
set_property PACKAGE_PIN P14 [get_ports {An4}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An4}]
#Bank = 34, Pin name = IO_L16N_T2_34,						Sch name = An5
set_property PACKAGE_PIN T14 [get_ports {An5}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An5}]
#Bank = 34, Pin name = IO_L1P_T0_34,						Sch name = An6
set_property PACKAGE_PIN K2 [get_ports {An6}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An6}]
#Bank = 34, Pin name = IO_L1N_T034,							Sch name = An7
set_property PACKAGE_PIN U13 [get_ports {An7}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {An7}]

set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ca}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cb}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cc}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cd}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Ce}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cf}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Cg}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {Dp}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An0}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An1}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An2}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An3}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An4}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An5}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An6}]]
set_false_path -from [all_registers -edge_triggered] -to [all_fanout -endpoints_only -flat -from [get_nets {An7}]]

#Buttons
##Bank = 15, Pin name = IO_L3P_T0_DQS_AD1P_15,				Sch name = CPU_RESET
#set_property PACKAGE_PIN C12 [get_ports btnCpuReset]				
#	set_property IOSTANDARD LVCMOS33 [get_ports btnCpuReset]
#Bank = 15, Pin name = IO_L11N_T1_SRCC_15,					Sch name = BTNC
set_property PACKAGE_PIN N17 [get_ports BtnC]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnC]
#Bank = 15, Pin name = IO_L14P_T2_SRCC_15,					Sch name = BTNU
set_property PACKAGE_PIN M18 [get_ports BtnU]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnU]
#Bank = CONFIG, Pin name = IO_L15N_T2_DQS_DOUT_CSO_B_14,	Sch name = BTNL
set_property PACKAGE_PIN P17 [get_ports BtnL]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnL]
#Bank = 14, Pin name = IO_25_14,							Sch name = BTNR
set_property PACKAGE_PIN M17 [get_ports BtnR]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnR]
#Bank = 14, Pin name = IO_L21P_T3_DQS_14,					Sch name = BTND
set_property PACKAGE_PIN P18 [get_ports BtnD]						
	set_property IOSTANDARD LVCMOS33 [get_ports BtnD]

set_false_path -through [get_nets {BtnC}]
set_false_path -through [get_nets {BtnU}]
set_false_path -through [get_nets {BtnL}]
set_false_path -through [get_nets {BtnR}]
set_false_path -through [get_nets {BtnD}]

##Pmod Header JA
##Bank = 15, Pin name = IO_L1N_T0_AD0N_15,					Sch name = JA1
#set_property PACKAGE_PIN B13 [get_ports {JA[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[0]}]
##Bank = 15, Pin name = IO_L5N_T0_AD9N_15,					Sch name = JA2
#set_property PACKAGE_PIN F14 [get_ports {JA[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[1]}]
##Bank = 15, Pin name = IO_L16N_T2_A27_15,					Sch name = JA3
#set_property PACKAGE_PIN D17 [get_ports {JA[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[2]}]
##Bank = 15, Pin name = IO_L16P_T2_A28_15,					Sch name = JA4
#set_property PACKAGE_PIN E17 [get_ports {JA[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[3]}]
##Bank = 15, Pin name = IO_0_15,								Sch name = JA7
#set_property PACKAGE_PIN G13 [get_ports {JA[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[4]}]
##Bank = 15, Pin name = IO_L20N_T3_A19_15,					Sch name = JA8
#set_property PACKAGE_PIN C17 [get_ports {JA[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[5]}]
##Bank = 15, Pin name = IO_L21N_T3_A17_15,					Sch name = JA9
#set_property PACKAGE_PIN D18 [get_ports {JA[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[6]}]
##Bank = 15, Pin name = IO_L21P_T3_DQS_15,					Sch name = JA10
#set_property PACKAGE_PIN E18 [get_ports {JA[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[7]}]



##Pmod Header JB
##Bank = 15, Pin name = IO_L15N_T2_DQS_ADV_B_15,				Sch name = JB1
#set_property PACKAGE_PIN G14 [get_ports {JB[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[0]}]
##Bank = 14, Pin name = IO_L13P_T2_MRCC_14,					Sch name = JB2
#set_property PACKAGE_PIN P15 [get_ports {JB[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[1]}]
##Bank = 14, Pin name = IO_L21N_T3_DQS_A06_D22_14,			Sch name = JB3
#set_property PACKAGE_PIN V11 [get_ports {JB[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[2]}]
##Bank = CONFIG, Pin name = IO_L16P_T2_CSI_B_14,				Sch name = JB4
#set_property PACKAGE_PIN V15 [get_ports {JB[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[3]}]
##Bank = 15, Pin name = IO_25_15,							Sch name = JB7
#set_property PACKAGE_PIN K16 [get_ports {JB[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[4]}]
##Bank = CONFIG, Pin name = IO_L15P_T2_DQS_RWR_B_14,			Sch name = JB8
#set_property PACKAGE_PIN R16 [get_ports {JB[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[5]}]
##Bank = 14, Pin name = IO_L24P_T3_A01_D17_14,				Sch name = JB9
#set_property PACKAGE_PIN T9 [get_ports {JB[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[6]}]
##Bank = 14, Pin name = IO_L19N_T3_A09_D25_VREF_14,			Sch name = JB10 
#set_property PACKAGE_PIN U11 [get_ports {JB[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[7]}]
 


##Pmod Header JC
##Bank = 35, Pin name = IO_L23P_T3_35,						Sch name = JC1
#set_property PACKAGE_PIN K2 [get_ports {JC[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[0]}]
##Bank = 35, Pin name = IO_L6P_T0_35,						Sch name = JC2
#set_property PACKAGE_PIN E7 [get_ports {JC[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[1]}]
##Bank = 35, Pin name = IO_L22P_T3_35,						Sch name = JC3
#set_property PACKAGE_PIN J3 [get_ports {JC[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[2]}]
##Bank = 35, Pin name = IO_L21P_T3_DQS_35,					Sch name = JC4
#set_property PACKAGE_PIN J4 [get_ports {JC[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[3]}]
##Bank = 35, Pin name = IO_L23N_T3_35,						Sch name = JC7
#set_property PACKAGE_PIN K1 [get_ports {JC[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[4]}]
##Bank = 35, Pin name = IO_L5P_T0_AD13P_35,					Sch name = JC8
#set_property PACKAGE_PIN E6 [get_ports {JC[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[5]}]
##Bank = 35, Pin name = IO_L22N_T3_35,						Sch name = JC9
#set_property PACKAGE_PIN J2 [get_ports {JC[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[6]}]
##Bank = 35, Pin name = IO_L19P_T3_35,						Sch name = JC10
#set_property PACKAGE_PIN G6 [get_ports {JC[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JC[7]}]
 

 
##Pmod Header JD
##Bank = 35, Pin name = IO_L21N_T2_DQS_35,					Sch name = JD1
#set_property PACKAGE_PIN H4 [get_ports {JD[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[0]}]
##Bank = 35, Pin name = IO_L17P_T2_35,						Sch name = JD2
#set_property PACKAGE_PIN H1 [get_ports {JD[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[1]}]
##Bank = 35, Pin name = IO_L17N_T2_35,						Sch name = JD3
#set_property PACKAGE_PIN G1 [get_ports {JD[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[2]}]
##Bank = 35, Pin name = IO_L20N_T3_35,						Sch name = JD4
#set_property PACKAGE_PIN G3 [get_ports {JD[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[3]}]
##Bank = 35, Pin name = IO_L15P_T2_DQS_35,					Sch name = JD7
#set_property PACKAGE_PIN H2 [get_ports {JD[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[4]}]
##Bank = 35, Pin name = IO_L20P_T3_35,						Sch name = JD8
#set_property PACKAGE_PIN G4 [get_ports {JD[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[5]}]
##Bank = 35, Pin name = IO_L15N_T2_DQS_35,					Sch name = JD9
#set_property PACKAGE_PIN G2 [get_ports {JD[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[6]}]
##Bank = 35, Pin name = IO_L13N_T2_MRCC_35,					Sch name = JD10
#set_property PACKAGE_PIN F3 [get_ports {JD[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JD[7]}]
 


##Pmod Header JXADC
##Bank = 15, Pin name = IO_L9P_T1_DQS_AD3P_15,				Sch name = XADC1_P -> XA1_P
#set_property PACKAGE_PIN A13 [get_ports {JXADC[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[0]}]
##Bank = 15, Pin name = IO_L8P_T1_AD10P_15,					Sch name = XADC2_P -> XA2_P
#set_property PACKAGE_PIN A15 [get_ports {JXADC[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[1]}]
##Bank = 15, Pin name = IO_L7P_T1_AD2P_15,					Sch name = XADC3_P -> XA3_P
#set_property PACKAGE_PIN B16 [get_ports {JXADC[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[2]}]
##Bank = 15, Pin name = IO_L10P_T1_AD11P_15,					Sch name = XADC4_P -> XA4_P
#set_property PACKAGE_PIN B18 [get_ports {JXADC[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[3]}]
##Bank = 15, Pin name = IO_L9N_T1_DQS_AD3N_15,				Sch name = XADC1_N -> XA1_N
#set_property PACKAGE_PIN A14 [get_ports {JXADC[4]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[4]}]
##Bank = 15, Pin name = IO_L8N_T1_AD10N_15,					Sch name = XADC2_N -> XA2_N
#set_property PACKAGE_PIN A16 [get_ports {JXADC[5]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[5]}]
##Bank = 15, Pin name = IO_L7N_T1_AD2N_15,					Sch name = XADC3_N -> XA3_N 
#set_property PACKAGE_PIN B17 [get_ports {JXADC[6]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[6]}]
##Bank = 15, Pin name = IO_L10N_T1_AD11N_15,					Sch name = XADC4_N -> XA4_N
#set_property PACKAGE_PIN A18 [get_ports {JXADC[7]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {JXADC[7]}]



##VGA Connector
##Bank = 35, Pin name = IO_L8N_T1_AD14N_35,					Sch name = VGA_R0
#set_property PACKAGE_PIN A3 [get_ports {vgaRed[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[0]}]
##Bank = 35, Pin name = IO_L7N_T1_AD6N_35,					Sch name = VGA_R1
#set_property PACKAGE_PIN B4 [get_ports {vgaRed[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[1]}]
##Bank = 35, Pin name = IO_L1N_T0_AD4N_35,					Sch name = VGA_R2
#set_property PACKAGE_PIN C5 [get_ports {vgaRed[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[2]}]
##Bank = 35, Pin name = IO_L8P_T1_AD14P_35,					Sch name = VGA_R3
#set_property PACKAGE_PIN A4 [get_ports {vgaRed[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaRed[3]}]
##Bank = 35, Pin name = IO_L2P_T0_AD12P_35,					Sch name = VGA_B0
#set_property PACKAGE_PIN B7 [get_ports {vgaBlue[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[0]}]
##Bank = 35, Pin name = IO_L4N_T0_35,						Sch name = VGA_B1
#set_property PACKAGE_PIN C7 [get_ports {vgaBlue[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[1]}]
##Bank = 35, Pin name = IO_L6N_T0_VREF_35,					Sch name = VGA_B2
#set_property PACKAGE_PIN D7 [get_ports {vgaBlue[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[2]}]
##Bank = 35, Pin name = IO_L4P_T0_35,						Sch name = VGA_B3
#set_property PACKAGE_PIN D8 [get_ports {vgaBlue[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaBlue[3]}]
##Bank = 35, Pin name = IO_L1P_T0_AD4P_35,					Sch name = VGA_G0
#set_property PACKAGE_PIN C6 [get_ports {vgaGreen[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[0]}]
##Bank = 35, Pin name = IO_L3N_T0_DQS_AD5N_35,				Sch name = VGA_G1
#set_property PACKAGE_PIN A5 [get_ports {vgaGreen[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[1]}]
##Bank = 35, Pin name = IO_L2N_T0_AD12N_35,					Sch name = VGA_G2
#set_property PACKAGE_PIN B6 [get_ports {vgaGreen[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[2]}]
##Bank = 35, Pin name = IO_L3P_T0_DQS_AD5P_35,				Sch name = VGA_G3
#set_property PACKAGE_PIN A6 [get_ports {vgaGreen[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {vgaGreen[3]}]
##Bank = 15, Pin name = IO_L4P_T0_15,						Sch name = VGA_HS
#set_property PACKAGE_PIN B11 [get_ports Hsync]						
	#set_property IOSTANDARD LVCMOS33 [get_ports Hsync]
##Bank = 15, Pin name = IO_L3N_T0_DQS_AD1N_15,				Sch name = VGA_VS
#set_property PACKAGE_PIN B12 [get_ports Vsync]						
	#set_property IOSTANDARD LVCMOS33 [get_ports Vsync]



##Micro SD Connector
##Bank = 35, Pin name = IO_L14P_T2_SRCC_35,					Sch name = SD_RESET
#set_property PACKAGE_PIN E2 [get_ports sdReset]					
	#set_property IOSTANDARD LVCMOS33 [get_ports sdReset]
##Bank = 35, Pin name = IO_L9N_T1_DQS_AD7N_35,				Sch name = SD_CD
#set_property PACKAGE_PIN A1 [get_ports sdCD]						
	#set_property IOSTANDARD LVCMOS33 [get_ports sdCD]
##Bank = 35, Pin name = IO_L9P_T1_DQS_AD7P_35,				Sch name = SD_SCK
#set_property PACKAGE_PIN B1 [get_ports sdSCK]						
	#set_property IOSTANDARD LVCMOS33 [get_ports sdSCK]
##Bank = 35, Pin name = IO_L16N_T2_35,						Sch name = SD_CMD
#set_property PACKAGE_PIN C1 [get_ports sdCmd]						
	#set_property IOSTANDARD LVCMOS33 [get_ports sdCmd]
##Bank = 35, Pin name = IO_L16P_T2_35,						Sch name = SD_DAT0
#set_property PACKAGE_PIN C2 [get_ports {sdData[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {sdData[0]}]
##Bank = 35, Pin name = IO_L18N_T2_35,						Sch name = SD_DAT1
#set_property PACKAGE_PIN E1 [get_ports {sdData[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {sdData[1]}]
##Bank = 35, Pin name = IO_L18P_T2_35,						Sch name = SD_DAT2
#set_property PACKAGE_PIN F1 [get_ports {sdData[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {sdData[2]}]
##Bank = 35, Pin name = IO_L14N_T2_SRCC_35,					Sch name = SD_DAT3
#set_property PACKAGE_PIN D2 [get_ports {sdData[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {sdData[3]}]



##Accelerometer
##Bank = 15, Pin name = IO_L6N_T0_VREF_15,					Sch name = ACL_MISO
#set_property PACKAGE_PIN D13 [get_ports aclMISO]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclMISO]
##Bank = 15, Pin name = IO_L2N_T0_AD8N_15,					Sch name = ACL_MOSI
#set_property PACKAGE_PIN B14 [get_ports aclMOSI]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclMOSI]
##Bank = 15, Pin name = IO_L12P_T1_MRCC_15,					Sch name = ACL_SCLK
#set_property PACKAGE_PIN D15 [get_ports aclSCK]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclSCK]
##Bank = 15, Pin name = IO_L12N_T1_MRCC_15,					Sch name = ACL_CSN
#set_property PACKAGE_PIN C15 [get_ports aclSS]						
	#set_property IOSTANDARD LVCMOS33 [get_ports aclSS]
##Bank = 15, Pin name = IO_L20P_T3_A20_15,					Sch name = ACL_INT1
#set_property PACKAGE_PIN C16 [get_ports aclInt1]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclInt1]
##Bank = 15, Pin name = IO_L11P_T1_SRCC_15,					Sch name = ACL_INT2
#set_property PACKAGE_PIN E15 [get_ports aclInt2]					
	#set_property IOSTANDARD LVCMOS33 [get_ports aclInt2]



##Temperature Sensor
##Bank = 15, Pin name = IO_L14N_T2_SRCC_15,					Sch name = TMP_SCL
#set_property PACKAGE_PIN F16 [get_ports tmpSCL]					
	#set_property IOSTANDARD LVCMOS33 [get_ports tmpSCL]
##Bank = 15, Pin name = IO_L13N_T2_MRCC_15,					Sch name = TMP_SDA
#set_property PACKAGE_PIN G16 [get_ports tmpSDA]					
	#set_property IOSTANDARD LVCMOS33 [get_ports tmpSDA]
##Bank = 15, Pin name = IO_L1P_T0_AD0P_15,					Sch name = TMP_INT
#set_property PACKAGE_PIN D14 [get_ports tmpInt]					
	#set_property IOSTANDARD LVCMOS33 [get_ports tmpInt]
##Bank = 15, Pin name = IO_L1N_T0_AD0N_15,					Sch name = TMP_CT
#set_property PACKAGE_PIN C14 [get_ports tmpCT]						
	#set_property IOSTANDARD LVCMOS33 [get_ports tmpCT]



##Omnidirectional Microphone
##Bank = 35, Pin name = IO_25_35,							Sch name = M_CLK
#set_property PACKAGE_PIN J5 [get_ports micClk]						
	#set_property IOSTANDARD LVCMOS33 [get_ports micClk]
##Bank = 35, Pin name = IO_L24N_T3_35,						Sch name = M_DATA
#set_property PACKAGE_PIN H5 [get_ports micData]					
	#set_property IOSTANDARD LVCMOS33 [get_ports micData]
##Bank = 35, Pin name = IO_0_35,								Sch name = M_LRSEL
#set_property PACKAGE_PIN F5 [get_ports micLRSel]					
	#set_property IOSTANDARD LVCMOS33 [get_ports micLRSel]



##PWM Audio Amplifier
##Bank = 15, Pin name = IO_L4N_T0_15,						Sch name = AUD_PWM
#set_property PACKAGE_PIN A11 [get_ports ampPWM]					
	#set_property IOSTANDARD LVCMOS33 [get_ports ampPWM]
##Bank = 15, Pin name = IO_L6P_T0_15,						Sch name = AUD_SD
#set_property PACKAGE_PIN D12 [get_ports ampSD]						
	#set_property IOSTANDARD LVCMOS33 [get_ports ampSD]


##USB-RS232 Interface
##Bank = 35, Pin name = IO_L7P_T1_AD6P_35,					Sch name = UART_TXD_IN
#set_property PACKAGE_PIN C4 [get_ports RsRx]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsRx]
##Bank = 35, Pin name = IO_L11N_T1_SRCC_35,					Sch name = UART_RXD_OUT
#set_property PACKAGE_PIN D4 [get_ports RsTx]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsTx]
##Bank = 35, Pin name = IO_L12N_T1_MRCC_35,					Sch name = UART_CTS
#set_property PACKAGE_PIN D3 [get_ports RsCts]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsCts]
##Bank = 35, Pin name = IO_L5N_T0_AD13N_35,					Sch name = UART_RTS
#set_property PACKAGE_PIN E5 [get_ports RsRts]						
	#set_property IOSTANDARD LVCMOS33 [get_ports RsRts]



##USB HID (PS/2)
##Bank = 35, Pin name = IO_L13P_T2_MRCC_35,					Sch name = PS2_CLK
#set_property PACKAGE_PIN F4 [get_ports PS2Clk]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Clk]
	#set_property PULLUP true [get_ports PS2Clk]
##Bank = 35, Pin name = IO_L10N_T1_AD15N_35,					Sch name = PS2_DATA
#set_property PACKAGE_PIN B2 [get_ports PS2Data]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PS2Data]	
	#set_property PULLUP true [get_ports PS2Data]



##SMSC Ethernet PHY
##Bank = 16, Pin name = IO_L11P_T1_SRCC_16,					Sch name = ETH_MDC
#set_property PACKAGE_PIN C9 [get_ports PhyMdc]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyMdc]
##Bank = 16, Pin name = IO_L14N_T2_SRCC_16,					Sch name = ETH_MDIO
#set_property PACKAGE_PIN A9 [get_ports PhyMdio]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyMdio]
##Bank = 35, Pin name = IO_L10P_T1_AD15P_35,					Sch name = ETH_RSTN
#set_property PACKAGE_PIN B3 [get_ports PhyRstn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyRstn]
##Bank = 16, Pin name = IO_L6N_T0_VREF_16,					Sch name = ETH_CRSDV
#set_property PACKAGE_PIN D9 [get_ports PhyCrs]						
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyCrs]
##Bank = 16, Pin name = IO_L13N_T2_MRCC_16,					Sch name = ETH_RXERR
#set_property PACKAGE_PIN C10 [get_ports PhyRxErr]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyRxErr]
##Bank = 16, Pin name = IO_L19N_T3_VREF_16,					Sch name = ETH_RXD0
#set_property PACKAGE_PIN D10 [get_ports {PhyRxd[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {PhyRxd[0]}]
##Bank = 16, Pin name = IO_L13P_T2_MRCC_16,					Sch name = ETH_RXD1
#set_property PACKAGE_PIN C11 [get_ports {PhyRxd[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {PhyRxd[1]}]
##Bank = 16, Pin name = IO_L11N_T1_SRCC_16,					Sch name = ETH_TXEN
#set_property PACKAGE_PIN B9 [get_ports PhyTxEn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyTxEn]
##Bank = 16, Pin name = IO_L14P_T2_SRCC_16,					Sch name = ETH_TXD0
#set_property PACKAGE_PIN A10 [get_ports {PhyTxd[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {PhyTxd[0]}]
##Bank = 16, Pin name = IO_L12N_T1_MRCC_16,					Sch name = ETH_TXD1
#set_property PACKAGE_PIN A8 [get_ports {PhyTxd[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {PhyTxd[1]}]
##Bank = 35, Pin name = IO_L11P_T1_SRCC_35,					Sch name = ETH_REFCLK
#set_property PACKAGE_PIN D5 [get_ports PhyClk50Mhz]				
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyClk50Mhz]
##Bank = 16, Pin name = IO_L12P_T1_MRCC_16,					Sch name = ETH_INTN
#set_property PACKAGE_PIN B8 [get_ports PhyIntn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports PhyIntn]



##Quad SPI Flash
##Bank = CONFIG, Pin name = CCLK_0,							Sch name = QSPI_SCK
#set_property PACKAGE_PIN E9 [get_ports {QspiSCK}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiSCK}]
##Bank = CONFIG, Pin name = IO_L1P_T0_D00_MOSI_14,			Sch name = QSPI_DQ0
#set_property PACKAGE_PIN K17 [get_ports {QspiDB[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[0]}]
##Bank = CONFIG, Pin name = IO_L1N_T0_D01_DIN_14,			Sch name = QSPI_DQ1
#set_property PACKAGE_PIN K18 [get_ports {QspiDB[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[1]}]
##Bank = CONFIG, Pin name = IO_L20_T0_D02_14,				Sch name = QSPI_DQ2
#set_property PACKAGE_PIN L14 [get_ports {QspiDB[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[2]}]
##Bank = CONFIG, Pin name = IO_L2P_T0_D03_14,				Sch name = QSPI_DQ3
#set_property PACKAGE_PIN M14 [get_ports {QspiDB[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {QspiDB[3]}]
#Bank = CONFIG, Pin name = IO_L15N_T2_DQS_DOUT_CSO_B_14,	Sch name = QSPI_CSN
set_property PACKAGE_PIN L13 [get_ports QuadSpiFlashCS]					
	set_property IOSTANDARD LVCMOS33 [get_ports QuadSpiFlashCS]



##Cellular RAM
##Bank = 14, Pin name = IO_L14N_T2_SRCC_14,					Sch name = CRAM_CLK
#set_property PACKAGE_PIN T15 [get_ports RamCLK]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamCLK]
##Bank = 14, Pin name = IO_L23P_T3_A03_D19_14,				Sch name = CRAM_ADVN
#set_property PACKAGE_PIN T13 [get_ports RamADVn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamADVn]
#Bank = 14, Pin name = IO_L4P_T0_D04_14,					Sch name = CRAM_CEN
#set_property PACKAGE_PIN L18 [get_ports RamCS]					
#	set_property IOSTANDARD LVCMOS33 [get_ports RamCS]
##Bank = 15, Pin name = IO_L19P_T3_A22_15,					Sch name = CRAM_CRE
#set_property PACKAGE_PIN J14 [get_ports RamCRE]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamCRE]
#Bank = 15, Pin name = IO_L15P_T2_DQS_15,					Sch name = CRAM_OEN
#set_property PACKAGE_PIN H14 [get_ports MemOE]					
#	set_property IOSTANDARD LVCMOS33 [get_ports MemOE]
#Bank = 14, Pin name = IO_0_14,								Sch name = CRAM_WEN
#set_property PACKAGE_PIN R11 [get_ports MemWR]					
#	set_property IOSTANDARD LVCMOS33 [get_ports MemWR]
##Bank = 15, Pin name = IO_L24N_T3_RS0_15,					Sch name = CRAM_LBN
#set_property PACKAGE_PIN J15 [get_ports RamLBn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamLBn]
##Bank = 15, Pin name = IO_L17N_T2_A25_15,					Sch name = CRAM_UBN
#set_property PACKAGE_PIN J13 [get_ports RamUBn]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamUBn
##Bank = 14, Pin name = IO_L14P_T2_SRCC_14,					Sch name = CRAM_WAIT
#set_property PACKAGE_PIN T14 [get_ports RamWait]					
	#set_property IOSTANDARD LVCMOS33 [get_ports RamWait]

##Bank = 14, Pin name = IO_L5P_T0_DQ06_14,					Sch name = CRAM_DQ0
#set_property PACKAGE_PIN R12 [get_ports {MemDB[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[0]}]
##Bank = 14, Pin name = IO_L19P_T3_A10_D26_14,				Sch name = CRAM_DQ1
#set_property PACKAGE_PIN T11 [get_ports {MemDB[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[1]}]
##Bank = 14, Pin name = IO_L20P_T3_A08)D24_14,				Sch name = CRAM_DQ2
#set_property PACKAGE_PIN U12 [get_ports {MemDB[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[2]}]
##Bank = 14, Pin name = IO_L5N_T0_D07_14,					Sch name = CRAM_DQ3
#set_property PACKAGE_PIN R13 [get_ports {MemDB[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[3]}]
##Bank = 14, Pin name = IO_L17N_T2_A13_D29_14,				Sch name = CRAM_DQ4
#set_property PACKAGE_PIN U18 [get_ports {MemDB[4]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[4]}]
##Bank = 14, Pin name = IO_L12N_T1_MRCC_14,					Sch name = CRAM_DQ5
#set_property PACKAGE_PIN R17 [get_ports {MemDB[5]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[5]}]
##Bank = 14, Pin name = IO_L7N_T1_D10_14,					Sch name = CRAM_DQ6
#set_property PACKAGE_PIN T18 [get_ports {MemDB[6]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[6]}]
##Bank = 14, Pin name = IO_L7P_T1_D09_14,					Sch name = CRAM_DQ7
#set_property PACKAGE_PIN R18 [get_ports {MemDB[7]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[7]}]
##Bank = 15, Pin name = IO_L22N_T3_A16_15,					Sch name = CRAM_DQ8
#set_property PACKAGE_PIN F18 [get_ports {MemDB[8]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[8]}]
##Bank = 15, Pin name = IO_L22P_T3_A17_15,					Sch name = CRAM_DQ9
#set_property PACKAGE_PIN G18 [get_ports {MemDB[9]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[9]}]
##Bank = 15, Pin name = IO_IO_L18N_T2_A23_15,				Sch name = CRAM_DQ10
#set_property PACKAGE_PIN G17 [get_ports {MemDB[10]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[10]}]
##Bank = 14, Pin name = IO_L4N_T0_D05_14,					Sch name = CRAM_DQ11
#set_property PACKAGE_PIN M18 [get_ports {MemDB[11]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[11]}]
##Bank = 14, Pin name = IO_L10N_T1_D15_14,					Sch name = CRAM_DQ12
#set_property PACKAGE_PIN M17 [get_ports {MemDB[12]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[12]}]
##Bank = 14, Pin name = IO_L9N_T1_DQS_D13_14,				Sch name = CRAM_DQ13
#set_property PACKAGE_PIN P18 [get_ports {MemDB[13]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[13]}]
##Bank = 14, Pin name = IO_L9P_T1_DQS_14,					Sch name = CRAM_DQ14
#set_property PACKAGE_PIN N17 [get_ports {MemDB[14]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[14]}]
##Bank = 14, Pin name = IO_L12P_T1_MRCC_14,					Sch name = CRAM_DQ15
#set_property PACKAGE_PIN P17 [get_ports {MemDB[15]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemDB[15]}]

##Bank = 15, Pin name = IO_L23N_T3_FWE_B_15,					Sch name = CRAM_A0
#set_property PACKAGE_PIN J18 [get_ports {MemAdr[0]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[0]}]
##Bank = 15, Pin name = IO_L18P_T2_A24_15,					Sch name = CRAM_A1
#set_property PACKAGE_PIN H17 [get_ports {MemAdr[1]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[1]}]
##Bank = 15, Pin name = IO_L19N_T3_A21_VREF_15,				Sch name = CRAM_A2
#set_property PACKAGE_PIN H15 [get_ports {MemAdr[2]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[2]}]
##Bank = 15, Pin name = IO_L23P_T3_FOE_B_15,					Sch name = CRAM_A3
#set_property PACKAGE_PIN J17 [get_ports {MemAdr[3]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[3]}]
##Bank = 15, Pin name = IO_L13P_T2_MRCC_15,					Sch name = CRAM_A4
#set_property PACKAGE_PIN H16 [get_ports {MemAdr[4]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[4]}]
##Bank = 15, Pin name = IO_L24P_T3_RS1_15,					Sch name = CRAM_A5
#set_property PACKAGE_PIN K15 [get_ports {MemAdr[5]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[5]}]
##Bank = 15, Pin name = IO_L17P_T2_A26_15,					Sch name = CRAM_A6
#set_property PACKAGE_PIN K13 [get_ports {MemAdr[6]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[6]}]
##Bank = 14, Pin name = IO_L11P_T1_SRCC_14,					Sch name = CRAM_A7
#set_property PACKAGE_PIN N15 [get_ports {MemAdr[7]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[7]}]
##Bank = 14, Pin name = IO_L16N_T2_SRCC-14,					Sch name = CRAM_A8
#set_property PACKAGE_PIN V16 [get_ports {MemAdr[8]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[8]}]
##Bank = 14, Pin name = IO_L22P_T3_A05_D21_14,				Sch name = CRAM_A9
#set_property PACKAGE_PIN U14 [get_ports {MemAdr[9]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[9]}]
##Bank = 14, Pin name = IO_L22N_T3_A04_D20_14,				Sch name = CRAM_A10
#set_property PACKAGE_PIN V14 [get_ports {MemAdr[10]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[10]}]
##Bank = 14, Pin name = IO_L20N_T3_A07_D23_14,				Sch name = CRAM_A11
#set_property PACKAGE_PIN V12 [get_ports {MemAdr[11]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[11]}]
##Bank = 14, Pin name = IO_L8N_T1_D12_14,					Sch name = CRAM_A12
#set_property PACKAGE_PIN P14 [get_ports {MemAdr[12]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[12]}]
##Bank = 14, Pin name = IO_L18P_T2_A12_D28_14,				Sch name = CRAM_A13
#set_property PACKAGE_PIN U16 [get_ports {MemAdr[13]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[13]}]
##Bank = 14, Pin name = IO_L13N_T2_MRCC_14,					Sch name = CRAM_A14
#set_property PACKAGE_PIN R15 [get_ports {MemAdr[14]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[14]}]
##Bank = 14, Pin name = IO_L8P_T1_D11_14,					Sch name = CRAM_A15
#set_property PACKAGE_PIN N14 [get_ports {MemAdr[15]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[15]}]
##Bank = 14, Pin name = IO_L11N_T1_SRCC_14,					Sch name = CRAM_A16
#set_property PACKAGE_PIN N16 [get_ports {MemAdr[16]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[16]}]
##Bank = 14, Pin name = IO_L6N_T0_D08_VREF_14,				Sch name = CRAM_A17
#set_property PACKAGE_PIN M13 [get_ports {MemAdr[17]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[17]}]
##Bank = 14, Pin name = IO_L18N_T2_A11_D27_14,				Sch name = CRAM_A18
#set_property PACKAGE_PIN V17 [get_ports {MemAdr[18]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[18]}]
##Bank = 14, Pin name = IO_L17P_T2_A14_D30_14,				Sch name = CRAM_A19
#set_property PACKAGE_PIN U17 [get_ports {MemAdr[19]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[19]}]
##Bank = 14, Pin name = IO_L24N_T3_A00_D16_14,				Sch name = CRAM_A20
#set_property PACKAGE_PIN T10 [get_ports {MemAdr[20]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[20]}]
##Bank = 14, Pin name = IO_L10P_T1_D14_14,					Sch name = CRAM_A21
#set_property PACKAGE_PIN M16 [get_ports {MemAdr[21]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[21]}]	
##Bank = 14, Pin name = IO_L23N_T3_A02_D18_14,				Sch name = CRAM_A22
#set_property PACKAGE_PIN U13 [get_ports {MemAdr[22]}]				
	#set_property IOSTANDARD LVCMOS33 [get_ports {MemAdr[22]}]

what's wrong with this
ok fix for me
the whole file please
module player(
    input wire clk,
    input wire rst,
    input SW0, BtnC, BtnL, BtnR, BtnU, BtnD,

    output reg [9:0] x,
    output reg [9:0] y,

    output wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
    output wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath
);

//================ STATE =================
reg [10:0] state;

localparam
INIT       = 11'b00000000001,
IDLE       = 11'b00000000010,
LEFT       = 11'b00000000100,
RIGHT      = 11'b00000001000,
DOWN       = 11'b00000010000,
JUMP       = 11'b00000100000,
UPLEFT     = 11'b00001000000,
UPRIGHT    = 11'b00010000000,
DOWNLEFT   = 11'b00100000000,
DOWNRIGHT  = 11'b01000000000, // FIXED (11 bits)
DEATH      = 11'b10000000000;

assign {Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
        Qupleft, Qupright, Qdownleft, Qdownright, Qdeath} = state;

//================ FLAGS =================
reg jumpflag;
reg [10:0] jumpcount, dashcount;

//================ FSM =================
always @(posedge clk) begin
    if (rst) begin
        state <= INIT;
        x <= 10;
        y <= 10;
        jumpflag <= 0;
    end
    else begin
        case(state)

        INIT: begin
            x <= 0;
            y <= 0;
            jumpflag <= 0;
            state <= IDLE;
        end

        IDLE: begin
            jumpflag <= 0;

            // PRIORITY ORDER FIXED
            if (BtnU & BtnL)       state <= UPLEFT;
            else if (BtnU & BtnR)  state <= UPRIGHT;
            else if (BtnD & BtnL)  state <= DOWNLEFT;
            else if (BtnD & BtnR)  state <= DOWNRIGHT;
            else if (BtnL)         state <= LEFT;
            else if (BtnR)         state <= RIGHT;
            else if (BtnU)         state <= JUMP;
            else if (BtnD)         state <= DOWN;
        end

        LEFT: begin
            if (x > 0)
                x <= x - 1;

            if (!BtnL)
                state <= IDLE;
        end

        RIGHT: begin
            if (x < 10'b1111111111)
                x <= x + 1;

            if (!BtnR)
                state <= IDLE;
        end

        DOWN: begin
            if (y > 0)
                y <= y - 1;

            if (!BtnD)
                state <= IDLE;
        end

        JUMP: begin
            if (y < 10'b1111111111) begin
                y <= y + 20;
                jumpflag <= 1;
            end
            state <= IDLE;
        end

        UPLEFT: begin
            jumpflag <= 1;

            if (y < 10'b1111111111)
                y <= y + 20;

            if (x > 0)
                x <= x - 1;

            if (BtnL)
                state <= LEFT;
            else
                state <= IDLE;
        end

        UPRIGHT: begin
            jumpflag <= 1;

            if (y < 10'b1111111111)
                y <= y + 20;

            if (x < 10'b1111111111)
                x <= x + 1;

            if (BtnR)   // FIXED (was BtnL)
                state <= RIGHT;
            else
                state <= IDLE;
        end

        DOWNLEFT: begin
            if (y > 0)
                y <= y - 1;

            if (x > 0)
                x <= x - 1;

            if (!BtnD && !BtnL)
                state <= IDLE;
            else if (BtnL && !BtnD)
                state <= LEFT;
            else if (!BtnL && BtnD)
                state <= DOWN;
        end

        DOWNRIGHT: begin
            if (y > 0)
                y <= y - 1;

            if (x < 10'b1111111111)
                x <= x + 1;

            if (!BtnD && !BtnR)
                state <= IDLE;
            else if (BtnR && !BtnD)
                state <= RIGHT; // FIXED (was LEFT)
            else if (!BtnR && BtnD)
                state <= DOWN;
        end

        DEATH: begin
            // no behavior yet
        end

        default: state <= INIT;

        endcase
    end
end

endmodule

is there problem in this?
timescale 1ns / 1ps

module vga_demo(
    input ClkPort,

    // switches
    input Sw0, Sw1,

    // buttons
    input BtnU, BtnD, BtnL, BtnR, BtnC,

    // VGA (match XDC names!)
    output Hsync, Vsync,
    output [3:0] vgaRed, vgaGreen, vgaBlue,

    // LEDs (note: Ld not LD)
    output Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7,
    output Ld8, Ld9, Ld10, Ld11, Ld12, Ld13, Ld14, Ld15,

    // 7-seg
    output An0, An1, An2, An3, An4, An5, An6, An7,
    output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,

    // required by XDC
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
// SIMPLE PLAYER (uses all buttons now)
//////////////////////////////////////////////////////////////
reg [9:0] x = 200;
reg [9:0] y = 200;

always @(posedge clk) begin
    if (reset) begin
        x <= 200;
        y <= 200;
    end else begin
        if (BtnL && x > 0)       x <= x - 1;
        if (BtnR && x < 1023)    x <= x + 1;
        if (BtnU && y < 1023)    y <= y + 1;
        if (BtnD && y > 0)       y <= y - 1;
    end
end

//////////////////////////////////////////////////////////////
// VGA DRAWING
//////////////////////////////////////////////////////////////
wire draw_player =
    (CounterX >= x && CounterX <= x + 20 &&
     CounterY >= y && CounterY <= y + 20);

wire draw_box =
    (CounterX > 100 && CounterX < 200 && CounterY[5:3] == 3'b111);

wire R = draw_player;
wire G = draw_box;
wire B = 1'b0;

assign vgaRed   = {4{R & inDisplayArea}};
assign vgaGreen = {4{G & inDisplayArea}};
assign vgaBlue  = {4{B & inDisplayArea}};

//////////////////////////////////////////////////////////////
// LEDS (just mirror switches for now)
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
// SSD (disabled cleanly)
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
// REQUIRED UNUSED OUTPUT
//////////////////////////////////////////////////////////////
assign QuadSpiFlashCS = 1'b1;

endmodule

create a divclk I can feed into player that's slower
why is vga_demo not using mu player_module? use it
timescale 1ns / 1ps

module vga_demo(
    input ClkPort,

    // switches
    input Sw0, Sw1,

    // buttons
    input BtnU, BtnD, BtnL, BtnR, BtnC,

    // VGA (match XDC names!)
    output Hsync, Vsync,
    output [3:0] vgaRed, vgaGreen, vgaBlue,

    // LEDs (note: Ld not LD)
    output Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7,
    output Ld8, Ld9, Ld10, Ld11, Ld12, Ld13, Ld14, Ld15,

    // 7-seg
    output An0, An1, An2, An3, An4, An5, An6, An7,
    output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,

    // required by XDC
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
// SIMPLE PLAYER (uses all buttons now)
//////////////////////////////////////////////////////////////
reg [9:0] x = 200;
reg [9:0] y = 200;

// slower clock for player movement
wire player_clk = DIV_CLK[20];

// player outputs
wire [9:0] x;
wire [9:0] y;

// debug state outputs (optional)
wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump;
wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath;

// instantiate player module
player p1 (
    .clk(player_clk),   // slower movement
    .rst(reset),
    .SW0(Sw0),
    .BtnC(BtnC),
    .BtnL(BtnL),
    .BtnR(BtnR),
    .BtnU(BtnU),
    .BtnD(BtnD),
    .x(x),
    .y(y),

    .Qinit(Qinit), .Qidle(Qidle), .Qleft(Qleft), .Qright(Qright),
    .Qdown(Qdown), .Qjump(Qjump),
    .Qupleft(Qupleft), .Qupright(Qupright),
    .Qdownleft(Qdownleft), .Qdownright(Qdownright),
    .Qdeath(Qdeath)
);

//////////////////////////////////////////////////////////////
// VGA DRAWING
//////////////////////////////////////////////////////////////
wire draw_player =
    (CounterX >= x && CounterX <= x + 20 &&
     CounterY >= y && CounterY <= y + 20);

wire draw_box =
    (CounterX > 100 && CounterX < 200 && CounterY[5:3] == 3'b111);

wire R = draw_player;
wire G = draw_box;
wire B = 1'b0;

assign vgaRed   = {4{R & inDisplayArea}};
assign vgaGreen = {4{G & inDisplayArea}};
assign vgaBlue  = {4{B & inDisplayArea}};

//////////////////////////////////////////////////////////////
// LEDS (just mirror switches for now)
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
// SSD (disabled cleanly)
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
// REQUIRED UNUSED OUTPUT
//////////////////////////////////////////////////////////////
assign QuadSpiFlashCS = 1'b1;

endmodule

fix it
module player(
    input wire clk,
    input wire rst,
    input SW0, BtnC, BtnL, BtnR, BtnU, BtnD,

    output reg [9:0] x,
    output reg [9:0] y,

    output wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
    output wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath
);

//================ STATE =================
reg [10:0] state;

localparam
INIT       = 11'b00000000001,
IDLE       = 11'b00000000010,
LEFT       = 11'b00000000100,
RIGHT      = 11'b00000001000,
DOWN       = 11'b00000010000,
JUMP       = 11'b00000100000,
UPLEFT     = 11'b00001000000,
UPRIGHT    = 11'b00010000000,
DOWNLEFT   = 11'b00100000000,
DOWNRIGHT  = 11'b01000000000, // FIXED (11 bits)
DEATH      = 11'b10000000000;

assign {Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
        Qupleft, Qupright, Qdownleft, Qdownright, Qdeath} = state;

//================ FLAGS =================
reg jumpflag;
reg [10:0] jumpcount, dashcount;

//================ FSM =================
always @(posedge clk) begin
    if (rst) begin
        state <= INIT;
        x <= 10;
        y <= 10;
        jumpflag <= 0;
    end
    else begin
        case(state)

        INIT: begin
            x <= 0;
            y <= 0;
            jumpflag <= 0;
            state <= IDLE;
        end

        IDLE: begin
            jumpflag <= 0;

            // PRIORITY ORDER FIXED
            if (BtnU & BtnL)       state <= UPLEFT;
            else if (BtnU & BtnR)  state <= UPRIGHT;
            else if (BtnD & BtnL)  state <= DOWNLEFT;
            else if (BtnD & BtnR)  state <= DOWNRIGHT;
            else if (BtnL)         state <= LEFT;
            else if (BtnR)         state <= RIGHT;
            else if (BtnU)         state <= JUMP;
            else if (BtnD)         state <= DOWN;
        end

        LEFT: begin
            if (x > 0)
                x <= x - 1;

            if (!BtnL)
                state <= IDLE;
        end

        RIGHT: begin
            if (x < 10'b1111111111)
                x <= x + 1;

            if (!BtnR)
                state <= IDLE;
        end

        DOWN: begin
            if (y > 0)
                y <= y - 1;

            if (!BtnD)
                state <= IDLE;
        end

        JUMP: begin
            if (y < 10'b1111111111) begin
                y <= y + 20;
                jumpflag <= 1;
            end
            state <= IDLE;
        end

        UPLEFT: begin
            jumpflag <= 1;

            if (y < 10'b1111111111)
                y <= y + 20;

            if (x > 0)
                x <= x - 1;

            if (BtnL)
                state <= LEFT;
            else
                state <= IDLE;
        end

        UPRIGHT: begin
            jumpflag <= 1;

            if (y < 10'b1111111111)
                y <= y + 20;

            if (x < 10'b1111111111)
                x <= x + 1;

            if (BtnR)   // FIXED (was BtnL)
                state <= RIGHT;
            else
                state <= IDLE;
        end

        DOWNLEFT: begin
            if (y > 0)
                y <= y - 1;

            if (x > 0)
                x <= x - 1;

            if (!BtnD && !BtnL)
                state <= IDLE;
            else if (BtnL && !BtnD)
                state <= LEFT;
            else if (!BtnL && BtnD)
                state <= DOWN;
        end

        DOWNRIGHT: begin
            if (y > 0)
                y <= y - 1;

            if (x < 10'b1111111111)
                x <= x + 1;

            if (!BtnD && !BtnR)
                state <= IDLE;
            else if (BtnR && !BtnD)
                state <= RIGHT; // FIXED (was LEFT)
            else if (!BtnR && BtnD)
                state <= DOWN;
        end

        DEATH: begin
            // no behavior yet
        end

        default: state <= INIT;

        endcase
    end
end

endmodule

please help implement gravity and a better jump
i want to decrement the magnitude of a variable
i want to make a world module that takes in where the player is going to be and returns if it's going to be a valid position for the player to be in or not. Then, the player module can use this to determine whether to actually move the player or not. Is this a good solution and how do I implement?
how would tile-based world work
so I pass into world the tiles I'm moving into?
btw, I want to store player position as the top left corner of the position
module world(
    input [9:0] x_next,
    input [9:0] y_next,
    output collide_left,
output collide_right,
output collide_top,
output collide_bottom
);

reg [0:0] world_map [0:39][0:29];

// example map
initial begin
    integer i;
    for (i = 0; i < 40; i = i + 1)
        world_map[i][0] = 1;
end

localparam PLAYER_W = 20;
localparam PLAYER_H = 20;

wire [5:0] left   = x_next >> 4;
wire [5:0] right  = (x_next + PLAYER_W - 1) >> 4;
wire [4:0] bottom = y_next >> 4;
wire [4:0] top    = (y_next + PLAYER_H - 1) >> 4;

assign collide_left = world_map[left][bottom] == 1 || world_map[left][top] == 1;
assign collide_right = world_map[right][bottom] == 1 || world_map[right][top] == 1;
assign collide_top = world_map[left][top] == 1 || world_map[right][top] == 1;
assign collide_bottom = world_map[left][bottom] == 1 || world_map[right][bottom] == 1;

endmodule

can we add a bounding box around the world for this or something?
ok give the whold module
change this to use my world module to prevent collisions
module player(
    input wire clk,
    input wire rst,
    input SW0, BtnC, BtnL, BtnR, BtnU, BtnD,
    input onGround, xOpen, yOpen

    output reg [9:0] x,
    output reg [9:0] y,
    output reg [9:0] nextX,
    output reg [9:0] nextY,

    output wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
    output wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath
);

reg [3:0] vx;
reg [3:0] vy;


wire collide_left, collide_right, collide_top, collide_bottom;
world w(.x_next(nextX), .y_next(nextY), .collide_left(collide_left), .collide_right(collide_right), .collide_top(collide_top), .collide_bottom(collide_bottom))

localparam X_BOUND = 10'b11111111111;
localparam Y_BOUND = 10'b11111111111;

//================ STATE =================
reg [10:0] state;

localparam
INIT       = 11'b00000000001,
IDLE       = 11'b00000000010,
LEFT       = 11'b00000000100,
RIGHT      = 11'b00000001000,
DOWN       = 11'b00000010000,
JUMP       = 11'b00000100000,
UPLEFT     = 11'b00001000000,
UPRIGHT    = 11'b00010000000,
DOWNLEFT   = 11'b00100000000,
DOWNRIGHT  = 11'b01000000000, // FIXED (11 bits)
DEATH      = 11'b10000000000;

assign {Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
        Qupleft, Qupright, Qdownleft, Qdownright, Qdeath} = state;

nextX = x + vx;
nextY = y + vy;

//================ FLAGS =================
reg jumpflag;
reg [10:0] jumpcount, dashcount;

//================ FSM =================
always @(posedge clk) begin
    if (rst) begin
        state <= INIT;
        x <= 0;
        y <= 0;
        vx = 0;
        vy = 0;
        jumpflag <= 0;
    end
    else begin
        case(state)
            INIT:
                begin
                    //actions
                    x<=0;
                    y<=0;
                    jumpflag <=0;
                    //rtl
                    state <= IDLE;
                end
            IDLE:
                begin
                    //actions: x and y don't change (unless there is gravity)

                    //gravity code:

                    jumpflag <= 0; //no conditions for now for testing
                    vx <= 0;
                    vy <= 0;
                    //rtl
                    if(BtnL)begin //debounce these later
                        state <= LEFT;
                    end
                    if(BtnR)begin
                        state<=RIGHT;
                    end
                    if(BtnU)begin
                        state <= JUMP;
                    end
                    if(BtnD)begin
                        state <=DOWN;
                    end
                    if(BtnU & BtnL)begin
                        state <=UPLEFT;
                    end
                    if(BtnU & BtnR)begin
                        state <= UPRIGHT;
                    end
                    if (BtnD & BtnL)begin
                        state <= DOWNLEFT;
                    end
                    if (BtnD & BtnR)begin
                        state <= DOWNRIGHT;
                    end

                end
            LEFT:
                begin
                    //
                    vx <= -1;
                    //rtl
                    if(!BtnL)begin
                        state<=IDLE;
                    end

                end
            RIGHT:
                begin
                    vx <= 1;
                    //rtl
                    if(!BtnR)begin
                        state <= IDLE;
                    end
                end
            DOWN: 
                begin
                    vy <= 1;
                    if(!BtnD)
                        state <= IDLE;
                    
                end
            JUMP:
                begin
                    if(jumpflag == 0)begin //debouce eventually
                        vy <= -20;
                        jumpflag <= 1; //cannot jump again until this becomes 0
                    end
                    state <= IDLE;
                end
            UPLEFT:
                begin
                    if(jumpflag == 0)begin
                        vy <= -20;
                        jumpflag <= 1;;
                    end
                    vx <= -1;
                    if(BtnL)
                        state <= LEFT; //keep moving left even after jump if left is still pressed 
                    else
                        state <= IDLE;
                end
            UPRIGHT:
                begin
                    if(jumpflag == 0)begin
                        vy <= -20;
                        jumpflag <= 1;;
                    end
                    vx <= 1;
                    if(BtnR)
                        state <= RIGHT; //keep on moving right even post jump until BtnL not pressed
                    else
                        state <= IDLE;
                end
            DOWNLEFT:
                begin
                    vy <= 1;
                    vx <= -1;
                    if(!BtnD & !BtnL)
                        state <= IDLE;
                    else if (BtnL & !BtnD)
                        state <= LEFT;
                    else if (!BtnL & BtnD)
                         state <= DOWN;
                end
            DOWNRIGHT:
                begin
                    vy <= 1;
                    vx <= 1;
                    if(!BtnD & !BtnR)
                        state <= IDLE;
                    else if (BtnR & !BtnD)
                        state <= LEFT;
                    else if (!BtnR & BtnD)
                         state <= DOWN;
                end
            DEATH: 
                begin
                end
        endcase
    end
end

always @(posedge clk) begin
    // x movement
    if(x + vx >= 0 && x + vx <= X_BOUND) begin
        x <= x + vx;
    end
    // gravity
    if(!onGround) begin
        vy <= vy + 2;
    end
    // y movement
    if(y + vy >= 0 && y + vy <= Y_BOUND) begin
        y <= y + vy;
    end
    // drag
    if(vx > 0) begin
        vx <= vx - 1;
    end
    else if(vx < 0) begin
        vx <= vx + 1;
    end
    if(vy > 0) begin
        vy <= vy - 1;
    end
    else if(vy < 0) begin
        vy <= vy + 1;
    end
end

endmodule
i don't want world to be inside the player module. I want to be able to see world from a top in order to draw the world graphics
give me the whole world module
so I instantiate the module in both player and vga? the vga also instantiates the player though
what is inDisplayArea
do I need to increment tile_x and tile_y?
module player(
    input wire clk,
    input wire rst,
    input SW0, BtnC, BtnL, BtnR, BtnU, BtnD,
    input collide_left, collide_right, collide_top, collide_bottom;

    output reg [9:0] x,
    output reg [9:0] y,
    output wire [9:0] nextX,
    output wire [9:0] nextY,

    output wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
    output wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath
);

reg signed [3:0] vx;
reg signed [3:0] vy;




localparam X_BOUND = 10'b11111111111;
localparam Y_BOUND = 10'b11111111111;
localparam jumpVel = 20;
localparam dashSpeed = 10;

//================ STATE =================
reg [10:0] state;

localparam
INIT       = 11'b00000000001,
IDLE       = 11'b00000000010,
LEFT       = 11'b00000000100,
RIGHT      = 11'b00000001000,
DOWN       = 11'b00000010000,
JUMP       = 11'b00000100000,
UPLEFT     = 11'b00001000000,
UPRIGHT    = 11'b00010000000,
DOWNLEFT   = 11'b00100000000,
DOWNRIGHT  = 11'b01000000000, // FIXED (11 bits)
DEATH      = 11'b10000000000;

assign {Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
        Qupleft, Qupright, Qdownleft, Qdownright, Qdeath} = state;



//================ FLAGS =================
reg jumpflag;
reg dashflag;
reg [10:0] jumpcount, dashcount;

//================ FSM =================
always @(posedge clk) begin
    if (rst) begin
        state <= INIT;
        vx <= 0;
        vy <= 0;
        jumpflag <= 0;
    end
    else begin
        case(state)
            INIT:
                begin
                    //actions
                    jumpflag <=0;
                    //rtl
                    state <= IDLE;
                end
            IDLE:
                begin
                    //actions: x and y don't change (unless there is gravity)

                    //gravity code:

                    // jumpflag <= 0; //no conditions for now for testing
                    // vx <= 0;
                    // vy <= 0;
                    //rtl
                    if(BtnL)begin //debounce these later
                        state <= LEFT;
                    end
                    if(BtnR)begin
                        state<=RIGHT;
                    end
                    if(BtnU)begin
                        state <= JUMP;
                    end
                    if(BtnD)begin
                        state <=DOWN;
                    end
                    if(BtnU & BtnL)begin
                        state <=UPLEFT;
                    end
                    if(BtnU & BtnR)begin
                        state <= UPRIGHT;
                    end
                    if (BtnD & BtnL)begin
                        state <= DOWNLEFT;
                    end
                    if (BtnD & BtnR)begin
                        state <= DOWNRIGHT;
                    end

                end
            LEFT:
                begin
                    //
                    vx <= -1;
                    if(btnC) begin
                        vx <= 
                    end
                    //rtl
                    if(!BtnL)begin
                        state<=IDLE;
                    end

                end
            RIGHT:
                begin
                    vx <= 1;
                    //rtl
                    if(!BtnR)begin
                        state <= IDLE;
                    end
                end
            DOWN: 
                begin
                    vy <= 1;
                    if(!BtnD)
                        state <= IDLE;
                    
                end
            JUMP:
                begin
                    if(jumpflag == 0)begin //debouce eventually
                        vy <= -20;
                        jumpflag <= 1; //cannot jump again until this becomes 0
                    end
                    state <= IDLE;
                end
            UPLEFT:
                begin
                    if(jumpflag == 0)begin
                        vy <= -20;
                        jumpflag <= 1;;
                    end
                    vx <= -1;
                    if(BtnL)
                        state <= LEFT; //keep moving left even after jump if left is still pressed 
                    else
                        state <= IDLE;
                end
            UPRIGHT:
                begin
                    if(jumpflag == 0)begin
                        vy <= -20;
                        jumpflag <= 1;;
                    end
                    vx <= 1;
                    if(BtnR)
                        state <= RIGHT; //keep on moving right even post jump until BtnL not pressed
                    else
                        state <= IDLE;
                end
            DOWNLEFT:
                begin
                    vy <= 1;
                    vx <= -1;
                    if(!BtnD & !BtnL)
                        state <= IDLE;
                    else if (BtnL & !BtnD)
                        state <= LEFT;
                    else if (!BtnL & BtnD)
                         state <= DOWN;
                end
            DOWNRIGHT:
                begin
                    vy <= 1;
                    vx <= 1;
                    if(!BtnD & !BtnR)
                        state <= IDLE;
                    else if (BtnR & !BtnD)
                        state <= LEFT;
                    else if (!BtnR & BtnD)
                         state <= DOWN;
                end
            DEATH: 
                begin
                end
        endcase
    end
end

//////////////////////////////////////////////////////////////
// PHYSICS + COLLISION
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        x <= 0;
        y <= 0;
    end else begin
        nextX = x + vx;
        nextY = y + vy;
        // ===== GRAVITY =====
        if (!collide_bottom)
            vy <= vy + 1;   // falling
        else
        begin
            vy <= 0;        // on ground
            jumpflag <= 0;
        end
        // ===== X MOVEMENT =====
        if (vx < 0 && !collide_left)
            x <= x + vx;
        else if (vx > 0 && !collide_right)
            x <= x + vx;

        // ===== Y MOVEMENT =====
        if (vy < 0 && !collide_top)
            y <= y + vy;
        else if (vy > 0 && !collide_bottom)
            y <= y + vy;
    end
end

endmodule

add a dash using btnc that adds dashspeed in direction
write the module with the dash, user the higher impulse and I also want dash in the air. When on the ground, reset dashflag
add a btnd to fall faster as well
you got rid of the jumpflag, bring it back so I can only jump once before hitting the ground again
add an output wire so I can see if I'm facing left or right
timescale 1ns / 1ps

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

wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump;
wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath;

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

    .Qinit(Qinit), .Qidle(Qidle), .Qleft(Qleft), .Qright(Qright),
    .Qdown(Qdown), .Qjump(Qjump),
    .Qupleft(Qupleft), .Qupright(Qupright),
    .Qdownleft(Qdownleft), .Qdownright(Qdownright),
    .Qdeath(Qdeath)
);

//////////////////////////////////////////////////////////////
// VGA DRAWING
//////////////////////////////////////////////////////////////
wire draw_player =
    (CounterX >= x && CounterX <= x + 20 &&
     CounterY >= y && CounterY <= y + 20);

wire draw_box =
    (CounterX > 100 && CounterX < 200 && CounterY[5:3] == 3'b111);

wire R = draw_player;
wire G = draw_box;
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

broken
module player(
    input wire clk,
    input wire rst,
    input SW0, BtnC, BtnL, BtnR, BtnU, BtnD,

    output reg [9:0] x,
    output reg [9:0] y,

    output wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
    output wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath
);

//================ STATE =================
reg [10:0] state;

localparam
INIT       = 11'b00000000001,
IDLE       = 11'b00000000010,
LEFT       = 11'b00000000100,
RIGHT      = 11'b00000001000,
DOWN       = 11'b00000010000,
JUMP       = 11'b00000100000,
UPLEFT     = 11'b00001000000,
UPRIGHT    = 11'b00010000000,
DOWNLEFT   = 11'b00100000000,
DOWNRIGHT  = 11'b01000000000, // FIXED (11 bits)
DEATH      = 11'b10000000000;

assign {Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
        Qupleft, Qupright, Qdownleft, Qdownright, Qdeath} = state;

//================ FLAGS =================
reg jumpflag;
reg [10:0] jumpcount, dashcount;

//================ FSM =================
always @(posedge clk) begin
    if (rst) begin
        state <= INIT;
        x <= 10;
        y <= 10;
        jumpflag <= 0;
    end
    else begin
        case(state)

        INIT: begin
            x <= 0;
            y <= 0;
            jumpflag <= 0;
            state <= IDLE;
        end

        IDLE: begin
            jumpflag <= 0;

            // PRIORITY ORDER FIXED
            if (BtnU & BtnL)       state <= UPLEFT;
            else if (BtnU & BtnR)  state <= UPRIGHT;
            else if (BtnD & BtnL)  state <= DOWNLEFT;
            else if (BtnD & BtnR)  state <= DOWNRIGHT;
            else if (BtnL)         state <= LEFT;
            else if (BtnR)         state <= RIGHT;
            else if (BtnU)         state <= JUMP;
            else if (BtnD)         state <= DOWN;
        end

        LEFT: begin
            if (x > 0)
                x <= x - 1;

            if (!BtnL)
                state <= IDLE;
        end

        RIGHT: begin
            if (x < 10'b1111111111)
                x <= x + 1;

            if (!BtnR)
                state <= IDLE;
        end

        DOWN: begin
            if (y > 0)
                y <= y - 1;

            if (!BtnD)
                state <= IDLE;
        end

        JUMP: begin
            if (y < 10'b1111111111) begin
                y <= y + 20;
                jumpflag <= 1;
            end
            state <= IDLE;
        end

        UPLEFT: begin
            jumpflag <= 1;

            if (y < 10'b1111111111)
                y <= y + 20;

            if (x > 0)
                x <= x - 1;

            if (BtnL)
                state <= LEFT;
            else
                state <= IDLE;
        end

        UPRIGHT: begin
            jumpflag <= 1;

            if (y < 10'b1111111111)
                y <= y + 20;

            if (x < 10'b1111111111)
                x <= x + 1;

            if (BtnR)   // FIXED (was BtnL)
                state <= RIGHT;
            else
                state <= IDLE;
        end

        DOWNLEFT: begin
            if (y > 0)
                y <= y - 1;

            if (x > 0)
                x <= x - 1;

            if (!BtnD && !BtnL)
                state <= IDLE;
            else if (BtnL && !BtnD)
                state <= LEFT;
            else if (!BtnL && BtnD)
                state <= DOWN;
        end

        DOWNRIGHT: begin
            if (y > 0)
                y <= y - 1;

            if (x < 10'b1111111111)
                x <= x + 1;

            if (!BtnD && !BtnR)
                state <= IDLE;
            else if (BtnR && !BtnD)
                state <= RIGHT; // FIXED (was LEFT)
            else if (!BtnR && BtnD)
                state <= DOWN;
        end

        DEATH: begin
            // no behavior yet
        end

        default: state <= INIT;

        endcase
    end
end

endmodule

here's my player
module world(
    //////////////////////////////////////////////////////////////
    // COLLISION INTERFACE (player uses this)
    //////////////////////////////////////////////////////////////
    input  [9:0] x_next,
    input  [9:0] y_next,

    output collide_left,
    output collide_right,
    output collide_top,
    output collide_bottom,

    //////////////////////////////////////////////////////////////
    // RENDER INTERFACE (VGA uses this)
    //////////////////////////////////////////////////////////////
    input  [5:0] tile_x,
    input  [4:0] tile_y,
    output [1:0] tile_out   // tile type (2 bits = extensible)
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam TILE_SIZE = 16;
localparam WORLD_W = 40;   // 640 / 16
localparam WORLD_H = 30;   // 480 / 16

localparam PLAYER_W = 20;
localparam PLAYER_H = 20;

//////////////////////////////////////////////////////////////
// TILE TYPES
//////////////////////////////////////////////////////////////
localparam TILE_EMPTY = 2'b00;
localparam TILE_SOLID = 2'b01;
localparam SPIKE = 2'b10;


//////////////////////////////////////////////////////////////
// WORLD MAP
//////////////////////////////////////////////////////////////
reg [1:0] world_map [0:WORLD_W-1][0:WORLD_H-1];

integer i;

initial begin
    // clear map
    for (i = 0; i < WORLD_W; i = i + 1) begin
        world_map[i][0] = TILE_SOLID;  // ground
    end

    // example platform
    world_map[10][5] = TILE_SOLID;
    world_map[11][5] = TILE_SOLID;
    world_map[12][5] = TILE_SOLID;
end

//////////////////////////////////////////////////////////////
// SAFE TILE ACCESS FUNCTION
//////////////////////////////////////////////////////////////
function is_solid;
    input [5:0] tx;
    input [4:0] ty;
    begin
        // treat outside world as solid boundary
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_solid = 1;
        else
            is_solid = (world_map[tx][ty] == TILE_SOLID);
    end
endfunction

//////////////////////////////////////////////////////////////
// PIXEL → TILE CONVERSION (for player)
//////////////////////////////////////////////////////////////
wire [5:0] left   = x_next >> 4;
wire [5:0] right  = (x_next + PLAYER_W - 1) >> 4;
wire [4:0] bottom = y_next >> 4;
wire [4:0] top    = (y_next + PLAYER_H - 1) >> 4;

//////////////////////////////////////////////////////////////
// COLLISION OUTPUTS
//////////////////////////////////////////////////////////////
assign collide_left =
    is_solid(left, bottom) || is_solid(left, top);

assign collide_right =
    is_solid(right, bottom) || is_solid(right, top);

assign collide_bottom =
    is_solid(left, bottom) || is_solid(right, bottom);

assign collide_top =
    is_solid(left, top) || is_solid(right, top);

//////////////////////////////////////////////////////////////
// TILE OUTPUT FOR VGA
//////////////////////////////////////////////////////////////
assign tile_out =
    (tile_x >= WORLD_W || tile_y >= WORLD_H) ?
        TILE_SOLID :
        world_map[tile_x][tile_y];

endmodule

fix world, everything is upside down. The top left corner of counter x counter y is 0,0
//////////////////////////////////////////////////////////////
// PHYSICS + COLLISION
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        x <= 20;
        y <= 20;
    end else begin

        // =======================
        // GRAVITY / FAST FALL
        // =======================
        if (!collide_bottom) begin
            if (BtnD && vy > 0)
                vy <= vy + FAST_FALL;
            else
                vy <= vy + GRAVITY;
        end

        // =======================
        // X MOVEMENT
        // =======================
        if (vx < 0 && !collide_left)
            x <= x + vx;
        else if (vx > 0 && !collide_right)
            x <= x + vx;

        // =======================
        // Y MOVEMENT
        // =======================
        if (vy < 0 && !collide_top)
            y <= y + vy;
        else if (vy > 0 && !collide_bottom)
            y <= y + vy;
    end
end

write drag into this, lower vx and vy by one in magnitude each clock cycl
if collide_bottom then vy <= 0 means I can't jump though no?
module player(
    input wire clk,
    input wire rst,
    input BtnC, BtnL, BtnR, BtnU, BtnD,

    input collide_left, collide_right, collide_top, collide_bottom,

    output reg [9:0] x,
    output reg [9:0] y,
    output wire [9:0] nextX,
    output wire [9:0] nextY,
    output wire facing_left
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam signed GRAVITY    = 1;
localparam signed FAST_FALL  = 3;
localparam signed JUMP_VEL   = -12;
localparam signed DASH_SPEED = 20;

//////////////////////////////////////////////////////////////
// VELOCITY
//////////////////////////////////////////////////////////////
reg signed [10:0] vx;
reg signed [10:0] vy;

//////////////////////////////////////////////////////////////
// FLAGS
//////////////////////////////////////////////////////////////
reg dashflag;
reg jumpflag;

//////////////////////////////////////////////////////////////
// NEXT POSITION
//////////////////////////////////////////////////////////////
assign nextX = x + vx;
assign nextY = y + vy;

reg facing_left_reg;
assign facing_left = facing_left_reg;

//////////////////////////////////////////////////////////////
// INPUT / CONTROL
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        vx <= 0;
        vy <= 0;
        dashflag <= 0;
        jumpflag <= 0;
        facing_left_reg <= 0;  // default facing right
    end else begin

        // =======================
        // HORIZONTAL INPUT
        // =======================
        if (BtnL)
            vx <= -2;
        else if (BtnR)
            vx <= 2;
        else
            vx <= 0;

        // update facing direction
        if (BtnL)
            facing_left_reg <= 1;
        else if (BtnR)
            facing_left_reg <= 0;

        // =======================
        // JUMP (single jump per air)
        // =======================
        if (BtnU && !jumpflag && collide_bottom) begin
            vy <= JUMP_VEL;
            jumpflag <= 1;
        end

        // =======================
        // DASH (ground + air)
        // =======================
        if (BtnC && !dashflag) begin
            if (BtnL)
                vx <= -DASH_SPEED;
            else if (BtnR)
                vx <= DASH_SPEED;
            else begin
                if (vx >= 0)
                    vx <= DASH_SPEED;
                else
                    vx <= -DASH_SPEED;
            end
            dashflag <= 1;
        end

        // =======================
        // RESET FLAGS ON GROUND
        // =======================
        if (collide_bottom) begin
            dashflag <= 0;
            jumpflag <= 0;
        end
    end
end

//////////////////////////////////////////////////////////////
// PHYSICS + COLLISION
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        x <= 100;
        y <= 100;
    end else begin

        // =======================
        // GRAVITY / FAST FALL
        // =======================
        if (collide_bottom) begin
            if (vy > 0)      // only cancel downward motion
                vy <= 0;
        end else begin
            if (BtnD && vy > 0)
                vy <= vy + FAST_FALL;
            else
                vy <= vy + GRAVITY;
        end

        // =======================
        // X MOVEMENT
        // =======================
        if (vx < 0 && !collide_left)
            x <= x + vx;
        else if (vx > 0 && !collide_right)
            x <= x + vx;

        // =======================
        // Y MOVEMENT
        // =======================
        if (vy < 0 && !collide_top)
            y <= y + vy;
        else if (vy > 0 && !collide_bottom)
            y <= y + vy;
            
    end
end

endmodule
there's no gravity or jumping, what's up???????
give me the whole module
module player(
    input wire clk,
    input wire rst,
    input BtnC, BtnL, BtnR, BtnU, BtnD,

    input collide_left, collide_right, collide_top, collide_bottom,

    output reg [9:0] x,
    output reg [9:0] y,
    output wire [9:0] nextX,
    output wire [9:0] nextY,
    output wire facing_left
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam signed GRAVITY    = 1;
localparam signed FAST_FALL  = 3;
localparam signed JUMP_VEL   = -12;
localparam signed DASH_SPEED = 20;

//////////////////////////////////////////////////////////////
// VELOCITY
//////////////////////////////////////////////////////////////
reg signed [10:0] vx;
reg signed [10:0] vy;

//////////////////////////////////////////////////////////////
// FLAGS
//////////////////////////////////////////////////////////////
reg dashflag;
reg jumpflag;
reg jump_req;

//////////////////////////////////////////////////////////////
// NEXT POSITION
//////////////////////////////////////////////////////////////
assign nextX = x + vx;
assign nextY = y + vy;

//////////////////////////////////////////////////////////////
// FACING DIRECTION
//////////////////////////////////////////////////////////////
reg facing_left_reg;
assign facing_left = facing_left_reg;

//////////////////////////////////////////////////////////////
// INPUT / CONTROL (NO vy WRITES HERE)
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        vx <= 0;
        dashflag <= 0;
        jumpflag <= 0;
        jump_req <= 0;
        facing_left_reg <= 0;
    end else begin

        // default
        jump_req <= 0;

        // =======================
        // HORIZONTAL INPUT
        // =======================
        if (BtnL) begin
            vx <= -2;
            facing_left_reg <= 1;
        end
        else if (BtnR) begin
            vx <= 2;
            facing_left_reg <= 0;
        end
        else begin
            vx <= 0;
        end

        // =======================
        // JUMP REQUEST
        // =======================
        if (BtnU && !jumpflag && collide_bottom) begin
            jump_req <= 1;
            jumpflag <= 1;
        end

        // =======================
        // DASH
        // =======================
        if (BtnC && !dashflag) begin
            if (BtnL)
                vx <= -DASH_SPEED;
            else if (BtnR)
                vx <= DASH_SPEED;
            else begin
                if (vx >= 0)
                    vx <= DASH_SPEED;
                else
                    vx <= -DASH_SPEED;
            end
            dashflag <= 1;
        end

        // =======================
        // RESET FLAGS ON GROUND
        // =======================
        if (collide_bottom) begin
            dashflag <= 0;
            jumpflag <= 0;
        end
    end
end

//////////////////////////////////////////////////////////////
// PHYSICS + COLLISION (ONLY PLACE vy IS CONTROLLED)
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        x <= 100;
        y <= 100;
        vy <= 0;
    end else begin

        // =======================
        // APPLY JUMP
        // =======================
        if (jump_req) begin
            vy <= JUMP_VEL;
        end else begin

            // =======================
            // GRAVITY / FAST FALL
            // =======================
            if (collide_bottom) begin
                if (vy > 0)
                    vy <= 0;
            end else begin
                if (BtnD && vy > 0)
                    vy <= vy + FAST_FALL;
                else
                    vy <= vy + GRAVITY;
            end
        end

        // =======================
        // X MOVEMENT
        // =======================
        if (vx < 0 && !collide_left)
            x <= x + vx;
        else if (vx > 0 && !collide_right)
            x <= x + vx;

        // =======================
        // Y MOVEMENT
        // =======================
        if (vy < 0 && !collide_top)
            y <= y + vy;
        else if (vy > 0 && !collide_bottom)
            y <= y + vy;
    end
end

endmodule

collide top not working
does the x need this or not?
why do we need vy_next?
is vy not where I want to go?
can I just make vy non-blocking instead??
sorry I mean blocking


ok, make the module where both vy_next and vx_next are there
i don't understand why we need the vy_next, if vy will just update on the next clock cycle and the movement is onlyl applied then as well isn't it fine that the check is only for the next clock cycle too?
isn't it fine if I decide based on yesterday's velocity if I check for collisions also using yesterday's velocity?
the above module code completely breaks the game
can you write the full module with this fix
currently i have a world and player module with vga outputs and can respond to movements/interact with each other. I want to create two more modules: a spike module that causes the player to reset (die) when hit and a strawberry module that increases score count when interacting with player and disappears after the interaction
i don't want the positions of the spike and strawberry to be hardcoded, i want to give it an input on what x and y it should be at
i also want these objects to have vga outputs
i want to use the tile system to determien the location of strawberry and spikes: 
module world(
    //////////////////////////////////////////////////////////////
    // COLLISION INTERFACE (player uses this)
    //////////////////////////////////////////////////////////////
    input  [9:0] x_next,
    input  [9:0] y_next,

    output collide_left,
    output collide_right,
    output collide_top,
    output collide_bottom,

    //////////////////////////////////////////////////////////////
    // RENDER INTERFACE (VGA uses this)
    //////////////////////////////////////////////////////////////
    input  [5:0] tile_x,
    input  [4:0] tile_y,
    output [1:0] tile_out   // tile type (2 bits = extensible)
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam TILE_SIZE = 16;
localparam WORLD_W = 40;   // 640 / 16
localparam WORLD_H = 30;   // 480 / 16

localparam PLAYER_W = 20;
localparam PLAYER_H = 20;

//////////////////////////////////////////////////////////////
// TILE TYPES
//////////////////////////////////////////////////////////////
localparam TILE_EMPTY = 2'b00;
localparam TILE_SOLID = 2'b01;
localparam SPIKE = 2'b10;


//////////////////////////////////////////////////////////////
// WORLD MAP
//////////////////////////////////////////////////////////////
reg [1:0] world_map [0:WORLD_W-1][0:WORLD_H-1];

integer i;

initial begin
    // layer 1
    for (i = 0; i < 16; i = i + 1) begin
        world_map[i][WORLD_H-1] = TILE_SOLID;  // ground
    end
    for (i=20; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-1] = TILE_SOLID;
    end
    
    //layer  2
    for (i= 0; i<12; i = i + 1)begin
        world_map[i][WORLD_H-2] = TILE_SOLID; //might have to update this if we want different top blocks
    end
    world_map[14][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[15][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[20][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[21][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[22][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[23][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[24][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[25][WORLD_H-2] = TILE_SOLID; //top tile
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-2] = TILE_SOLID;
    end
    //layer 3
    for (i= 0; i<10; i = i + 1)begin
        world_map[i][WORLD_H-3] = TILE_SOLID; //might have to update this if we want different top blocks
    end
    //top tile
    for(i=10; i<16; i=i+1)begin
        world_map[i][WORLD_H-3] = TILE_SOLID; //top tile
    end
    for(i=20; i<26; i = i + 1)begin
         world_map[i][WORLD_H-3] = TILE_SOLID; //top tile
    end
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-3] = TILE_SOLID;
    end
    //layer 4
    //top tile
    for (i= 0; i<6; i = i + 1)begin
        world_map[i][WORLD_H-4] = TILE_SOLID; //might have to update this if we want different top blocks
    end

    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-4] = TILE_SOLID;
    end
    world_map[25][WORLD_H-4] = TILE_SOLID; //spike
    //layer 5
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-5] = TILE_SOLID; 
    end
    world_map[25][WORLD_H-5] = TILE_SOLID; //spike
    //layer 6
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-6] = TILE_SOLID; 
    end
    //platform
    for(i=16; i<20; i = i+1)begin
        world_map[i][WORLD_H-6] = TILE_SOLID; //top tile
    end
    world_map[25][WORLD_H-6] = TILE_SOLID; //spike
    
    //layer 7
    for(i=26; i<WORLD_W; i = i+1)begin
        world_map[i][WORLD_H-7] = TILE_SOLID; //top tile
    end
    world_map[25][WORLD_H-7] = TILE_SOLID; //spike
    //layer 9
    //platform
    for(i=12; i<17;i = i+1)begin
        world_map[i][WORLD_H-9]= TILE_SOLID; //top tile
    end
    //layer 12
    for(i = 17; i<23; i = i + 1)begin
        world_map[i][WORLD_H-12]= TILE_SOLID; //top tile
    end
    //layer 15
    for(i = 23; i<WORLD_W; i = i + 1)begin
        world_map[i][WORLD_H-15]= TILE_SOLID; //top tile
    end
    //layer 16
    world_map[27][WORLD_H-16] = TILE_SOLID; //spike
    world_map[28][WORLD_H-16] = TILE_SOLID; //spike
    
    
    
end

//////////////////////////////////////////////////////////////
// SAFE TILE ACCESS FUNCTION
//////////////////////////////////////////////////////////////
function is_solid;
    input [5:0] tx;
    input [4:0] ty;
    begin
        // treat outside world as solid boundary
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_solid = 1;
        else
            is_solid = (world_map[tx][ty] == TILE_SOLID);
    end
endfunction

//////////////////////////////////////////////////////////////
// PIXEL → TILE CONVERSION (for player)
//////////////////////////////////////////////////////////////
wire [5:0] left   = x_next >> 4;
wire [5:0] right  = (x_next + PLAYER_W - 1) >> 4;
wire [4:0] top = y_next >> 4;
wire [4:0] bottom    = (y_next + PLAYER_H - 1) >> 4;

//////////////////////////////////////////////////////////////
// COLLISION OUTPUTS
//////////////////////////////////////////////////////////////
assign collide_left =
    is_solid(left, bottom) || is_solid(left, top);

assign collide_right =
    is_solid(right, bottom) || is_solid(right, top);

assign collide_bottom =
    is_solid(left, bottom) || is_solid(right, bottom);

assign collide_top =
    is_solid(left, top) || is_solid(right, top);

//////////////////////////////////////////////////////////////
// TILE OUTPUT FOR VGA
//////////////////////////////////////////////////////////////
assign tile_out =
    (tile_x >= WORLD_W || tile_y >= WORLD_H) ?
        TILE_SOLID :
        world_map[tile_x][tile_y];

endmodule

in world.v, i put placeholder world tiles of where i want the spikes to be (i have not put strawberries in yet). how would i keep this consistent tiling system?
do i still need strawberry.v and spike.v or is it all in the world file now?

so can kill player ?

how does detecting it is a solid kill the player?
module world(
    //////////////////////////////////////////////////////////////
    // COLLISION INTERFACE (player uses this)
    //////////////////////////////////////////////////////////////
    input  [9:0] x_next,
    input  [9:0] y_next,

    output collide_left,
    output collide_right,
    output collide_top,
    output collide_bottom,
    output hit_spike,
    output collect_berry,

    //////////////////////////////////////////////////////////////
    // RENDER INTERFACE (VGA uses this)
    //////////////////////////////////////////////////////////////
    input  [5:0] tile_x,
    input  [4:0] tile_y,
    output [1:0] tile_out   // tile type (2 bits = extensible)
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam TILE_SIZE = 16;
localparam WORLD_W = 40;   // 640 / 16
localparam WORLD_H = 30;   // 480 / 16

localparam PLAYER_W = 20;
localparam PLAYER_H = 20;

//////////////////////////////////////////////////////////////
// TILE TYPES
//////////////////////////////////////////////////////////////
localparam TILE_EMPTY = 2'b00;
localparam TILE_SOLID = 2'b01;
localparam SPIKE = 2'b10;
localparam STRAWBERRY = 2'b11;


//////////////////////////////////////////////////////////////
// WORLD MAP
//////////////////////////////////////////////////////////////
reg [1:0] world_map [0:WORLD_W-1][0:WORLD_H-1];

integer i;

initial begin
    // layer 1
    for (i = 0; i < 16; i = i + 1) begin
        world_map[i][WORLD_H-1] = TILE_SOLID;  // ground
    end
    for (i=20; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-1] = TILE_SOLID;
    end
    
    //layer  2
    for (i= 0; i<12; i = i + 1)begin
        world_map[i][WORLD_H-2] = TILE_SOLID; //might have to update this if we want different top blocks
    end
    world_map[14][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[15][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[20][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[21][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[22][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[23][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[24][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[25][WORLD_H-2] = TILE_SOLID; //top tile
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-2] = TILE_SOLID;
    end
    //layer 3
    for (i= 0; i<10; i = i + 1)begin
        world_map[i][WORLD_H-3] = TILE_SOLID; //might have to update this if we want different top blocks
    end
    //top tile
    for(i=10; i<16; i=i+1)begin
        world_map[i][WORLD_H-3] = TILE_SOLID; //top tile
    end
    for(i=20; i<26; i = i + 1)begin
         world_map[i][WORLD_H-3] = TILE_SOLID; //top tile
    end
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-3] = TILE_SOLID;
    end
    //layer 4
    //top tile
    for (i= 0; i<6; i = i + 1)begin
        world_map[i][WORLD_H-4] = TILE_SOLID; //might have to update this if we want different top blocks
    end
    for(i = 20; i<26; i = i + 1)begin
        world_map[i][WORLD_H-4] = SPIKE;
    end

    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-4] = TILE_SOLID;
    end

    //layer 5
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-5] = TILE_SOLID; 
    end

    //layer 6
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-6] = TILE_SOLID; 
    end
    //platform
    for(i=16; i<20; i = i+1)begin
        world_map[i][WORLD_H-6] = TILE_SOLID; //top tile
    end
    world_map[5][WORLD_H-6] = STRAWBERRY;
    
    //layer 7
    for(i=26; i<WORLD_W; i = i+1)begin
        world_map[i][WORLD_H-7] = TILE_SOLID; //top tile
    end

    //layer 9
    //platform
    for(i=12; i<17;i = i+1)begin
        world_map[i][WORLD_H-9]= TILE_SOLID; //top tile
    end
    //layer 12
    for(i = 17; i<23; i = i + 1)begin
        world_map[i][WORLD_H-12]= TILE_SOLID; //top tile
    end
    //layer 15
    for(i = 23; i<WORLD_W; i = i + 1)begin
        world_map[i][WORLD_H-15]= TILE_SOLID; //top tile
    end
    //layer 16
    world_map[27][WORLD_H-16] = SPIKE; //spike
    world_map[28][WORLD_H-16] = SPIKE; //spike
    
    
    
end

//////////////////////////////////////////////////////////////
// SAFE TILE ACCESS FUNCTION
//////////////////////////////////////////////////////////////
function is_solid;
    input [5:0] tx;
    input [4:0] ty;
    begin
        // treat outside world as solid boundary
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_solid = 1;
        else
            is_solid = (world_map[tx][ty] == TILE_SOLID || world_map[tx][ty] == SPIKE);
    end
endfunction

function is_spike;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_spike = 0;
        else
            is_spike = (world_map[tx][ty] == SPIKE);
    end
endfunction

assign hit_spike =
    is_spike(left, bottom) ||
    is_spike(right, bottom) ||
    is_spike(left, top) ||
    is_spike(right, top);
    
function is_berry;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_berry = 0;
        else
            is_berry = (world_map[tx][ty] == STRAWBERRY);
    end
endfunction
assign collect_berry =
    is_berry(left, bottom) ||
    is_berry(right, bottom) ||
    is_berry(left, top) ||
    is_berry(right, top);

//////////////////////////////////////////////////////////////
// PIXEL → TILE CONVERSION (for player)
//////////////////////////////////////////////////////////////
wire [5:0] left   = x_next >> 4;
wire [5:0] right  = (x_next + PLAYER_W - 1) >> 4;
wire [4:0] top = y_next >> 4;
wire [4:0] bottom    = (y_next + PLAYER_H - 1) >> 4;

//////////////////////////////////////////////////////////////
// COLLISION OUTPUTS
//////////////////////////////////////////////////////////////
assign collide_left =
    is_solid(left, bottom) || is_solid(left, top);

assign collide_right =
    is_solid(right, bottom) || is_solid(right, top);

assign collide_bottom =
    is_solid(left, bottom) || is_solid(right, bottom);

assign collide_top =
    is_solid(left, top) || is_solid(right, top);

//////////////////////////////////////////////////////////////
// TILE OUTPUT FOR VGA
//////////////////////////////////////////////////////////////
assign tile_out = //how do i fix this for spike?
    (tile_x >= WORLD_W || tile_y >= WORLD_H) ?
        TILE_SOLID :
        world_map[tile_x][tile_y];

endmodule

i updated world.v as best I could, but i am confused about how to update tile_out + the always block for the strawberry. additionally, how should i edit my vga_demo.v file:
timescale 1ns / 1ps

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
	.facing_left(facing_left)
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

and my player file:
my current vga_demo file works for before we updated world.v for strawberries and spikes, theres nothing broken about the logic. additionally, here is the player file to also update. please give me three updated files that maintains the integrity of the code before strawberries and spikes were added , making minimal changes to the code to add strawberries and spikes:

world.v (has some updates for spikes and strawberries)
module world(
    //////////////////////////////////////////////////////////////
    // COLLISION INTERFACE (player uses this)
    //////////////////////////////////////////////////////////////
    input  [9:0] x_next,
    input  [9:0] y_next,
    input clk,

    output collide_left,
    output collide_right,
    output collide_top,
    output collide_bottom,
    output hit_spike,
    output collect_berry,

    //////////////////////////////////////////////////////////////
    // RENDER INTERFACE (VGA uses this)
    //////////////////////////////////////////////////////////////
    input  [5:0] tile_x,
    input  [4:0] tile_y,
    output [1:0] tile_out   // tile type (2 bits = extensible)
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam TILE_SIZE = 16;
localparam WORLD_W = 40;   // 640 / 16
localparam WORLD_H = 30;   // 480 / 16

localparam PLAYER_W = 20;
localparam PLAYER_H = 20;

//////////////////////////////////////////////////////////////
// TILE TYPES
//////////////////////////////////////////////////////////////
localparam TILE_EMPTY = 2'b00;
localparam TILE_SOLID = 2'b01;
localparam SPIKE = 2'b10;
localparam STRAWBERRY = 2'b11;


//////////////////////////////////////////////////////////////
// WORLD MAP
//////////////////////////////////////////////////////////////
reg [1:0] world_map [0:WORLD_W-1][0:WORLD_H-1];

integer i;

initial begin
    // layer 1
    for (i = 0; i < 16; i = i + 1) begin
        world_map[i][WORLD_H-1] = TILE_SOLID;  // ground
    end
    for (i=20; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-1] = TILE_SOLID;
    end
    
    //layer  2
    for (i= 0; i<12; i = i + 1)begin
        world_map[i][WORLD_H-2] = TILE_SOLID; //might have to update this if we want different top blocks
    end
    world_map[14][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[15][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[20][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[21][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[22][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[23][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[24][WORLD_H-2] = TILE_SOLID; //top tile
    world_map[25][WORLD_H-2] = TILE_SOLID; //top tile
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-2] = TILE_SOLID;
    end
    //layer 3
    for (i= 0; i<10; i = i + 1)begin
        world_map[i][WORLD_H-3] = TILE_SOLID; //might have to update this if we want different top blocks
    end
    //top tile
    for(i=10; i<16; i=i+1)begin
        world_map[i][WORLD_H-3] = TILE_SOLID; //top tile
    end
    for(i=20; i<26; i = i + 1)begin
         world_map[i][WORLD_H-3] = TILE_SOLID; //top tile
    end
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-3] = TILE_SOLID;
    end
    //layer 4
    //top tile
    for (i= 0; i<6; i = i + 1)begin
        world_map[i][WORLD_H-4] = TILE_SOLID; //might have to update this if we want different top blocks
    end
    for(i = 20; i<26; i = i + 1)begin
        world_map[i][WORLD_H-4] = SPIKE;
    end

    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-4] = TILE_SOLID;
    end

    //layer 5
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-5] = TILE_SOLID; 
    end

    //layer 6
    for (i=26; i< WORLD_W; i = i +1) begin
        world_map[i][WORLD_H-6] = TILE_SOLID; 
    end
    //platform
    for(i=16; i<20; i = i+1)begin
        world_map[i][WORLD_H-6] = TILE_SOLID; //top tile
    end
    world_map[5][WORLD_H-6] = STRAWBERRY;
    
    //layer 7
    for(i=26; i<WORLD_W; i = i+1)begin
        world_map[i][WORLD_H-7] = TILE_SOLID; //top tile
    end

    //layer 9
    //platform
    for(i=12; i<17;i = i+1)begin
        world_map[i][WORLD_H-9]= TILE_SOLID; //top tile
    end
    //layer 12
    for(i = 17; i<23; i = i + 1)begin
        world_map[i][WORLD_H-12]= TILE_SOLID; //top tile
    end
    //layer 15
    for(i = 23; i<WORLD_W; i = i + 1)begin
        world_map[i][WORLD_H-15]= TILE_SOLID; //top tile
    end
    //layer 16
    world_map[27][WORLD_H-16] = SPIKE; //spike
    world_map[28][WORLD_H-16] = SPIKE; //spike
    
    
    
end

//////////////////////////////////////////////////////////////
// SAFE TILE ACCESS FUNCTION
//////////////////////////////////////////////////////////////
function is_solid;
    input [5:0] tx;
    input [4:0] ty;
    begin
        // treat outside world as solid boundary
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_solid = 1;
        else
            is_solid = (world_map[tx][ty] == TILE_SOLID || world_map[tx][ty] == SPIKE);
    end
endfunction

function is_spike;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_spike = 0;
        else
            is_spike = (world_map[tx][ty] == SPIKE);
    end
endfunction

assign hit_spike =
    is_spike(left, bottom) ||
    is_spike(right, bottom) ||
    is_spike(left, top) ||
    is_spike(right, top);
    
function is_berry;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_berry = 0;
        else
            is_berry = (world_map[tx][ty] == STRAWBERRY);
    end
endfunction
assign collect_berry =
    is_berry(left, bottom) ||
    is_berry(right, bottom) ||
    is_berry(left, top) ||
    is_berry(right, top);

//////////////////////////////////////////////////////////////
// PIXEL → TILE CONVERSION (for player)
//////////////////////////////////////////////////////////////
wire [5:0] left   = x_next >> 4;
wire [5:0] right  = (x_next + PLAYER_W - 1) >> 4;
wire [4:0] top = y_next >> 4;
wire [4:0] bottom    = (y_next + PLAYER_H - 1) >> 4;

//////////////////////////////////////////////////////////////
// COLLISION OUTPUTS
//////////////////////////////////////////////////////////////
assign collide_left =
    is_solid(left, bottom) || is_solid(left, top);

assign collide_right =
    is_solid(right, bottom) || is_solid(right, top);

assign collide_bottom =
    is_solid(left, bottom) || is_solid(right, bottom);

assign collide_top =
    is_solid(left, top) || is_solid(right, top);
//strawberry collision
always @(posedge clk) begin
    if (collect_berry) begin
        // remove berry at all possible contact points
        if (left   < WORLD_W && bottom < WORLD_H && world_map[left][bottom] == STRAWBERRY)
            world_map[left][bottom] <= TILE_EMPTY;

        if (right  < WORLD_W && bottom < WORLD_H && world_map[right][bottom] == STRAWBERRY)
            world_map[right][bottom] <= TILE_EMPTY;

        if (left   < WORLD_W && top < WORLD_H && world_map[left][top] == STRAWBERRY)
            world_map[left][top] <= TILE_EMPTY;

        if (right  < WORLD_W && top < WORLD_H && world_map[right][top] == STRAWBERRY)
            world_map[right][top] <= TILE_EMPTY;
    end
end
//////////////////////////////////////////////////////////////
// TILE OUTPUT FOR VGA
//////////////////////////////////////////////////////////////
assign tile_out = //how do i fix this for spike?
    (tile_x >= WORLD_W || tile_y >= WORLD_H) ?
        TILE_SOLID :
        world_map[tile_x][tile_y];

endmodule
vga_demo.v (no updates, only can do static green world and red player, but it worked for it)
timescale 1ns / 1ps

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

// ONE world instance
wire hit_spike;
wire collect_berry;

world w(
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

// priority: player > spike > berry > solid
wire [3:0] r =
    draw_player ? 4'b1111 :
    is_spike    ? 4'b1111 :
                  4'b0000;

wire [3:0] g =
    draw_player ? 4'b0000 :
    is_berry    ? 4'b1111 :
    is_solid    ? 4'b1111 :
                  4'b0000;

wire [3:0] b = 4'b0000;

assign vgaRed   = r & {4{inDisplayArea}};
assign vgaGreen = g & {4{inDisplayArea}};
assign vgaBlue  = b & {4{inDisplayArea}};
//score
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

and player.v (same as vga_demo.v)
module player(
    input wire clk,
    input wire rst,
    input BtnC, BtnL, BtnR, BtnU, BtnD,

    input collide_left, collide_right, collide_top, collide_bottom,

    output reg [9:0] x,
    output reg [9:0] y,
    output wire [9:0] nextX,
    output wire [9:0] nextY,
    output wire facing_left
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam signed GRAVITY    = 1;
localparam signed FAST_FALL  = 3;
localparam signed JUMP_VEL   = -12;
localparam signed DASH_SPEED = 20;

//////////////////////////////////////////////////////////////
// VELOCITY
//////////////////////////////////////////////////////////////
reg signed [10:0] vx;
reg signed [10:0] vy;

//////////////////////////////////////////////////////////////
// FLAGS
//////////////////////////////////////////////////////////////
reg dashflag;
reg jumpflag;
reg jump_req;

//////////////////////////////////////////////////////////////
// NEXT POSITION
//////////////////////////////////////////////////////////////
assign nextX = x + vx;
assign nextY = y + vy;

//////////////////////////////////////////////////////////////
// FACING DIRECTION
//////////////////////////////////////////////////////////////
reg facing_left_reg;
assign facing_left = facing_left_reg;

//////////////////////////////////////////////////////////////
// INPUT / CONTROL
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        vx <= 0;
        dashflag <= 0;
        jumpflag <= 0;
        jump_req <= 0;
        facing_left_reg <= 0;
    end else begin

        // default
        jump_req <= 0;

        // =======================
        // HORIZONTAL INPUT
        // =======================
        if (BtnL) begin
            vx <= -2;
            facing_left_reg <= 1;
        end
        else if (BtnR) begin
            vx <= 2;
            facing_left_reg <= 0;
        end
        else begin
            vx <= 0;
        end

        // =======================
        // JUMP REQUEST
        // =======================
        if (BtnU && !jumpflag && collide_bottom) begin
            jump_req <= 1;
            jumpflag <= 1;
        end

        // =======================
        // DASH
        // =======================
        if (BtnC && !dashflag) begin
            if (BtnL)
                vx <= -DASH_SPEED;
            else if (BtnR)
                vx <= DASH_SPEED;
            else begin
                if (vx >= 0)
                    vx <= DASH_SPEED;
                else
                    vx <= -DASH_SPEED;
            end
            dashflag <= 1;
        end

        // =======================
        // RESET FLAGS ON GROUND
        // =======================
        if (collide_bottom) begin
            dashflag <= 0;
            jumpflag <= 0;
        end
    end
end

//////////////////////////////////////////////////////////////
// PHYSICS + COLLISION (FIXED)
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst) begin
        x <= 100;
        y <= 100;
        vy <= 0;
    end else begin

        // =======================
        // APPLY JUMP FIRST
        // =======================
        if (jump_req) begin
            vy <= JUMP_VEL;
        end
        else begin
            // =======================
            // GRAVITY / FAST FALL
            // =======================
            if (collide_bottom) begin
                if (vy > 0)
                    vy <= 0;
            end else begin
                if (BtnD && vy > 0)
                    vy <= vy + FAST_FALL;
                else
                    vy <= vy + GRAVITY;
            end
        end

        // =======================
        // X MOVEMENT
        // =======================
        if (vx < 0 && !collide_left)
            x <= x + vx;
        else if (vx > 0 && !collide_right)
            x <= x + vx;

        // =======================
        // Y MOVEMENT
        // =======================
        if (vy < 0 && !collide_top)
            y <= y + vy;
        else if (vy > 0 && !collide_bottom)
            y <= y + vy;
    end
end

endmodule

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