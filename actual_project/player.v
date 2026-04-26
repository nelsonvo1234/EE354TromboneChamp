module player(
    input wire clk,
    input wire rst,
    input SW0, BtnC, BtnL, BtnR, BtnU, BtnD,

    output reg [9:0] x,
    output reg [9:0] y,

    output Qinit, Qidle, Qleft, Qright, Qdown, Qjump, Qupleft, Qupright, Qdownleft, Qdownright, Qdeath;
)
reg [10:0] state;
localparam
INIT = 11'b00000000001,
IDLE = 11'b00000000010,
LEFT = 11'b00000000100,
RIGHT = 11'b00000001000,
DOWN = 11'b00000010000,
JUMP = 11'b00000100000,
UPLEFT = 11'b00001000000,
UPRIGHT = 11'b00010000000,
DOWNLEFT = 11'b00100000000,
DOWNRIGHT = 11'010000000000,
DEATH = 11'b10000000000,
UNK = 11'bXXXXXXXXXXX;

assign {Qinit, Qidle, Qleft, Qright, Qdown, Qjump, Qupleft, Qupright, Qdownleft, Qdownright, Qdeath} = state;

reg jumpflag, dashflag;
reg [10:0] jumpcount, dashcount; //how long it will jump and dash for
always @(posedge clk)begin
    if(rst) begin
        state <= INIT;
        x <= 10;
        y <= 10;
        jumpflag <= 0;
    end
    else begin
        case(state)
            INIT:
                begin
                    //actions
                    x<=0;
                    y<=0;
                    jumpflag <=0;
                    //rtl
                    state <= IDLE;
                end
            IDLE:
                begin
                    //actions: x and y don't change (unless there is gravity)

                    //gravity code:

                    jumpflag <= 0; //no conditions for now for testing

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
                    if(x>=0)begin
                        x<=x-1;
                    end
                    //rtl
                    if(!BtnL)begin
                        state<=IDLE;
                    end

                end
            RIGHT:
                begin
                    if(x<= 0'b11111111111)begin
                        x<=x+1;
                    end
                    //rtl
                    if(!BtnR)begin
                        state <= IDLE;
                    end
                end
            DOWN: 
                begin
                    if(x>=0)
                        y <= y-1;
                    
                    //rtl
                    if(!BtnD)
                        state <= IDLE;
                    
                end
            JUMP:
                begin
                    if(y<=0'b11111111111)begin
                        y<= y+20;
                        jumpflag <= 1; //cannot jump again until this becomes 0
                    end
                    state <= IDLE;
                end
            UPLEFT:
                begin
                    jumpflag <= 1;
                    if(y<=0'b11111111111)
                        y <= y + 20;
                    if( x>=0)
                        x <= x - 1;
                    //rtl
                    if(BtnL)
                        state <= LEFT; //keep moving left even after jump if left is still pressed 
                    else
                        state <= IDLE;
                end
            UPRIGHT:
                begin
                    jumpflag <= 1;
                    if(y<=0'b11111111111)
                        y <= y + 20;
                    if( x<=0'b11111111111)
                        x <= x + 1;
                    //rtl
                    if(BtnL)
                        state <= RIGHT; //keep on moving right even post jump until BtnL not pressed
                    else
                        state <= IDLE;
                end
            DOWNLEFT:
                begin
                    if(y>=0)
                        y <= y - 1;
                    if( x>=0)
                        x <= x - 1;
                    if(!BtnD & !BtnL)
                        state <= IDLE;
                    else if (BtnL & !BtnD)
                        state <= LEFT;
                    else if (!BtnL & BtnD)
                         state <= DOWN;
                end
            DOWNRIGHT:
                begin
                    if(y>=0)
                        y <= y - 1;
                    if( x<=0'b11111111111)
                        x <= x + 1;
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
endmodule