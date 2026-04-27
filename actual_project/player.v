module player(
    input wire clk,
    input wire rst,
    input SW0, BtnC, BtnL, BtnR, BtnU, BtnD,
    input collide_left, collide_right, collide_top, collide_bottom;

    output reg [9:0] x,
    output reg [9:0] y,
    output wire [9:0] nextX,
    output wire [9:0] nextY,

    output wire Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
    output wire Qupleft, Qupright, Qdownleft, Qdownright, Qdeath
);

reg signed [3:0] vx;
reg signed [3:0] vy;




localparam X_BOUND = 10'b11111111111;
localparam Y_BOUND = 10'b11111111111;

//================ STATE =================
reg [10:0] state;

localparam
INIT       = 11'b00000000001,
IDLE       = 11'b00000000010,
LEFT       = 11'b00000000100,
RIGHT      = 11'b00000001000,
DOWN       = 11'b00000010000,
JUMP       = 11'b00000100000,
UPLEFT     = 11'b00001000000,
UPRIGHT    = 11'b00010000000,
DOWNLEFT   = 11'b00100000000,
DOWNRIGHT  = 11'b01000000000, // FIXED (11 bits)
DEATH      = 11'b10000000000;

assign {Qinit, Qidle, Qleft, Qright, Qdown, Qjump,
        Qupleft, Qupright, Qdownleft, Qdownright, Qdeath} = state;

//================ FLAGS =================
reg jumpflag;
reg [10:0] jumpcount, dashcount;

//================ FSM =================
always @(posedge clk) begin
    if (rst) begin
        state <= INIT;
        vx <= 0;
        vy <= 0;
        jumpflag <= 0;
    end
    else begin
        case(state)
            INIT:
                begin
                    //actions
                    jumpflag <=0;
                    //rtl
                    state <= IDLE;
                end
            IDLE:
                begin
                    //actions: x and y don't change (unless there is gravity)

                    //gravity code:

                    // jumpflag <= 0; //no conditions for now for testing
                    // vx <= 0;
                    // vy <= 0;
                    //rtl
                    if(BtnL)begin //debounce these later
                        state <= LEFT;
                    end
                    if(BtnR)begin
                        state<=RIGHT;
                    end
                    if(BtnU)begin
                        state <= JUMP;
                    end
                    if(BtnD)begin
                        state <=DOWN;
                    end
                    if(BtnU & BtnL)begin
                        state <=UPLEFT;
                    end
                    if(BtnU & BtnR)begin
                        state <= UPRIGHT;
                    end
                    if (BtnD & BtnL)begin
                        state <= DOWNLEFT;
                    end
                    if (BtnD & BtnR)begin
                        state <= DOWNRIGHT;
                    end

                end
            LEFT:
                begin
                    //
                    vx <= -1;
                    //rtl
                    if(!BtnL)begin
                        state<=IDLE;
                    end

                end
            RIGHT:
                begin
                    vx <= 1;
                    //rtl
                    if(!BtnR)begin
                        state <= IDLE;
                    end
                end
            DOWN: 
                begin
                    vy <= 1;
                    if(!BtnD)
                        state <= IDLE;
                    
                end
            JUMP:
                begin
                    if(jumpflag == 0)begin //debouce eventually
                        vy <= -20;
                        jumpflag <= 1; //cannot jump again until this becomes 0
                    end
                    state <= IDLE;
                end
            UPLEFT:
                begin
                    if(jumpflag == 0)begin
                        vy <= -20;
                        jumpflag <= 1;;
                    end
                    vx <= -1;
                    if(BtnL)
                        state <= LEFT; //keep moving left even after jump if left is still pressed 
                    else
                        state <= IDLE;
                end
            UPRIGHT:
                begin
                    if(jumpflag == 0)begin
                        vy <= -20;
                        jumpflag <= 1;;
                    end
                    vx <= 1;
                    if(BtnR)
                        state <= RIGHT; //keep on moving right even post jump until BtnL not pressed
                    else
                        state <= IDLE;
                end
            DOWNLEFT:
                begin
                    vy <= 1;
                    vx <= -1;
                    if(!BtnD & !BtnL)
                        state <= IDLE;
                    else if (BtnL & !BtnD)
                        state <= LEFT;
                    else if (!BtnL & BtnD)
                         state <= DOWN;
                end
            DOWNRIGHT:
                begin
                    vy <= 1;
                    vx <= 1;
                    if(!BtnD & !BtnR)
                        state <= IDLE;
                    else if (BtnR & !BtnD)
                        state <= LEFT;
                    else if (!BtnR & BtnD)
                         state <= DOWN;
                end
            DEATH: 
                begin
                end
        endcase
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
        nextX = x + vx;
        nextY = y + vy;
        // ===== GRAVITY =====
        if (!collide_bottom)
            vy <= vy + 1;   // falling
        else
        begin
            vy <= 0;        // on ground
            jumpflag <= 0;
        end
        // ===== X MOVEMENT =====
        if (vx < 0 && !collide_left)
            x <= x + vx;
        else if (vx > 0 && !collide_right)
            x <= x + vx;

        // ===== Y MOVEMENT =====
        if (vy < 0 && !collide_top)
            y <= y + vy;
        else if (vy > 0 && !collide_bottom)
            y <= y + vy;
    end
end

endmodule