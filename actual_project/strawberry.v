module strawberry(
    input clk,
    input rst,

    input [9:0] player_x,
    input [9:0] player_y,

    input [9:0] obj_x,
    input [9:0] obj_y,

    input [9:0] pixel_x,
    input [9:0] pixel_y,

    output reg collected,

    output draw,
    output [3:0] r,
    output [3:0] g,
    output [3:0] b
);

localparam SIZE = 16;
localparam PLAYER_W = 20;
localparam PLAYER_H = 20;

//////////////////////////////////////////////////////////////
// COLLISION
//////////////////////////////////////////////////////////////
wire overlap =
    (player_x < obj_x + SIZE) &&
    (player_x + PLAYER_W > obj_x) &&
    (player_y < obj_y + SIZE) &&
    (player_y + PLAYER_H > obj_y);

always @(posedge clk) begin
    if (rst)
        collected <= 0;
    else if (overlap)
        collected <= 1;
end

//////////////////////////////////////////////////////////////
// DRAW LOGIC
//////////////////////////////////////////////////////////////
wire visible = !collected;

assign draw =
    visible &&
    (pixel_x >= obj_x && pixel_x < obj_x + SIZE &&
     pixel_y >= obj_y && pixel_y < obj_y + SIZE);

// green strawberry
assign r = 0;
assign g = draw ? 4'b1111 : 0;
assign b = 0;

endmodule