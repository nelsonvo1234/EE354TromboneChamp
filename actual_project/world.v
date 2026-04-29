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

localparam PLAYER_W = 16;
localparam PLAYER_H = 16;

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

integer j;

initial begin
    for (i = 0; i < WORLD_W; i = i + 1)
        for (j = 0; j < WORLD_H; j = j + 1)
            world_map[i][j] = TILE_EMPTY;
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
// PIXEL → TILE CONVERSION (for player)
//////////////////////////////////////////////////////////////
// wire [5:0] left   = x_next >> 4;  //x position of the tile that the left side player is in
// wire [5:0] right  = (x_next + PLAYER_W - 1) >> 4; //x pos right
// wire [4:0] top = y_next >> 4; //y position of the tile thst the top side player is in
// wire [4:0] bottom    = (y_next + PLAYER_H - 1) >> 4; //


// NEW (stable)
wire [5:0] left   = (x_next + 1) >> 4;
wire [5:0] right  = (x_next + PLAYER_W - 2) >> 4;
wire [4:0] top    = (y_next + 1) >> 4;
wire [4:0] bottom = (y_next + PLAYER_H - 2) >> 4;
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
    
assign hit_spike =
    is_spike(left, bottom) ||
    is_spike(right, bottom) ||
    is_spike(left, top) ||
    is_spike(right, top);
    
assign collect_berry =
    is_berry(left, bottom) ||
    is_berry(right, bottom) ||
    is_berry(left, top) ||
    is_berry(right, top);
//strawberry collision
// always @(posedge clk) begin
//     if (collect_berry) begin
//         // remove berry at all possible contact points
//         if (left   < WORLD_W && bottom < WORLD_H && world_map[left][bottom] == STRAWBERRY)
//             world_map[left][bottom] <= TILE_EMPTY;

//         if (right  < WORLD_W && bottom < WORLD_H && world_map[right][bottom] == STRAWBERRY)
//             world_map[right][bottom] <= TILE_EMPTY;

//         if (left   < WORLD_W && top < WORLD_H && world_map[left][top] == STRAWBERRY)
//             world_map[left][top] <= TILE_EMPTY;

//         if (right  < WORLD_W && top < WORLD_H && world_map[right][top] == STRAWBERRY)
//             world_map[right][top] <= TILE_EMPTY;
//     end
// end
//////////////////////////////////////////////////////////////
// TILE OUTPUT FOR VGA
//////////////////////////////////////////////////////////////
assign tile_out = //how do i fix this for spike?
    (tile_x >= WORLD_W || tile_y >= WORLD_H) ?
        TILE_SOLID :
        world_map[tile_x][tile_y];

endmodule