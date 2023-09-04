module general_MEF(clock, dht_data, rx_serial,tx_serial, transmission_active, vm, ve, az);
	input clock, rx_serial;
	inout dht_data;
	output reg tx_serial;
	output transmission_active;
	output vm, ve, az;
	/*
	CRIAR UM DECODIFICADOR PARA DEPENDENDO DA INFORMAÇÃO QUE CHEGAR PELO RX
	DEFINIR O CODIGO DE SAIDA PARA O COMPUTADOR
	*/
	reg vermelho, verde, azul;
	wire rx_done, rx_done1;
	reg tx_done, selector_reg;
	reg [7:0] protocol_01, protocol_02; //registradores para salvar os 2 bytes recebidos
	wire [7:0] info_rx; //informação recebida pela uart
	wire [8:0] info_interface; //informação que vem com primeiros 8 bits de dados
								//ultimo bit, o MSB, é para informar informação 100% lida
	
	//receber os dados da uart e colocar um buffer
	//colocar verificação para os dados nao sobreescrever
	reg cavalo_troia;
	wire verify_code;
	//assign rx_done = 1'b0;
	//assign rx_done1 = 1'b0;
	uart_rx receiver_uart1 (clock, rx_serial, rx_done, info_rx);
	//coloca os dados recebidos pela uart num registrador

	always @(posedge rx_done)
		begin
			protocol_01 <= info_rx;
			
		end
		

	
	uart_rx receiver_uart2 (clock, rx_serial, rx_done1, info_rx);
	//coloca os dados recebidos pela uart num registrador

	always @(posedge rx_done1)
		begin
			protocol_02 <= info_rx;
		end



	//realiza uma decodificação do codigo de comando recebido, e deixa salvo num flag se é valido ou nao
	code_verify verify (protocol_01, verify_code);

	//codigos de cada um dos estados
	localparam [1:0] s_idle =2'b00, s_check_code =2'b01, s_invalid_code = 2'b10, s_reading = 2'b11;
	
	//registrador para funcionamento da estrutura se
	reg [1:0] choose_case;
	
	
	
	always @(posedge clock)
		begin
			case(choose_case)
				s_idle: 	//estado de espera
					begin
						//apos a informação ter sido completamente recebida, é passado para o estado de checagem
						if(rx_done == 1'b1) 
							begin
								choose_case <=s_check_code;
							end
						else //fica nesse estado enquanto ele nao recebe outros dados
							begin
								verde = 1'b0;
								azul = 1'b1;
								vermelho = 1'b0;	
								cavalo_troia = 1'b1;
								choose_case <= s_idle;
								
							end
						
					end
					
				s_check_code: //estado de verificaçao do codigo recebido na uart
					begin
						//se o codigo que foi recebido é algo valido ele envia a informação de que recebeu o codigo
						if(cavalo_troia == 1'b1)
							begin
							
								verde = 1'b1;
								azul = 1'b0;
								vermelho = 1'b0;
								choose_case <= s_reading; //prossegue para realizar a leitura
							end
						else //caso o codigo que tenha sido recebido na FPGA tenha sido invalido, ele retorna isso
							begin
								//enviar a informação de que o comando recebido é invalido
								//esse trecho de codigo pode descer para o s_invalid_code
								
								choose_case <= s_reading; //vai para o estado de dizer que o codigo ta invalido
							end
								
					end
				//ESTADO PARA SER ESTUDADO A SUA REMOÇÃO
				s_invalid_code: //codigo que informa sobre o codigo ser invalido
					begin
						verde = 1'b0;
						azul = 1'b0;
						vermelho = 1'b1;
						choose_case <= s_idle;
					end
					
				s_reading: //estado que realiza a leitura do sensor
					begin
						//desativação da leitura continua de 
						if(rx_serial == 8'h0x05 )
							begin
								
								choose_case <= s_idle;
							end
						if(rx_serial == 8'h0x06)
							begin
								
							end
						if(rx_serial == 8'h0x03)
							begin
								if(protocol_02 == 5'b00000) //verificar se o endereço corresponde ao sensor 00
									begin
										
									end
								choose_case <= s_reading;
							end
						if(rx_serial == 8'h0x04)
							begin
								if(protocol_02 == 5'b00000) //verificar se o endereço corresponde ao sensor 00
									begin
										
									end
								choose_case <= s_reading;
							end
						if(rx_serial == 8'h0x00) //situação do sensor
							begin
								if(protocol_02 == 5'b00000) //verificar se o endereço corresponde ao sensor 00
									begin
										
									end
									//colocar modulo da uart para mandar info recebida para o pc
								choose_case <= s_idle;
							end
						if(rx_serial == 8'h0x01) //medida atual de temperatura
							begin
								if(protocol_02 == 5'b00000) //verificar se o endereço corresponde ao sensor 00
									
								choose_case <= s_idle;
							end
						if(rx_serial == 8'h0x02) //medida atual de umidade
							begin
								if(protocol_02 == 5'b00000) //ver se o endereço corresponde ao sensor 00
									begin
										
									end
								
								choose_case <= s_idle;
							end
						
						// if(info_interface[8]==1'b1)
						// 	begin
						// 		uart_tx send_data (clock, 1'b1, 8'h0x0B, teste, tx_serial, tx_done);
						// 		always @(negedge tx_done)
						// 			begin
						// 				uart_tx send_data2 (clock, 1'b1, 8'h0xFC, teste, tx_serial, tx_done);
						// 			end
						// 		//provavelmente vai ter outra chamada dessa função de envio de dados
						// 		choose_case <= s_IDLE;
						// 	end
						else
							begin
								choose_case <=s_reading;
							end
					end
				
				default: //define o estado padrao
					choose_case <= s_idle;
			endcase
		end
	
	
	


assign vm = verde;
assign ve = vermelho;
assign az = azul;


endmodule


//Error (10170): Verilog HDL syntax error at general_MEF.v(116) near text: "(";  expecting ";". Check for and fix any syntax errors that appear immediately before or at the specified keyword. The Intel FPGA Knowledge Database contains many articles with specific details on how to resolve this error. Visit the Knowledge Database at https://www.altera.com/support/support-resources/knowledge-base/search.html and search for this specific error message number.



//ideia usar um temporizador que esta no estado de leitura continua, ai quando da aquele
//termina a leitura ele vai para o estado de espera, se der o tempo, e nao tiver recebido 
//nenhuma outra requisição, volta para o estado de leitura pra poder ler
//caso tenha recebido uma requisição, tem que ver de que tipo ela é, pq com o continuo ativo
//so pode receber codigo pedindo para desativar, por mais que seja ativado dnv pelo pc automaticamente