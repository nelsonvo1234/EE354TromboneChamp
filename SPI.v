timescale 1ns / 1ps

module spi_master(
	input wire clk,
	input wire rst, 
	input wire start,
	input wire [7:0] data_in,
	output reg [7:0] data_out,
	output reg done,
	input wire [7:0] clk_div_amount

	output reg sclk, 
	output reg mosi, 
	input wire miso 
	// output reg cs
	);

reg[3:0] bit_cnt;
reg[7:0] shift_reg;
reg[7:0] recv_reg;

reg sclk_prev;
wire sclk_rising = (sclk == 1 && sclk_prev = 0);
wire sclk_falling = (sclk == 0 && sclk_prev == 1);


typedef enum reg [1:0] {
    IDLE,
    TRANSFER,
    DONE
} state_t;

state_t state;

// sclk generation
reg[7:0] clk_div;
reg spi_tick;

always @(posedge clk){
	sclk_prev <= sclk;
	clk_div <= clk_div + 1;
	spi_tick <= (clk_div == clk_div_amount);
	if(spi_tick)begin
		sclk <= ~sclk;
	end
}

// SPI sending and receiving
always @(posedge clk or posedge rst) begin
	if(rst)begin
		state <= IDLE:
		done <= 0;
		// cs <= 1;
		sclkc <= 0;
		sclk_prev <= 0;
	end
	else begin
		case(state)
		IDLE: begin
			if(start) begin
				done <= 0;
				// cs <= 0;
				bit_cnt <= 7;
				shift_reg <= data_in;
				state <= TRANSFER:
			end
		end
		TRANSFER: begin
			if(sclk_falling)begin
				mosi <= shift_reg[7];
				shift_reg <= shift_reg << 1;
			end
			if(sclk_rising)begin

				recv_reg <= {recv_reg[6:0], miso};

				if(bit_cnt == 0)begin
					state <= DONE;
					
				end
				else begin
					bit_cnt <= bit_cnt - 1;
				end
					
			end
		end
		DONE: begin
			data_out <= recv_reg;
			done <= 1;
			// cs <= 1;
			state <= IDLE;
		end
	end
	
end

end module