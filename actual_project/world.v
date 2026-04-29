module world(
    input  [9:0] nextX,
    input  [9:0] nextY,
    input clk,

    output collide_left,
    output collide_right,
    output collide_top,
    output collide_bottom,
    output hit_spike,
    output collect_berry,

    // NEW DEBUG OUTPUTS
    output [9:0] left_o,
    output [9:0] right_o,
    output [9:0] top_o,
    output [9:0] bottom_o,
    output [1:0] tile_o,

    input  [5:0] tile_x,
    input  [4:0] tile_y,
    output [1:0] tile_out
);

reg berry = 1;

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


assign left_o   = left;
assign right_o  = right;
assign top_o    = top;
assign bottom_o = bottom;


    function [1:0] tile_at_tile;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H) begin
            tile_at_tile = TILE_SOLID;
        end else if (ty == WORLD_H-1) begin
            tile_at_tile = (tx < 16 || tx >= 20) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-2) begin
            tile_at_tile = (tx < 12 || (tx >= 14 && tx < 16) || tx >= 20) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-3) begin
            tile_at_tile = (tx < 16 || tx >= 20) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-4) begin
            if (tx >= 20 && tx < 26)
                tile_at_tile = SPIKE;
            else
                tile_at_tile = (tx < 6 || tx >= 26) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-5) begin
            tile_at_tile = (tx >= 26) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-6) begin
            if (tx == 5)
                tile_at_tile = STRAWBERRY;
            else
                tile_at_tile = ((tx >= 16 && tx < 20) || tx >= 26) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-7) begin
            tile_at_tile = (tx >= 26) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-9) begin
            tile_at_tile = (tx >= 12 && tx < 17) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-12) begin
            tile_at_tile = (tx >= 17 && tx < 23) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-15) begin
            tile_at_tile = (tx >= 23) ? TILE_SOLID : TILE_EMPTY;
        end else if (ty == WORLD_H-16) begin
            tile_at_tile = (tx == 27 || tx == 28) ? SPIKE : TILE_EMPTY;
        end else begin
            tile_at_tile = TILE_EMPTY;
        end
    end
endfunction

//////////////////////////////////////////////////////////////
// SAFE TILE ACCESS FUNCTION
//////////////////////////////////////////////////////////////

function is_solid;
    input [9:0] tx;
    input [9:0] ty;
    begin
        // treat outside world as solid boundary
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_solid = 1;
        else
            is_solid = (tile_at_tile(tx, ty) == TILE_SOLID || tile_at_tile(tx, ty) == SPIKE);
    end
endfunction

function is_spike;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_spike = 0;
        else
            is_spike = (tile_at_tile(tx, ty) == SPIKE);
    end
endfunction
    
function is_berry;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H)
            is_berry = 0;
        else
            is_berry = (tile_at_tile(tx, ty) == STRAWBERRY);
    end
endfunction

//////////////////////////////////////////////////////////////
// PIXEL to TILE CONVERSION (for player debug)
//////////////////////////////////////////////////////////////
wire [9:0] left   = nextX >> 4;
wire [9:0] right  = (nextX + PLAYER_W - 1) >> 4;
wire [9:0] top    = nextY >> 4;
wire [9:0] bottom = (nextY + PLAYER_H - 1) >> 4;

//////////////////////////////////////////////////////////////
// DIRECTIONAL COLLISION PROBES
//////////////////////////////////////////////////////////////
wire [9:0] left_probe_col   = (nextX - 1) >> 4;
wire [9:0] right_probe_col  = (nextX + PLAYER_W) >> 4;
wire [9:0] top_probe_row    = (nextY - 1) >> 4;
wire [9:0] bottom_probe_row = (nextY + PLAYER_H) >> 4;

wire [9:0] probe_col_a = (nextX + 2) >> 4;
wire [9:0] probe_col_b = (nextX + PLAYER_W - 3) >> 4;
wire [9:0] probe_row_a = (nextY + 2) >> 4;
wire [9:0] probe_row_b = (nextY + PLAYER_H - 3) >> 4;

assign tile_o =
    (left >= WORLD_W || top >= WORLD_H) ?
        TILE_SOLID :
        tile_at_tile(left, top);

//////////////////////////////////////////////////////////////
// COLLISION OUTPUTS
//////////////////////////////////////////////////////////////
assign collide_left =
    is_solid(left_probe_col, probe_row_a) ||
    is_solid(left_probe_col, probe_row_b) ||
    is_solid(left, probe_row_a) ||
    is_solid(left, probe_row_b);

assign collide_right =
    is_solid(right_probe_col, probe_row_a) ||
    is_solid(right_probe_col, probe_row_b) ||
    is_solid(right, probe_row_a) ||
    is_solid(right, probe_row_b);

assign collide_bottom =
    is_solid(probe_col_a, bottom_probe_row) ||
    is_solid(probe_col_b, bottom_probe_row) ||
    is_solid(probe_col_a, bottom) ||
    is_solid(probe_col_b, bottom);

assign collide_top =
    is_solid(probe_col_a, top_probe_row) ||
    is_solid(probe_col_b, top_probe_row) ||
    is_solid(probe_col_a, top) ||
    is_solid(probe_col_b, top);

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
    
//  always @(posedge clk) begin
//      if (collect_berry) begin
        
//      end
//  end
//////////////////////////////////////////////////////////////
// TILE OUTPUT FOR VGA
//////////////////////////////////////////////////////////////
assign tile_out = //how do i fix this for spike?
    (tile_x >= WORLD_W || tile_y >= WORLD_H) ?
        TILE_SOLID :
        tile_at_tile(tile_x, tile_y);

endmodule
