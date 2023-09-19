//versão v2 da maquina geral de estados


module general_MEF(clock, dht_data, rx_serial,tx_serial, segmento_B, segmento_C, segmento_A, seven_segmentos0, seven_segmentos1);
	input clock, rx_serial; //entrada de clock, e informação proveniente da porta serial
	inout dht_data; //entrada e saida de dados do sensor DHT11
	output tx_serial, segmento_B, segmento_C, segmento_A; //saida para enviar informações pela serial, e informações para debug
	output reg [7:0] seven_segmentos0, seven_segmentos1; //para apresentar informações nos displays de 7 segmentos

	/*fios para: sinal da serial recebedio;
				 transmissao ocorrendo pela porta serial
				 transmissao concluida
				 finalizada a leitura provinda do dht11
				 verificação se o protocolo enviado esta correto
				 trabalhar com o byte recebido pela porta serial
				 trabalhar com o byte recebido pela maquina do sensor
	*/
	wire rx_done, tx_ocurring, tx_fineshed, read_fineshed, verify_code;
	wire [7:0] info_rx; //informação recebida pela uart
	wire [7:0] info_interface; //informação que vem com primeiros 8 bits de dados proveniente do sensor

	/*registradores para: ativar a transmissão dos dados
						  iniciar a maquina de estados
						  acendimento do segmento B do display direito
						  acendimento do segmento C do display direito
						  acendimento do segmento A do display direito
						  informar a maquina de "interface" do sensor qual informação deseja receber dele
						  guardar o primeiro protocolo recebido pela porta serial
						  guardar o endereço do sensor recebido pela porta serial
						  registrar qual informação será transmitida pela porta serial
	
	*/
	reg active_tx, start_machine, seg_b, seg_c, seg_a;
	reg [1:0] request = 2'b00; //diz para a "interface" do sensor qual informação esta sendo requisitada
	reg [7:0] protocol_01, protocol_02, info_send; //registradores para salvar os 2 bytes recebidos, e o byte de envio

	initial start_machine <=1'b0;

	//contadores
	reg [15:0] counter = 16'd0;
	reg [24:0] cnt; //contador
	reg[31:0] counter_continuous;
	initial counter_continuous = 32'd0;
	initial cnt = 25'd0;




	 
	
	
	//receber os dados da uart e colocar buffers, organizando da forma: 1º byte sendo o protocolo, e o 2º byte o endereço
	reg selector_buffer = 1'b0;

	//chamada do modulo da UART RX para recebimento dos dados
	uart_rx receiver_uart (clock, rx_serial, rx_done, info_rx);

	/*
	Logica para colocar os dados recebidos pela uart no seu buffer correto
	Funcionamento:
		verifica se recebeu uma informação, e se o seletor é igual a 0, em caso positivo, irá 
		guardar no primeiro buffer, e mudar o valor do seletor, para que o proximo dado seja colocado
		no segundo buffer, em que quando isso ocorrer, irá voltar o seletor para o valor inicial, igual a 0
		permitindo que a proxima informação recebida, um protocolo adjunto com um endereço, seja guardado no
		buffer correto
	*/
	always @(posedge clock)
		begin
			//recebeu um byte, e o seletor tava em 0, logo coloca a informação recebida no primeiro buffer
			if(rx_done ==1'b1 && selector_buffer == 1'b0)
				begin
					protocol_01 <= info_rx;	//passa a informação para o buffer
					start_machine <= 1'b0;
					selector_buffer = 1'b1; //muda o seletor, para indicar que o primeiro buffer ja tem conteudo
				end
			//recebeu um byte e o seletor tava em 1, logo coloca a informação recebida no segundo buffer
			else if (rx_done == 1'b1 && selector_buffer == 1'b1)
				begin
					protocol_02 <= info_rx; //passa a informação recebida para o buffer
					//se o start machine der ERRO, pode continuar do modo antigo, que n tava dando erro
					start_machine <=1'b1; //informa que ja recebeu e registrou os 2 bytes, e pode começar a operar
					selector_buffer = 1'b0; //altera o seletor do buffer para 0, para indicar que a proxima informação deverá ser guardada la
				end
  		end
	

	//realiza uma decodificação do codigo de comando recebido, e deixa salvo num flag se é valido ou nao
	code_verify verify (protocol_01, verify_code);


	//codigos de cada um dos estados
	localparam [2:0] s_idle = 3'b000, s_check_code =3'b001, s_invalid_code = 3'b010, s_reading = 3'b011, s_information = 3'b100;
	

	//registrador para funcionamento da estrutura da maquina de estados
	reg [2:0] choose_case;


	//chamada do modulo da UART TX
	uart_tx transmiter_data (clock, active_tx, info_send, tx_serial, tx_fineshed);
	

	//chamada da maquina do sensor - funciona como uma interface para cada sensor
	sensor_01_MEF sensor00 (clock, request, dht_data, info_sensor, read_fineshed);


	always @(posedge clock)
		begin
			case(choose_case)
				s_idle: 	//estado de espera, e default
					begin
						//informações para o debug
						seg_b = 1'b0;
						seg_c = 1'b0;
						seg_a = 1'b1;

						//protocol_02 = 8'd00000; //definindo o endereço do sensor 0

						active_tx = 1'b0; //desativa a uart TX
						//apos a informação ter sido completamente recebida, é passado para o estado de checagem do que foi recebido
						if(start_machine == 1'b1) 
							begin	
								active_tx = 1'b0; //desativa a uart TX
								choose_case <=s_check_code; 
							end
						else if(start_machine == 1'b0) //fica nesse estado enquanto ele nao recebe outros dados
							begin
								active_tx = 1'b0; //desativa a uart TX
								choose_case <= s_idle; //permanecer no estado de espera
							end
						
					end
					

				s_check_code: //estado de verificaçao do codigo recebido na uart
					begin
						//se o codigo que foi recebido é algo valido ele mostra que recebeu o codigo
						if(verify_code == 1'b1)
							begin
								//confirma que recebeu a info correta no display de 7 segmentos da esquerda
								seven_segmentos0 = 8'b00111001; //para formar a letra C no display de 7 segmentos da esquerda
								choose_case <= s_reading; //prossegue para o estado de leitura, para realizar ela
							end
						else if(verify_code == 1'b0)//caso o codigo que tenha sido recebido na FPGA tenha sido invalido, ele retorna isso
							begin
								//leva para o estado que enviar a informação
								//de que o comando recebido é invalido
								choose_case <= s_invalid_code;
							end
								
					end


				s_invalid_code: //codigo que informa sobre o codigo ser invalido
					begin
						//informação de debug - saber em qual estado esta
						seg_b = 1'b1;
						seg_c = 1'b0;
						seg_a = 1'b0;



						seven_segmentos1 = 8'b11111001; //acende no display de 7 segmentos a informação de que a informação ta errada
						
						//define a informação registrada, para ser enviada via uart tx
						info_send <= 8'h0xFB; //comando de codigo invalido
						active_tx = 1'b1; //ativa a uart
						//verifica se o primeiro byte ja foi enviado, em caso positivo, desativa a TX, e seta o segundo byte para enviar
						if(tx_fineshed == 1'b1) 
                            begin
								active_tx = 1'b0; //desativa a uart para n ficar mandando a informação continuamente
								info_send <= 8'h0xFC; //define o byte secundario necessario para enviar ao computador (precisa mandar 2 bytes)
                                choose_case <= s_information; //vai para o estado que manda o segundo byte
                            end
						//condição para permanencia nesse estado enquanto, nao termina de mandar a informação pela uart
						else if (tx_fineshed == 1'b0)
							begin
								choose_case <= s_invalid_code; 
							end
					end


				s_reading: //estado que realiza a leitura do sensor
					begin
						//informações para debug
						seg_b = 1'b0;
						seg_c = 1'b1;
						seg_a = 1'b0;
						
						
						//caso que eh para estar funcionando, vulgo corrigido
						if(protocol_01 == 8'h0x05 ) //desativação da leitura continua de temperatura
							begin
								if(protocol_02 == 8'd0) //conferir se o endereço de sensor recebido, equivale a um sensor registrado
									begin
										info_send <= 8'h0x0A; //confirmaçao de desativacao da temp continua
										active_tx = 1'b1; //ativa a tx para envio dos dados
										if(tx_fineshed == 1'b1) //quando terminar de mandar a informação muda de estado
											begin
												active_tx = 1'b0; //desativa a tx para nao ficar mandando dados continuamente
												info_send <= 8'h0xFC; //seta o segundo byte no registrador para ser enviado
												choose_case <= s_information; //vai ao estado que envia a informação
											end
										else if(tx_fineshed == 1'b0) //continua nesse estado enquanto o envio nao tiver terminado
                                            begin
                                                choose_case <= s_reading;
                                            end
										
									end
								//caso seja enviado um endereço que nao seja valido, vai para o estado de informação invalida informar isto
								else 
									begin
										choose_case <= s_invalid_code;
									end
							end


						else if(protocol_01 == 8'h0x06) //desativação da leitura continua de umidade
							begin
								if(protocol_02 == 8'd0) //verifica o endereço do sensor, se é um dos 32
									begin
										info_send <= 8'h0x0B; //confirmacao de desativacao do sensoriamento continuo
										active_tx = 1'b1; //ativa o envio de dados pela porta serial
										if(tx_fineshed == 1'b1)
											begin
												active_tx = 1'b0; //desativa a transmissao de dados
												info_send <= 8'h0xFC; //seta o segundo byte para ser enviado
												choose_case <= s_information; //vai para o estado de envio do segundo byte
											end
										else
											begin
												choose_case <= s_reading;
											end 
									end
								//caso seja enviado um endereço que nao seja valido, vai para o estado de informação invalida informar isto
								else
									begin
										choose_case <= s_invalid_code;
									end
								
							end


						else if(protocol_01 == 8'h0x03) //sensoriamento continuo de temperatura
							begin
								//explicando o codigo: //SE TIVER OK, REPLICAR PARA O CODIGO DA UMIDADE CONTINUA
								/*
								primeiro if: ele verifica se o contador chegou em 60 segundos
									se tiver chegado ele executa o trampo de mandar a informação
									e deixa o contador c o valor 1 ao final
										objetivo de deixar c valor 1: nao cair no segundo if e mandar a informação 2 vezes
								segundo if: ele verifica se o contador é 0, para o caso da primeira execução
									nesse caso ele executa a operação de mandar a informação
								terceiro if(else): serve para realizar incrementos no contador
									o contador nao vai entrar no primeiro nem no segundo if pela logica...
								*/
								if(counter_continuous == 32'b10110010110100000101111000000000)
									begin
										if(protocol_02 == 5'b00000)
										begin
											request =2'b01;
											info_send <=8'h0xFD;
											active_tx = 1'b1;
											
											//outra parte da informação enviada pela maquina do sensor
											if(read_fineshed == 1'b0)
												begin
													choose_case <=s_reading;
												end
											if(read_fineshed == 1'b1)
												begin
													//colocar um contador aq para ele ficar aq
													request = 2'b11; // codigo invalido para desativar a maquina do sensor por um momento
													counter_continuous = counter_continuous + 1'b1;
													
														begin
															request =2'b01;
															counter_continuous = 32'd1;
														end
												end
										end
									end
								if(counter_continuous == 32'd0)
									begin
										if(protocol_02 == 5'b00000)
										begin
											request =2'b01;
											info_send <=8'h0xFD;
											active_tx = 1'b1;
											if(counter > 3'b011)
												begin
													active_tx = 1'b0;
													
													choose_case <= s_reading; 
												end
											//outra parte da informação enviada pela maquina do sensor
											if(read_fineshed == 1'b0)
												begin
													choose_case <=s_reading;
												end
											if(read_fineshed == 1'b1)
												begin
													//colocar um contador aq para ele ficar aq
													request = 2'b11; // codigo invalido para desativar a maquina do sensor por um momento
													counter_continuous = counter_continuous + 1'b1;
													
														begin
															request =2'b01;
															counter_continuous = 32'd0;
														end
												end
										end
									end
								else
									begin
										counter_continuous = counter_continuous + 1'b1;
									end
								//essa parte ate o final acho q pode ser add para dentro da seção do protocolo
								
								choose_case <= s_reading;
							end


						else if(protocol_01 == 8'h0x04) //sensoriamento continuo de umidade
							begin
								if(protocol_02 == 5'b00000) //verificar se o endereço corresponde ao sensor 00
									begin
										
									end
								else
									begin
										choose_case <= s_invalid_code;
									end
								choose_case <= s_reading;
							end


						else if(protocol_01 == 8'h0x00) //situação do sensor
							begin
								if(protocol_02 == 5'b00000) //verificar se o endereço corresponde ao sensor 00
									begin
										request = 2'b10; //request para a maquina do sensor verificar se ele esta funcionando normalmente
										//informação enviada pela maquina do sensor
										if(read_fineshed == 1'b0) 
											begin
												choose_case <=s_reading;
											end
										//quando o sensor terminar de realizar a leitura inicia o procedimento
										else
											begin
												if(info_sensor == 8'b11111111) //informação de que o sensor esta com problema
													begin
														info_send <= 8'h0x1F; //sensor com problema
														active_tx = 1'b1; //ativa o envio de dados pela porta serial
                                                        if(tx_fineshed == 1'b1)
                                                            begin
																active_tx = 1'b0; //desativa a transmissao de dados
																info_send <= 8'h0xFC; //seta o segundo byte para ser enviado
                                                                choose_case <= s_information; //vai para o estado de envio do segundo byte
                                                            end
                                                        else
                                                            begin
                                                                choose_case <= s_reading;
															end
													end
												else if(info_sensor == 8'd0) //sensor sem problemas
													begin
														info_send <= 8'h0x07; //sensor funcionando normalmente
														active_tx = 1'b1; //ativa o envio de dados pela porta serial
														if(tx_fineshed == 1'b1) //quando a informação é totalmente enviada entra 
															begin
																active_tx = 1'b0; //desativa a transmissao de dados
																info_send <= 8'h0xFC; //seta o segundo byte para ser enviado
																choose_case <= s_information; //vai para o estado de envio do segundo byte
															end
                                                        else //enquanto nao termina de mandar os dados, continua aqui
                                                            begin
                                                                choose_case <= s_reading;
                                                            end
													end
											end
									end
									//caso seja enviado um endereço que nao seja valido, vai para o estado de informação invalida informar isto
									else
										begin
											choose_case <= s_invalid_code;
										end
							end


						else if(protocol_01 == 8'h0x01) //medida atual de temperatura
							begin
								if(protocol_02 == 5'b00000) //verificar se o endereço corresponde ao sensor 00
									begin
										//info de debug
										seg_b = 1'b1;
										seg_c = 1'b1;
										seg_a = 1'b1;

										
										request = 2'b01; //request indicando que ta fazendo o pedido de temperatura
										info_send <= 8'h0x09; //protocolo de resposta para medida de temperatura
										active_tx = 1'b1; //ativa a transmissao do primeiro byte
										
										if(tx_fineshed == 1'b1)
                                            begin
												active_tx = 1'b0;
												//verificar essa parte quando tiver com a placa para ver se ele entra aqui, ou se passa direto
												if(read_fineshed == 1'b1)
													begin
														info_send <= info_sensor; //seta o segundo byte para ser a informação tratada do sensor
														choose_case <= s_information; //vai para o estado de envio do segundo byte
													end
												else if(read_fineshed == 1'b0)//enquanto nao tiver finalizado a leitura pelo dht11, vai continuar aqui nesse estado
													begin
														choose_case <= s_reading;
													end
																
                                            end
                                        else if (tx_fineshed == 1'b0)
                                            begin
                                                choose_case <= s_reading;
                                            end
									end
								//caso seja enviado um endereço que nao seja valido, vai para o estado de informação invalida informar isto
								else 
									begin
										choose_case <= s_invalid_code;
									end
							end


						else if(protocol_01 == 8'h0x02) //medida atual de umidade
							begin
								if(protocol_02 == 5'b00000) //ver se o endereço corresponde ao sensor 00
									begin
										request = 2'b00; //request de umidade para a interface do sensor
										info_send <= 8'h0x08; //medida de umidade
										active_tx = 1'b1; //ativa o envio de dados pela porta serial
										if(tx_fineshed ==  1'b1)
											begin
												active_tx = 1'b0; //desativa a transmissao de dados
												if(read_fineshed == 1'b1) //quando o sensor terminar de realizar a leitura inicia o procedimento
													begin
														info_send <= info_sensor; //seta o segundo byte de envio com informação lida pelo sensor
														choose_case <= s_information; //vai para o estado de envio do segundo byte
													end
												else
													begin
														choose_case <= s_reading;
													end
											end
										else
											begin
												choose_case <= s_reading;
											end
									end		
								//caso seja enviado um endereço que nao seja valido, vai para o estado de informação invalida informar isto
								else if(protocol_02 != 8'd0) 
									begin
										choose_case <=s_invalid_code;
									end
							end


						else
							begin
								//se a entrada n for nenhum dos codigos previstos, vai para o estado para informar que
								//o codigo que recebeu foi invalido
								//estando nesse estado de leitura, so pode receber uma requisição de pedido de leitura ou
								//de cancelamento da leitura dos dados
								choose_case <=s_invalid_code;
							end
					end


				s_information: //estado para envio do segundo byte para o computador
                    begin
                        //ativa a uart tx para poder começar a transmitir os dados
						active_tx = 1'b1;
						if(tx_fineshed == 1'b1)
							begin
								active_tx = 1'b0; //uart tx desativada
								choose_case <= s_idle; //volta para o estado de espera, pois ja terminou de mandar os dados
							end
						else if (tx_fineshed == 1'b0)
							begin
								choose_case <= s_information;
							end
                    end
						  
                    
				default: //define o estado padrao
					begin
						active_tx = 1'b0;
						choose_case <= s_idle;
					end
			endcase
		end
	

//seg_a = estado de espera
//seg_c = lendo
//seg_b = codigo invalido
//branco (td ligado) = saber se esta aonde deseja no codigo
//magenta (R e B) = 



assign segmento_B = seg_b;
assign segmento_C = seg_c;
assign segmento_A = seg_a;	




endmodule

//ideia usar um temporizador que esta no estado de leitura continua, ai quando da aquele
//termina a leitura ele vai para o estado de espera, se der o tempo, e nao tiver recebido 
//nenhuma outra requisição, volta para o estado de leitura pra poder ler
//caso tenha recebido uma requisição, tem que ver de que tipo ela é, pq com o continuo ativo
//so pode receber codigo pedindo para desativar, por mais que seja ativado dnv pelo pc automaticamente