module world(
    input  [9:0] playerX,
    input  [9:0] playerY,
    input  [9:0] nextX,
    input  [9:0] nextY,
    input clk,
    input rst,

    output collide_left,
    output collide_right,
    output collide_top,
    output collide_bottom,
    output hit_spike,
    output collect_berry,
    output all_berries_collected,

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

localparam BERRY_COUNT = 5;
localparam [5:0] BERRY0_X = 6'd5;
localparam [4:0] BERRY0_Y = WORLD_H-6;
localparam [5:0] BERRY1_X = 6'd18;
localparam [4:0] BERRY1_Y = WORLD_H-14;
localparam [5:0] BERRY2_X = 6'd30;
localparam [4:0] BERRY2_Y = WORLD_H-17;
localparam [5:0] BERRY3_X = 6'd10;
localparam [4:0] BERRY3_Y = WORLD_H-10;
localparam [5:0] BERRY4_X = 6'd24;
localparam [4:0] BERRY4_Y = WORLD_H-20;

localparam BERRIES_READY = 1'b0;
localparam BERRIES_UPDATE = 1'b1;

reg berry_state;
reg [BERRY_COUNT-1:0] berries_present;
wire [BERRY_COUNT-1:0] touched_berries;
reg collect_pulse;

assign collect_berry = collect_pulse;
assign all_berries_collected = (berries_present == {BERRY_COUNT{1'b0}});

initial begin
    berry_state = BERRIES_READY;
    berries_present = {BERRY_COUNT{1'b1}};
    collect_pulse = 1'b0;
end

//////////////////////////////////////////////////////////////
// WORLD MAP
//////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////
// PIXEL to TILE CONVERSION
//////////////////////////////////////////////////////////////
wire [9:0] player_left   = playerX >> 4;
wire [9:0] player_right  = (playerX + PLAYER_W - 1) >> 4;
wire [9:0] player_top    = playerY >> 4;
wire [9:0] player_bottom = (playerY + PLAYER_H - 1) >> 4;

wire [9:0] left   = nextX >> 4;
wire [9:0] right  = (nextX + PLAYER_W - 1) >> 4;
wire [9:0] top    = nextY >> 4;
wire [9:0] bottom = (nextY + PLAYER_H - 1) >> 4;

assign left_o   = left;
assign right_o  = right;
assign top_o    = top;
assign bottom_o = bottom;

function berry_present_at;
    input [5:0] tx;
    input [4:0] ty;
    begin
        berry_present_at =
            (berries_present[0] && tx >= BERRY0_X && tx <= BERRY0_X + 1 && ty >= BERRY0_Y && ty <= BERRY0_Y + 1) ||
            (berries_present[1] && tx >= BERRY1_X && tx <= BERRY1_X + 1 && ty >= BERRY1_Y && ty <= BERRY1_Y + 1) ||
            (berries_present[2] && tx >= BERRY2_X && tx <= BERRY2_X + 1 && ty >= BERRY2_Y && ty <= BERRY2_Y + 1) ||
            (berries_present[3] && tx >= BERRY3_X && tx <= BERRY3_X + 1 && ty >= BERRY3_Y && ty <= BERRY3_Y + 1) ||
            (berries_present[4] && tx >= BERRY4_X && tx <= BERRY4_X + 1 && ty >= BERRY4_Y && ty <= BERRY4_Y + 1);
    end
endfunction

function [1:0] tile_at_tile;
    input [5:0] tx;
    input [4:0] ty;
    begin
        if (tx >= WORLD_W || ty >= WORLD_H) begin
            tile_at_tile = TILE_SOLID;
        end else if (berry_present_at(tx, ty)) begin
            tile_at_tile = STRAWBERRY;
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
    is_spike(player_left[5:0], player_bottom[4:0]) ||
    is_spike(player_right[5:0], player_bottom[4:0]) ||
    is_spike(player_left[5:0], player_top[4:0]) ||
    is_spike(player_right[5:0], player_top[4:0]) ||
    is_spike(left[5:0], bottom[4:0]) ||
    is_spike(right[5:0], bottom[4:0]) ||
    is_spike(left[5:0], top[4:0]) ||
    is_spike(right[5:0], top[4:0]);

assign touched_berries =
    berry_mask(player_left[5:0], player_bottom[4:0]) |
    berry_mask(player_right[5:0], player_bottom[4:0]) |
    berry_mask(player_left[5:0], player_top[4:0]) |
    berry_mask(player_right[5:0], player_top[4:0]) |
    berry_mask(left[5:0], bottom[4:0]) |
    berry_mask(right[5:0], bottom[4:0]) |
    berry_mask(left[5:0], top[4:0]) |
    berry_mask(right[5:0], top[4:0]);

function [BERRY_COUNT-1:0] berry_mask;
    input [5:0] tx;
    input [4:0] ty;
    begin
        berry_mask = {BERRY_COUNT{1'b0}};
        if (tx >= BERRY0_X && tx <= BERRY0_X + 1 && ty >= BERRY0_Y && ty <= BERRY0_Y + 1)
            berry_mask[0] = 1'b1;
        if (tx >= BERRY1_X && tx <= BERRY1_X + 1 && ty >= BERRY1_Y && ty <= BERRY1_Y + 1)
            berry_mask[1] = 1'b1;
        if (tx >= BERRY2_X && tx <= BERRY2_X + 1 && ty >= BERRY2_Y && ty <= BERRY2_Y + 1)
            berry_mask[2] = 1'b1;
        if (tx >= BERRY3_X && tx <= BERRY3_X + 1 && ty >= BERRY3_Y && ty <= BERRY3_Y + 1)
            berry_mask[3] = 1'b1;
        if (tx >= BERRY4_X && tx <= BERRY4_X + 1 && ty >= BERRY4_Y && ty <= BERRY4_Y + 1)
            berry_mask[4] = 1'b1;
    end
endfunction

always @(posedge clk) begin
    if (rst || hit_spike) begin
        berry_state <= BERRIES_READY;
        berries_present <= {BERRY_COUNT{1'b1}};
        collect_pulse <= 1'b0;
    end else begin
        collect_pulse <= 1'b0;

        case (berry_state)
            BERRIES_READY: begin
                if (|(berries_present & touched_berries))
                    berry_state <= BERRIES_UPDATE;
            end

            BERRIES_UPDATE: begin
                berries_present <= berries_present & ~touched_berries;
                collect_pulse <= |(berries_present & touched_berries);
                berry_state <= BERRIES_READY;
            end
        endcase
    end
end

//////////////////////////////////////////////////////////////
// TILE OUTPUT FOR VGA
//////////////////////////////////////////////////////////////
assign tile_out = //how do i fix this for spike?
    (tile_x >= WORLD_W || tile_y >= WORLD_H) ?
        TILE_SOLID :
        tile_at_tile(tile_x, tile_y);

endmodule
