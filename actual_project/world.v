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