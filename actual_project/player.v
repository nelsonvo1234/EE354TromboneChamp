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
        x <= 0;
        y <= 0;
    end else begin

        // =======================
        // GRAVITY / FAST FALL
        // =======================
        if (!collide_bottom) begin
            if (BtnD && vy > 0)
                vy <= vy + FAST_FALL;
            else
                vy <= vy + GRAVITY;
        end else begin
            vy <= 0;
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