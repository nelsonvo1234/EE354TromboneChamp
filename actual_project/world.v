module world(
    //////////////////////////////////////////////////////////////
    // COLLISION INTERFACE
    //////////////////////////////////////////////////////////////
    input  [9:0] x_next,
    input  [9:0] y_next,
    input  clk,

    output collide_left,
    output collide_right,
    output collide_top,
    output collide_bottom,
    output hit_spike,
    output collect_berry,

    //////////////////////////////////////////////////////////////
    // RENDER INTERFACE
    //////////////////////////////////////////////////////////////
    input  [5:0] tile_x,
    input  [4:0] tile_y,
    output [1:0] tile_out
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam TILE_SIZE = 16;
localparam WORLD_W   = 40;
localparam WORLD_H   = 30;
localparam PLAYER_W  = 16;
localparam PLAYER_H  = 16;

//////////////////////////////////////////////////////////////
// TILE TYPES
//////////////////////////////////////////////////////////////
localparam TILE_EMPTY  = 2'b00;
localparam TILE_SOLID  = 2'b01;
localparam SPIKE       = 2'b10;
localparam STRAWBERRY  = 2'b11;

//////////////////////////////////////////////////////////////
// WORLD MAP
//////////////////////////////////////////////////////////////
reg [1:0] world_map [0:WORLD_W-1][0:WORLD_H-1];
integer i, j;

initial begin
    for (i = 0; i < WORLD_W; i = i + 1)
        for (j = 0; j < WORLD_H; j = j + 1)
            world_map[i][j] = TILE_EMPTY;

    // layer 1
    for (i = 0; i < 16; i = i + 1)
        world_map[i][WORLD_H-1] = TILE_SOLID;
    for (i = 20; i < WORLD_W; i = i + 1)
        world_map[i][WORLD_H-1] = TILE_SOLID;

    // layer 2
    for (i = 0; i < 12; i = i + 1)
        world_map[i][WORLD_H-2] = TILE_SOLID;
    world_map[14][WORLD_H-2] = TILE_SOLID;
    world_map[15][WORLD_H-2] = TILE_SOLID;
    world_map[20][WORLD_H-2] = TILE_SOLID;
    world_map[21][WORLD_H-2] = TILE_SOLID;
    world_map[22][WORLD_H-2] = TILE_SOLID;
    world_map[23][WORLD_H-2] = TILE_SOLID;
    world_map[24][WORLD_H-2] = TILE_SOLID;
    world_map[25][WORLD_H-2] = TILE_SOLID;
    for (i = 26; i < WORLD_W; i = i + 1)
        world_map[i][WORLD_H-2] = TILE_SOLID;

    // layer 3
    for (i = 0; i < 10; i = i + 1)
        world_map[i][WORLD_H-3] = TILE_SOLID;
    for (i = 10; i < 16; i = i + 1)
        world_map[i][WORLD_H-3] = TILE_SOLID;
    for (i = 20; i < 26; i = i + 1)
        world_map[i][WORLD_H-3] = TILE_SOLID;
    for (i = 26; i < WORLD_W; i = i + 1)
        world_map[i][WORLD_H-3] = TILE_SOLID;

    // layer 4
    for (i = 0; i < 6; i = i + 1)
        world_map[i][WORLD_H-4] = TILE_SOLID;
    for (i = 20; i < 26; i = i + 1)
        world_map[i][WORLD_H-4] = SPIKE;
    for (i = 26; i < WORLD_W; i = i + 1)
        world_map[i][WORLD_H-4] = TILE_SOLID;

    // layer 5
    for (i = 26; i < WORLD_W; i = i + 1)
        world_map[i][WORLD_H-5] = TILE_SOLID;

    // layer 6
    for (i = 26; i < WORLD_W; i = i + 1)
        world_map[i][WORLD_H-6] = TILE_SOLID;
    for (i = 16; i < 20; i = i + 1)
        world_map[i][WORLD_H-6] = TILE_SOLID;
    world_map[5][WORLD_H-6] = STRAWBERRY;

    // layer 7
    for (i = 26; i < WORLD_W; i = i + 1)
        world_map[i][WORLD_H-7] = TILE_SOLID;

    // layer 9
    for (i = 12; i < 17; i = i + 1)
        world_map[i][WORLD_H-9] = TILE_SOLID;

    // layer 12
    for (i = 17; i < 23; i = i + 1)
        world_map[i][WORLD_H-12] = TILE_SOLID;

    // layer 15
    for (i = 23; i < WORLD_W; i = i + 1)
        world_map[i][WORLD_H-15] = TILE_SOLID;

    // layer 16 spikes
    world_map[27][WORLD_H-16] = SPIKE;
    world_map[28][WORLD_H-16] = SPIKE;
end

//////////////////////////////////////////////////////////////
// TILE QUERY FUNCTIONS
//////////////////////////////////////////////////////////////
function is_solid;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_solid = 1;
        else
            is_solid = (world_map[tx][ty] == TILE_SOLID ||
                        world_map[tx][ty] == SPIKE);
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

//////////////////////////////////////////////////////////////
// COLLISION PROBE DESIGN
//
// Each face is probed ONE PIXEL OUTSIDE the player bounding box.
// This is the key insight: a probe that is outside the box on
// face A cannot possibly be inside the box on face B, so there
// is zero overlap between any two faces' probe sets.
//
// Two probes per face, inset 2px on the cross-axis to avoid
// the exact corner pixel (which belongs to neither face):
//
//          x+2        x+13
//           |           |
//    y-1 ---+-----T-----+---   TOP probes (row = y-1)
//           |           |
//    y   [==|===========|==]
//           |  PLAYER   |
//  x-1  L   |           |   R  x+16
//           |           |
//    y+15[==|===========|==]
//           |           |
//    y+16---+-----B-----+---   BOTTOM probes (row = y+16)
//
// T probes : col = x+2, x+13  row = y-1
// B probes : col = x+2, x+13  row = y+PLAYER_H   (= y+16)
// L probes : col = x-1        row = y+2, y+13
// R probes : col = x+PLAYER_W (= x+16)  row = y+2, y+13
//
// Because all pixel coordinates are [9:0] unsigned, subtracting 1
// when x_next=0 or y_next=0 would underflow to a large number,
// which the is_solid bounds check (tx >= WORLD_W) catches as
// out-of-bounds → solid. So screen-edge collision is handled
// automatically and correctly.
//////////////////////////////////////////////////////////////

// BOTTOM
wire [5:0] bot_col_a = (x_next + 2)             >> 4;
wire [5:0] bot_col_b = (x_next + PLAYER_W - 3)  >> 4;
wire [4:0] bot_row   = (y_next + PLAYER_H)       >> 4;

// TOP
wire [5:0] top_col_a = (x_next + 2)             >> 4;
wire [5:0] top_col_b = (x_next + PLAYER_W - 3)  >> 4;
wire [4:0] top_row   = (y_next - 1)              >> 4;

// LEFT
wire [5:0] left_col   = (x_next - 1)            >> 4;
wire [4:0] left_row_a = (y_next + 2)            >> 4;
wire [4:0] left_row_b = (y_next + PLAYER_H - 3) >> 4;

// RIGHT
wire [5:0] right_col   = (x_next + PLAYER_W)    >> 4;
wire [4:0] right_row_a = (y_next + 2)           >> 4;
wire [4:0] right_row_b = (y_next + PLAYER_H - 3)>> 4;

//////////////////////////////////////////////////////////////
// DIRECTIONAL COLLISION OUTPUTS
//////////////////////////////////////////////////////////////
assign collide_bottom =
    is_solid(bot_col_a, bot_row) ||
    is_solid(bot_col_b, bot_row);

assign collide_top =
    is_solid(top_col_a, top_row) ||
    is_solid(top_col_b, top_row);

assign collide_left =
    is_solid(left_col, left_row_a) ||
    is_solid(left_col, left_row_b);

assign collide_right =
    is_solid(right_col, right_row_a) ||
    is_solid(right_col, right_row_b);

//////////////////////////////////////////////////////////////
// SPIKE / BERRY — four inner corners of the bounding box
//////////////////////////////////////////////////////////////
wire [5:0] inner_col_l = (x_next + 1)            >> 4;
wire [5:0] inner_col_r = (x_next + PLAYER_W - 2) >> 4;
wire [4:0] inner_row_t = (y_next + 1)            >> 4;
wire [4:0] inner_row_b = (y_next + PLAYER_H - 2) >> 4;

assign hit_spike =
    is_spike(inner_col_l, inner_row_t) ||
    is_spike(inner_col_r, inner_row_t) ||
    is_spike(inner_col_l, inner_row_b) ||
    is_spike(inner_col_r, inner_row_b);

assign collect_berry =
    is_berry(inner_col_l, inner_row_t) ||
    is_berry(inner_col_r, inner_row_t) ||
    is_berry(inner_col_l, inner_row_b) ||
    is_berry(inner_col_r, inner_row_b);

//////////////////////////////////////////////////////////////
// TILE OUTPUT FOR VGA
//////////////////////////////////////////////////////////////
assign tile_out =
    (tile_x >= WORLD_W || tile_y >= WORLD_H) ?
        TILE_SOLID :
        world_map[tile_x][tile_y];

endmodule