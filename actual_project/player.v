module player(
    input wire clk,
    input wire rst,
    input BtnC, BtnL, BtnR, BtnU, BtnD,

    input collide_left, collide_right, collide_top, collide_bottom,
    input hit_spike,

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
// FSM STATES (UPDATED)
//////////////////////////////////////////////////////////////
localparam READ  = 2'b00;
localparam WAIT  = 2'b01;   // NEW
localparam APPLY = 2'b10;

reg [1:0] state;

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
reg [9:0] nextXreg;
reg [9:0] nextYreg;

assign nextX = nextXreg;
assign nextY = nextYreg;

//////////////////////////////////////////////////////////////
// FACING
//////////////////////////////////////////////////////////////
reg facing_left_reg;
assign facing_left = facing_left_reg;

//////////////////////////////////////////////////////////////
// FSM
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst || hit_spike) begin
        state <= READ;

        x <= 100;
        y <= 100;

        vx <= 0;
        vy <= 0;

        dashflag <= 0;
        jumpflag <= 0;
        jump_req <= 0;
    end else begin

        case (state)

        ////////////////////////////////////////////////////////
        // READ
        ////////////////////////////////////////////////////////
        READ: begin
            jump_req <= 0;

            // HORIZONTAL
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

            // JUMP
            if (BtnU && !jumpflag && collide_bottom) begin
                jump_req <= 1;
                jumpflag <= 1;
            end

            // DASH
            if (BtnC && !dashflag) begin
                if (BtnL)
                    vx <= -DASH_SPEED;
                else if (BtnR)
                    vx <= DASH_SPEED;
                else
                    vx <= (vx >= 0) ? DASH_SPEED : -DASH_SPEED;

                dashflag <= 1;
            end

            // GRAVITY
            if (jump_req) begin
                vy <= JUMP_VEL;
            end else begin
                if (collide_bottom) begin
                    if (vy > 0)
                        vy <= 0;
                    dashflag <= 0;
                    jumpflag <= 0;
                end else begin
                    if (BtnD && vy > 0)
                        vy <= vy + FAST_FALL;
                    else
                        vy <= vy + GRAVITY;
                end
            end

            // COMPUTE NEXT
            nextXreg <= x + vx;
            nextYreg <= y + vy;

            state <= WAIT;   // <-- KEY FIX
        end

        ////////////////////////////////////////////////////////
        // WAIT (NEW)
        ////////////////////////////////////////////////////////
        WAIT: begin
            state <= APPLY;
        end

        ////////////////////////////////////////////////////////
        // APPLY
        ////////////////////////////////////////////////////////
        APPLY: begin

            // X movement
            if (vx < 0 && !collide_left)
                x <= nextXreg;
            else if (vx > 0 && !collide_right)
                x <= nextXreg;

            // Y movement
            if (vy < 0 && !collide_top)
                y <= nextYreg;
            else if (vy > 0 && !collide_bottom)
                y <= nextYreg;

            state <= READ;
        end

        endcase
    end
end

endmodule