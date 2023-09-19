module code_verify(info_received, check_info);
    input [7:0] info_received;
    output reg check_info;
	 
	 //SE DER PROBLEMA, COLOCAR DIRETO DENTRO DO CODIGO DA GENERAL_MEF
		//OUTRA ALTERNATIVA É COLOCAR O FUNCIONAMENTO COM O POSEDGE DO CLOCK, AI TEM QUE RECEBER O CLOCK
	 
	 /* COM RECEBIMENTO DE HEXADECIMAL
    always @* begin
        case(info_received)
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
	 
	 //caso com tabela ascii
	 always @* begin
		case(info_received)
			8'b00110000 : check_info = 1'b1; //0x00
			8'b00110001 : check_info = 1'b1; //0x01
			8'b00110010 : check_info = 1'b1; //0x02
			8'b00110011 : check_info = 1'b1; //0x03
			8'b00110100 : check_info = 1'b1; //0x04
			8'b00110101 : check_info = 1'b1; //0x05
			8'b00110111 : check_info = 1'b1; //0x06
			default : check_info = 1'b0;
		endcase
	end
endmodule 