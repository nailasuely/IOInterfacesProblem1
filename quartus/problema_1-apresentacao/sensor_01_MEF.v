

module sensor_01_MEF(clock,  request, dht_data, information, info_fineshed);
		// led, reset_sensor, colunas, linhas
    input clock; //entrada de clock
    input [1:0] request;    //entrada recebida pela maquina principal, sobre a requisição desejada
    inout dht_data; //entrada e saida dos dados recebidos pelo sensor
    output reg [7:0] information; //saida para a outra maquina de estados
    output reg info_fineshed; //saida para informar que ja terminou de mandar os dados

    localparam  s_idle = 2'b00, s_receiver_data = 2'b10; //definição dos estados da maquina

    reg [1:0] choose_case; //registrador para funcionamento do case
		/*
		INFORMAÇÕES ATE ENTAO NAO NESSARIAS NESSE MODULO
		reg [4:0] ui_colunas = 4'd0; 
		assign colunas = ui_colunas;
		assign linhas = information;
		*/

    //wire [7:0] hum_int, temp_int;
	 
	 /*
		Fios para:
			receber a informação do sensor de que ja terminou
			receber a informação para esperar pela resposta do sensor
			receber informação do sensor caso ele tenha dado erro
	 */
    wire readout_done, wait_sensor, error_sensor;
    
	 /*
	 Registradores:
		indicar o reset para a maquina de controle, a que tem controle temporal, do dht11
		ativar a maquina de controle do sensor
		ativar o temporizador para saber quando mudar de estado
	 
	 */
    reg rst_sensor;
	reg enable_sensor, active_timer;
	
	/*
		Fios:
			fio para receber o dado do temporizador, para assim nao passar de estado antes da hora, e resetar durante o tempo certos
			receber os dados provenientes do sensor
			fio para indicar que deve mudar de estado ou nao
	*/
    wire to_receiver; 
   wire [39:0] data_dht11; 
	 wire muda_ai_pfv;
	 
	 //registrar o valor recebido pelo modulo de controle do DHT11
	 reg [39:0] dadinhos_dht;
	 
	 //procedimento para registrar os dados recebidos pelo DHT11
	 always @(posedge readout_done)begin
		dadinhos_dht <= data_dht11;
	 end
	 
	 
	 //registrador para o temporizador de tempo do reset. Deixar ele ativo um tempo
    reg active_timer_reset = 1'b0; //ativador do temporizador
	 
	 //procedimento para manter o reset ativo por 0,5 segundos, e resetar a maquina especifica do sensor
    timer_pulso_reset reset_pulse_timer (clock, active_timer_reset, to_receiver); //temporizador de 0,5segundos
	 
	 //temporizador para garantir que foi possivel capturar os dados recebidos pelo sensor
	 timer_pulso_mudar_estado muda_state(clock, active_timer, muda_ai_pfv);
	 
    //chamada do modulo especifico do sensor
    DHT11_Made_in_china dht11_sensor(clock, enable_sensor, rst_sensor, dht_data, data_dht11, error_sensor, readout_done);

    //fios para depois separar qual informação vao ser melhor
    wire [7:0] umidade_int, temperature_int;
	
	
	//initial enable_sensor = 1'b0;
	//initial led = 1'b0;
	//reg [2:0] request = 2'b01;	

	

	 
    //PARTE ADAPTADA PARA O DHT11 NOVO(Made in China)
    always @(posedge clock)
        begin
            case(choose_case)
                s_idle: //estado de espera
                    begin
                        //testar comentar esse "INFO_FINESHED = 1'B0" ou então colocar essa informação dentro do if do request
                        
								
                        if(request == 2'b00 || request == 2'b01 || request == 2'b10) //verifica se o request esta correto
                            begin
											info_fineshed = 1'b0; //informar que ainda não foi completada a leitura do DHT11
                                active_timer_reset <=1'b1; //ativa o temporizador por conta do reset
                                enable_sensor = 1'b1; // Ativa o sensor para captar as informações do mesmo
                                rst_sensor <= 1'b1; // Sinal de reset para apagar os dados em buffer, e começar a leitura
                                //espera dar um tempo para o reset ter feito efeito no modulo do dht11, e entao muda de estado
										  
										  
										  
                                if(to_receiver == 1'b1) 
                                    begin
													
                                        rst_sensor <=1'b0; //o sinal de reset tem ser apenas 1 pulso tipo butao, logo ja desativa ele
                                        choose_case <= s_receiver_data; //vai para o estado de receber e tratar as informações do DHT11
                                    end
                                else
                                    begin
													
                                        choose_case <= s_idle;
                                    end
                                
                            end
                        else //enquanto nao é enviado um sinal de request valido, mantem os valores desativados
                            begin
                                enable_sensor = 1'b0;
                                rst_sensor <= 1'b0;
										  information <= 8'd0;
										  //ESTA SO MANTENDO O VALOR DO QUE JA RECEBEU
										  info_fineshed = 1'b1; //informar que ainda não foi completada a leitura do DHT11
										  //led = 1'b1;
                                //active_timer_reset <=1'b0;
                                choose_case <= s_idle;
                            end
                    end   
                s_receiver_data: //estado de receber os dados do DHT11 e realizar o tratamento desses dados para enviar a maquina principal
                    begin
                        active_timer_reset <=1'b0; //desativar o temporizador do sinal de reset
								active_timer <=1'b1; //ativa o temporizador de mudança de estado
                        rst_sensor <=1'b0; //o sinal de reset tem ser apenas 1 pulso tipo butao, logo ja desativa ele
								//led = 1'b0;
                        if(muda_ai_pfv == 1'b1) //quando o temporizador terminar a contagem e informar que passou do tempo
                            begin
										  active_timer <=1'b0;

                                //request de umidade
                                //coloca nos locais certos a informação que chegou do sensor
                                if(request == 2'b00) 
                                    begin
                                        //separa os bits que o sensor mandou, e que contem o inteiro de umidade
                                        information[0] <= dadinhos_dht[0];
                                        information[1] <= dadinhos_dht[1];
                                        information[2] <= dadinhos_dht[2];
                                        information[3] <= dadinhos_dht[3];
                                        information[4] <= dadinhos_dht[4];
                                        information[5] <= dadinhos_dht[5];
                                        information[6] <= dadinhos_dht[6];
                                        information[7] <= dadinhos_dht[7];

                                        //sinaliza que a informação foi completamente lida, e na maquina principal pode continuar o fluxo
                                        info_fineshed = 1'b1;
													 //request = 2'b11;
                                        choose_case <= s_idle;
                                    end


                                else if(request <= 2'b01) //request de temperatura
                                    begin
                                        //separa os bits que o sensor mandou, e que contem o inteiro de temperatura 
                                        information[0] <= dadinhos_dht[16];
                                        information[1] <= dadinhos_dht[17];
                                        information[2] <= dadinhos_dht[18];
                                        information[3] <= dadinhos_dht[19];
                                        information[4] <= dadinhos_dht[20];
                                        information[5] <= dadinhos_dht[21];
                                        information[6] <= dadinhos_dht[22];
                                        information[7] <= dadinhos_dht[23];
													 //request = 2'b11;
                                        //sinaliza que a informação foi completamente lida, e na maquina principal pode continuar o fluxo
                                        info_fineshed = 1'b1;
                                        choose_case <= s_idle;
                                    end


                                else if(request <= 2'b10) //request de situação de leitura do sensor
                                    begin
													//request <= 2'b11;
												
                                        //verifica se o modulo especifico de trabalho do sensor informou que o sensor esta com problema
                                        if(error_sensor == 1'b0) //sem error, sensor normal
                                            begin
                                                information <= 8'b00000000;

                                                //sinaliza que a informação foi completamente lida, e na maquina principal pode continuar o fluxo
                                                info_fineshed = 1'b1; 
                                                choose_case <= s_idle;
                                            end
                                        else //sensor com problema
                                            begin 
                                                information <= 8'b11111111;

                                                //sinaliza que a informação foi completamente lida, e na maquina principal pode continuar o fluxo
                                                info_fineshed = 1'b1;
                                                choose_case <= s_idle;
                                            end
                                    end


                                else
                                    begin
                                        
                                        choose_case <=s_idle;
                                    end
                            end
                        else //enquanto ainda nao terminou a contagem
                            begin
                                choose_case <= s_receiver_data;
                            end
                    end

                default: 
                    choose_case <= s_idle;
                endcase
        end


endmodule


//deixar o reset o tempo aceso necessario, antes de mudar de estado e desativa-lo
module timer_pulso_reset (clock, activate, next_state);
    input clock; //entrada de clock 50MHz
	input activate; //entrada de ativação, para iniciar a contagem
    output reg next_state; //saida indicando que ja passou o tempo, e pode passar ao prox estado

    reg [26:0] counter = 27'd0; //registrador de contador

    always @(posedge clock)
        begin
            if(activate == 1'b1) //se tiver sinal pedindo para contagem
                begin 
                    if(counter == 27'd25000000) //contador que vai ate 0,5 segundos
                        begin
									//counter <= 27'd0;
                            next_state = 1'b1; //envia o sinal que pode passar para o prox estado
                        end
                    else //enquanto o contador nao terminar, continua contando, e impedindo de pasasar ao prox estado
                        begin
                            next_state =1'b0;
                            counter = counter + 1'b1;
                        end
                end
            else //enquanto nao houver sinal de ativação, permanece esse sinal desativado
                begin
                    next_state =1'b0;
						  counter <= 27'd0;
                end
        end

endmodule 

/*
module timer_pulso_mudar_estado (clock, activate, next_state);
    input clock; //entrada de clock 50MHz
	input activate; //entrada de ativação, para iniciar a contagem
    output reg next_state; //saida indicando que ja passou o tempo, e pode passar ao prox estado

    reg [30:0] counter = 30'd0; //registrador de contador

    always @(posedge clock)
        begin
            if(activate == 1'b1) //se tiver sinal pedindo para contagem
                begin 
                    if(counter == 30'd200000000) //contador que vai ate 2 segundos
                        begin
									//counter <= 27'd0;
                            next_state = 1'b1; //envia o sinal que pode passar para o prox estado
                        end
                    else //enquanto o contador nao terminar, continua contando, e impedindo de pasasar ao prox estado
                        begin
                            next_state =1'b0;
                            counter = counter + 1'b1;
                        end
                end
            else //enquanto nao houver sinal de ativação, permanece esse sinal desativado
                begin
                    next_state =1'b0;
						  counter <= 30'd0;
                end
        end

endmodule 

*/
