module player(
    input  wire clk,
    input  wire rst,
    input  BtnC, BtnL, BtnR, BtnU, BtnD,

    input  collide_left, collide_right, collide_top, collide_bottom,
    input  hit_spike,

    output reg  [9:0] x,
    output reg  [9:0] y,
    output wire [9:0] nextX,
    output wire [9:0] nextY,
    output wire       facing_left
);

//////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////
localparam signed [10:0] GRAVITY   = 11'sd1;
localparam signed [10:0] FAST_FALL = 11'sd3;
localparam signed [10:0] JUMP_VEL  = -11'sd12;
localparam signed [10:0] DASH_SPD  = 11'sd20;
localparam signed [10:0] WALK_SPD  = 11'sd2;

//////////////////////////////////////////////////////////////
// FSM
//////////////////////////////////////////////////////////////
// READ  : sample buttons, compute new velocity and nextX/nextY,
//         publish nextX/nextY to the world module.
// WAIT  : idle one cycle so the world's combinatorial collision
//         signals have a full clock to settle on the new nextX/Y.
// APPLY : read stable collision signals, commit x/y.
localparam READ  = 2'b00;
localparam WAIT  = 2'b01;
localparam APPLY = 2'b10;

reg [1:0] state;

//////////////////////////////////////////////////////////////
// STATE
//////////////////////////////////////////////////////////////
reg signed [10:0] vx;
reg signed [10:0] vy;
reg dashflag;
reg jumpflag;
reg facing_left_reg;

// nextX/nextY are registered so the world sees a stable value
// throughout the WAIT and APPLY states.
reg [9:0] next_x_reg;
reg [9:0] next_y_reg;

assign nextX       = next_x_reg;
assign nextY       = next_y_reg;
assign facing_left = facing_left_reg;

//////////////////////////////////////////////////////////////
// FSM
//////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (rst || hit_spike) begin
        state           <= READ;
        x               <= 10'd100;
        y               <= 10'd100;
        next_x_reg      <= 10'd100;
        next_y_reg      <= 10'd100;
        vx              <= 0;
        vy              <= 0;
        dashflag        <= 0;
        jumpflag        <= 0;
        facing_left_reg <= 0;
    end
    else begin
        case (state)

        //------------------------------------------------------
        // READ: compute the velocity we WANT for this frame,
        //       then immediately use it to compute next position.
        //
        //       We use blocking (=) for all intermediate values
        //       so that vx_new/vy_new are available in the same
        //       always block when we compute next_x_reg/next_y_reg.
        //------------------------------------------------------
        READ: begin : do_read
            reg signed [10:0] vx_new;
            reg signed [10:0] vy_new;

            // ---- Horizontal ----
            if (BtnC && !dashflag) begin
                // Dash overrides walk
                if      (BtnL) vx_new = -DASH_SPD;
                else if (BtnR) vx_new =  DASH_SPD;
                else           vx_new = (vx >= 0) ? DASH_SPD : -DASH_SPD;
                dashflag <= 1;
            end
            else if (BtnL) begin
                vx_new          = -WALK_SPD;
                facing_left_reg <= 1;
            end
            else if (BtnR) begin
                vx_new          =  WALK_SPD;
                facing_left_reg <= 0;
            end
            else begin
                vx_new = 0;
            end

            // ---- Vertical ----
            if (BtnU && !jumpflag && collide_bottom) begin
                // Jump: launch upward, consume jump token
                vy_new   = JUMP_VEL;
                jumpflag <= 1;
            end
            else if (collide_bottom && vy >= 0) begin
                // On ground and not trying to jump: kill downward velocity,
                // reset dash and jump so they can be used again next frame.
                vy_new   = 0;
                dashflag <= 0;
                jumpflag <= 0;
            end
            else begin
                // In the air: apply gravity (or fast-fall)
                if (BtnD && vy > 0)
                    vy_new = vy + FAST_FALL;
                else
                    vy_new = vy + GRAVITY;
            end

            // ---- Latch velocities ----
            vx <= vx_new;
            vy <= vy_new;

            // ---- Compute proposed next position ----
            // Use the NEW velocities (blocking vars) so the world
            // immediately sees the correct probe position.
            next_x_reg <= x + vx_new;
            next_y_reg <= y + vy_new;

            state <= WAIT;
        end

        //------------------------------------------------------
        // WAIT: the world module is purely combinatorial but
        //       its inputs (next_x_reg/next_y_reg) just changed
        //       on this rising edge. Give the signals one full
        //       clock period to propagate through the LUT chain
        //       before we read collide_* in APPLY.
        //------------------------------------------------------
        WAIT: begin
            state <= APPLY;
        end

        //------------------------------------------------------
        // APPLY: collision signals are stable. Move the player
        //        only if the direction is unobstructed.
        //
        //        Note: if blocked horizontally we keep x as-is
        //        (don't zero vx here — it resets each READ anyway).
        //        If blocked vertically we keep y as-is and also
        //        kill vy so we don't accumulate velocity into a wall.
        //------------------------------------------------------
        APPLY: begin
            // X
            if      (vx < 0 && !collide_left)  x <= next_x_reg;
            else if (vx > 0 && !collide_right)  x <= next_x_reg;
            // vx == 0: no horizontal movement, x unchanged

            // Y
            if (vy < 0 && !collide_top) begin
                y <= next_y_reg;
            end
            else if (vy < 0 && collide_top) begin
                // Bonked ceiling: kill upward velocity so gravity
                // takes over immediately rather than floating.
                vy <= 0;
            end
            else if (vy > 0 && !collide_bottom) begin
                y <= next_y_reg;
            end
            // vy == 0 or blocked below: y unchanged

            state <= READ;
        end

        default: state <= READ;
        endcase
    end
end

endmodule