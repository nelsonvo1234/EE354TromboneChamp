module moduleName #(
    parameter CHUNK_BYTES = 512, //chunk size from ssd card reader
    parameter SAMPLE_WIDTH = 16, //16 bit samples (double check if this is true for sound file used)
    parameter CHUNKS_PER_FRAME = 4, //4 512byte ssd card chunks needed
    parameter CHUNK_SAMPLES = 256, //256 samples per 512 byte chunk
    parameter FRAME_SAMPLES = 1024, //needed for 1024 resolution
    parameter ADDR_W = 10 //number of address bits needed to access sample array
) (
    input wire clk,
    input wire rst,

    input wire chunk_valid, //double check with nelson how we are doing the flag
    input wire [CHUNK_BYTES*8-1:0] chunk_data, //512bytes * 8 = that number of bits per chunk (this is all the data)
    //FFT module reading interface
    input wire [ADDR_W1:0] fft_read_addr, //address the sample the fft module wants to read
    output reg signed [SAMPLE_WIDTH-1:0] fft_read_data, //data to fft module

    input wire fft_done, //from fft module
    output reg frame_ready, //goes to fft module to signal it is done
    output reg chunk_recieved // give to ssd card reader so it can begin reading next 512 byte chunk?

    //states for debugging
    output Qempty, Qrc1, Qrc2, Qrc3, Qrc4, Qread;
);
    reg signed [SAMPLE_WIDTH-1:0] frame [0:FRAME_SAMPLES-1];
    reg [5:0] state;

//state machine states

localparam 
EMPTY = 6'b000001,
RC1 = 6'b000010,
RC2 = 6'b000100,
RC3 = 6'b001000,
RC4 = 6'b010000,
READ = 6'b100000,
UNK = 6'bxxxxxx;
assign {Qempty, Qrc1, Qrc2, Qrc3, Qrc4, Qread} = state;

reg [15:0] temp_sample; //use this to get sample from chunk, then store this at the currect index
reg [ADDR_W:0] frame_index; //index we are currently storing into frame
reg [7:0] chunk_index; //sample number current being read in chunk (NOT WHICH BIT (do like chunk_index * 16 + i to access specific bits))
reg [3:0] i;
//i only want this to happen when frame_read == 1 though

assign fft_read_data = frame[fft_read_addr];


always @(posedge clk, posedge rst)
    begin
        //reset
        if(rst)
            begin
                state <= EMPTY;
                i<=0;
                chunk_index <= 0;
                frame_index <= 0;
                temp_sample <= 0;
            end
        else
            begin
                case(state)
                    EMPTY:
                        begin
                            //empty state
                            //rtl: go to fill first chunk when chunk_valid = true
                        end
                    RC1:
                        begin
                            //fill first chunk state
                            //if sample count (chunk iterator) less than CHUNK_SAMPLES, read and store
                            //else, do nothing

                            //rtl: go to next state when chunk iterator == CHUNK_SAMPLES-1 and chunk_valid = true
                        end
                    RC2:
                        begin
                        //fill second chunk state
                        //if sample count (chunk iterator) less than CHUNK_SAMPLES, read and store
                        //else, do nothing

                        //rtl: go to next state when chunk iterator == CHUNK_SAMPLES-1 and chunk_valid = true
                        end
                    RC3:
                        begin
                        //fill third chunk state
                        //if sample count (chunk iterator) less than CHUNK_SAMPLES, read and store
                        //else, do nothing

                        //rtl: go to next state when chunk iterator == CHUNK_SAMPLES-1 and chunk_valid = true
                        end
                    RC4:
                        begin
                        //fill fourth chunk state
                        //if sample count (chunk iterator) less than CHUNK_SAMPLES, read and store
                        //else, do nothing

                        //rtl: go to next state when chunk iterator == CHUNK_SAMPLES-1 and chunk_valid = true
                        end
                    READ:
                        begin
                        //fft_reading phase
                        //frame ready flag goes true
                        //code to read? (update fft_read_data when fft_ad_data updates, or should that be outside (probably outside))
                        //rtl: move onto next phase when fft_done becomes true and go to empty state
                        end 
                endcase 
            end
    end

    
endmodule