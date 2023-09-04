module code_verify(info_received, check_info);
    input [7:0] info_received;
    output  check_info;
	/*
    always @* begin
        case(info_received)
            8'h0x00 : check_info = 1'b1; 
            8'h0x01 : check_info = 1'b1; //solicita situação atual do sensor
            8'h0x02 : check_info = 1'b1; //solicita medida de temperatura atual
            8'h0x03 : check_info = 1'b1; //temperatura continua
            8'h0x04 : check_info = 1'b1; //umidade continua
            8'h0x05 : check_info = 1'b1; //temperatura continua desativada
            8'h0x06 : check_info = 1'b1; //umidade continua desativada
            default:check_info=1'b0;
        endcase
    end
	 */
	 assign check_info =1'b1;
endmodule