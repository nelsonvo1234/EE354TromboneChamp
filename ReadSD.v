module SD_Command(
    input wire [7:0] cmd,
    input wire [31:0] arg,
    input wire [7:0] crc,

    input wire start,
    input wire rst,
    input wire clk,

    // SPI interface (connect to external SPI module)
    output reg SPIstart,
    output reg [7:0] data_in,
    input wire SPIdone,

    output reg done
);

typedef enum reg [1:0] {
    IDLE,
    LOAD,
    SEND,
    WAIT,
    DONE
} state_t;

state_t state;

reg [2:0] bytes_sent;
reg [47:0] packet;   // 6 bytes total

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        bytes_sent <= 0;
        done <= 0;
        SPIstart <= 0;
        data_in <= 0;
    end
    else begin
        case(state)

        // -----------------
        IDLE: begin
            done <= 0;
            SPIstart <= 0;
            bytes_sent <= 0;

            if(start) begin
                state <= LOAD;
            end
        end

        // -----------------
        LOAD: begin
            // Build full command packet
            packet <= {
                (cmd | 8'h40),
                arg[31:24],
                arg[23:16],
                arg[15:8],
                arg[7:0],
                crc
            };

            state <= SEND;
        end

        // -----------------
        SEND: begin
            data_in <= packet[47:40]; // send top byte
            SPIstart <= 1;
            state <= WAIT;
            if (SPIdone) begin
                packet <= packet << 8;
                bytes_sent <= bytes_sent + 1;

                if (bytes_sent == 5) begin
                    state <= DONE;
                end
                else begin
                    state <= SEND;
                end
            end
        end

        // -----------------
        WAIT: begin
            SPIstart <= 0;


        end

        // -----------------
        DONE: begin
            done <= 1;
            state <= IDLE;
        end

        endcase
    end
end

endmodule

module SD_powerUpSeq(input wire clk,
input wire rst, input wire start, output wire done, output wire cs)

typedef enum reg [2:0] {
    IDLE,
    CS_DISABLE,
    DELAY,
    SYNCHRONIZE,
    DONE
} state_t;

reg [7:0] data_in;
reg [7:0] data_out;
reg SPIdone;
wire SPIstart

state_t state;

spi_master(.clk(clk), .rst(rst), .start(SPIstart), .data_in(data_in),
	.data_out(data_out),
	.done(SPIdone),
	.clk_div_amount(8'd50),

	.sclk(sclk), 
	.mosi(mosi), 
	.miso(miso)
	// .cs(cs)
    );

wire ms = 450000;
wire delayCount;

wire sendCount = 0;
always @ (posedge clk or posedge rst)
begin
    if(rst) begin
        done <= 0;
        state <= IDLE;
    end
    else begin
        case(state)
        IDLE: begin
            done <= 0;
            if(start) begin
                cs <= 1;
                data_in <= 0xFF;
                state <= CS_DISABLE;
                SPIstart <= 1;
            end
        end
        CS_DISABLE: begin
            if(SPIdone) begin
                SPIstart <= 0;
                if(sendCount != 10) begin
                    state <= DELAY;
                end
                else begin
                    state <= DONE;
                end
            end
        end
        DELAY: begin
            delayCount <= delayCount + 1;
            if(delayCount == ms) begin
                state <= SYNCHRONIZE;
                SPIstart <= 1;
            end
        end
        SYNCHRONIZE: begin
            if(SPIdone) begin
                sendCount <= sendCount + 1;
                if(sendCount == 9) begin
                    state <= CS_DISABLE;
                    cs <= 1;
                    SPIstart <= 1;
                end
            end
        end
        DONE: begin
            done <= 1;
            state <= IDLE;
        end
    end
end

end module

module ReadSD(    
    input wire start,
    input wire rst,
    input wire clk,

    output reg sclk, 
	output reg mosi, 
	input wire miso, 
	output reg cs

    output wire done)

wire[7:0] cmd;
wire [31:0] arg;
wire [7:0] crc;

wire command_start;
wire command_done;
SD_Command(
    .cmd(cmd),
    .arg(arg),
    .crc(crc),

    .start(command_start),
    .rst(rst),
    .clk(clk),

    .sclk(sclk), 
	.mosi(mosi), 
	.miso(miso), 
	.cs(cs),

    .done(command_done)
)

wire SPIstart;
wire [7:0] data_in;
wire [7:0] data_out;
wire SPIdone;
spi_master(.clk(clk), .rst(rst), .start(SPIstart), .data_in(data_in),
	.data_out(data_out),
	.done(SPIdone),
	.clk_div_amount(8'd50),

	.sclk(sclk), 
	.mosi(mosi), 
	.miso(miso), 
	.cs(cs));

wire [3:0] cmdattempts;

typedef enum reg [1:0] {
    IDLE,
    SD_goIdleState,
    SD_sendIfCond,
    SD_readOCR,
    SD_sendApp,
    SD_sendOpCond,
    DONE
} state_t;

state_t CMDstate;

typedef enum reg[1:0] {
    IDLE,
    ASSERT_CHIP_SELECT,
    SEND_CMD,
    READ_RESPONSE,
    DEASSERT_CHIP_SELECT,
    DONE
}  state_i;

state_i InternalState;

always@ (posedge clk or posedge rst)begin
    if(rst)begin
        Internalstate <= IDLE;
        CMDstate <= IDLE;
    end
    else begin
        case(InternalState)
        IDLE: begin
            case(CMDstate)
            SD_goIdleState: begin
                cmd <= 0;
                arg <= 0x00000000;
                crc <= 0x94;
            end
            SD_sendIfCond: begin
                cmd <= 8;
                arg <= 0x0000001AA;
                crc <= 0x86;
            end
            SD_readOCR: begin
                cmd <= 58;
                arg <= 0x00000000;
                crc <= 0x00;
            end
            SD_sendApp: begin
                cmd <= 55;
                arg <= 0x00000000;
                crc <= 0x00;
            end
            SD_sendOpCond: begin
                cmd <= 41;
                arg <= 0x40000000;
                crc <= 0x00;
            end
        end
        ASSERT_CHIP_SELECT: begin
            if(SPIdone) begin
                if(!preTransfer) begin
                    preTransfer <= 1;
                    cs <= 0;
                end
                else begin
                    preTransfer <= 0;
                    state <= SEND_CMD;
                    command_start <= 1;
                
                end
            end
        end

        SEND_CMD: begin
            if(command_done) begin
                command_start <= 0;
                state <= READ_RESPONSE;
                SPIstart <= 1;
            end
        end

        READ_RESPONSE: begin
            // read R1
            if(SPIdone) begin
                if(data_out != 0xFF || responseTries == 7) begin
                    SPIstart <= 1;
                    cs <= 0;
                    state <= DEASSERT_CHIP_SELECT;
                end
                responseTries <= responseTries + 1;
            end

            // read R7
            if(SPIdone) begin
                responseTries <= responseTries + 1;
                if((data_out != 0xFF || responseTries == 7) && responseFlag == 0) begin
                    if(data_out > 1) begin
                        state <= DONE;
                    end
                    responseTries <= 0;
                end
                if(responseFlag == 1 && responseTries == 4) begin
                    PIstart <= 1;
                    cs <= 0;
                    state <= DEASSERT_CHIP_SELECT;
                end
            end

        end

        DEASSERT_CHIP_SELECT: begin
            if(SPIdone) begin
                if(!preTransfer) begin
                    preTransfer <= 1;
                    cs <= 1;
                end
                else begin
                    preTransfer <= 0;
                    SPIstart <= 0;
                    state <= DONE;
                end
            end
        end

    end
end



end module