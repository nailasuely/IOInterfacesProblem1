module protocol_decoder(received_info, protocol_response);
    input [7:0] received_info;
    output reg [7:0] protocol_response;

    always @*begin
        case (received_info)
            7'h0x00 : protocol_response = 7'h0xF0; //
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0;
            7'h0x01 : protocol_response = 7'h0xF0; 
            
            default:protocol_response=7'b00000000;
        endcase
    end

endmodule 

