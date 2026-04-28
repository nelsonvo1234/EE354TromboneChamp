module spike(
    input [9:0] player_x,
    input [9:0] player_y,

    input [9:0] obj_x,
    input [9:0] obj_y,

    input [9:0] pixel_x,
    input [9:0] pixel_y,

    output hit,

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
assign hit =
    (player_x < obj_x + SIZE) &&
    (player_x + PLAYER_W > obj_x) &&
    (player_y < obj_y + SIZE) &&
    (player_y + PLAYER_H > obj_y);

//////////////////////////////////////////////////////////////
// DRAW LOGIC
//////////////////////////////////////////////////////////////
assign draw =
    (pixel_x >= obj_x && pixel_x < obj_x + SIZE &&
     pixel_y >= obj_y && pixel_y < obj_y + SIZE);

// red spike
assign r = draw ? 4'b1111 : 0;
assign g = 0;
assign b = 0;

endmodule