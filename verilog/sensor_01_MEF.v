//v2 do modulo do sensor do dht11

module sensor_01_MEF(clock, request, dht_data, information, info_fineshed);
    input clock; //entrada de clock
    input [1:0] request;    //entrada recebida pela maquina principal, sobre a requisição desejada
    inout dht_data; //entrada e saida dos dados recebidos pelo sensor
    output reg [7:0] information; //saida para a outra maquina de estados
    output reg info_fineshed; //saida para informar que ja terminou de mandar os dados


    localparam  s_idle = 2'b00, s_receiver_data = 2'b10; //definição dos estados da maquina
    //, s_error_sensor = 2'b10, s_send_data = 2'b11;

    reg [1:0] choose_case; //registrador para funcionamento do case



    wire [7:0] hum_int, temp_int;
    wire readout_done, wait_sensor, error_sensor;
    
    reg enable_sensor, rst_sensor;
    
    //Chamada antiga do DHT11 com o antigo codigo - ps o codigo funcionava, mas o seu problema era na Leitura
    //DHT11 dht11_comunication (clock, enable_sensor, rst_sensor, dht_data, hum_int, hum_float, temp_int, temp_float, check_sum, wait_sensor, debug_sensor, error_sensor, readout_done);

    //NOVO DHT11 - by china
    /*
    Seu funcionamento:
        recebe clock de 1MHZ
        precisa de um sinal de start
        precisa de um sinal de reset
        entrada e saida na mesma porta para a comunicação c o DHT11
        saida com os dados, os 40 bits totais
        saida de erro - se for 1 = erro, se for 0 = sem erro
            ESTA SAIDA ABAIXO É IMPORTANTE PARA O CONTROLE DAS MAQUINAS DE ESTADOS
            COM ELE TEM O CONTROLE PARA NAO MUDAR DE ESTADO ENQUANTO AINDA NAO RECEBEU
            O DADO DO DHT11
        saida para afirmar que terminou de receber o dado, ou seja um "done" 
    
        ele pega o sinal de clock, precisa do start para iniciar e de um reset
        logo, passar um sinal de reset, e depois um sinal de start
            ps: possa ser q essa ordem precise alterar
        depois de um tempo, pode pegar os dados e salvar 
        ele entrega todos os 40 bits juntos, precisa separar
        ele ja faz o check sum p informar se teve erro ou nao
    
    */
/* CODIGO ABAIXO PARA O FUNCIONAMENTO DO DHT11 ANTIGO, ADAPTAÇÕES PARA O NOVO
DHT11_Made_in_china ESTARÃO MAIS ABAIXO
    always @(posedge clock)
    begin
        case(choose_case)
            s_idle:
                begin
                    if(request == 2'b00 || resquest == 2'b01 || request == 2'b10)
                        begin
                            en_dht11 <= 1'b1; // Ativa o sensor
						    r_Rst <= 1'b1; // Dar-se um sinal de rst para iniciar a obtenção de dados
                            choose_case <= s_receiver_data;
                        end
                    else
                        begin
                            //possa ser que precise informar que o request chegou errado
                            choose_case <= s_idle;
                        end
                end   
            s_receiver_data:
                rst_sensor <=1'b0;
                begin
                    if(readout_done == 1'b1)
                        begin
                        if(request == 2'b00)
                            begin
                                information <=hum_int;
                            end
                        if(request <= 2'b01)
                            begin
                                information <= temp_int;
                            end
                        if(request <= 2'b10)
                            begin
                                if(error_sensor == 1'b0) //sem error, sensor normal
                                    begin
                                        information <= 8'b00000000;
                                    end
                                else //sensor com problema
                                    begin 
                                        information <= 8'b11111111;
                                    end
                            end
                        end
                        else
                            begin
                                choose_case <=s_reading;
                            end
                end
            s_error_sensor:
                begin
                
                end
            s_send_data:
                begin
                
                end
            default: 
                choose_case <= s_idle;
    end
*/
    wire to_receiver; //fio para receber o dado do temporizador, para assim nao passar de estado antes da hora
    wire [39:0] data_dht11; //fio para receber os dados provenientes do sensor
    reg active_timer_reset = 1'b0; //ativador do temporizador
    timer_pulso_reset reset_pulse_timer (clock, active_timer_reset, to_receiver); //temporizador de 2,67segundos
    //chamada do modulo especifico do sensor
    DHT11_Made_in_china dht11_sensor(clock, enable_sensor, rst_sensor, dht_data, data_dht11, error_sensor, readout_done);

    //fios para depois separar qual informação vao ser melhor
    wire [7:0] umidade_int, temperature_int;

    
    
    //PARTE ADAPTADA PARA O DHT11 NOVO(Made in China)
    always @(posedge clock)
        begin
            case(choose_case)
                s_idle: //estado de espera
                    begin
                        //testar comentar esse "INFO_FINESHED = 1'B0" ou então colocar essa informação dentro do if do request
                        info_fineshed = 1'b0; //informar que ainda não foi completada a leitura do DHT11
                        if(request == 2'b00 || request == 2'b01 || request == 2'b10) //verifica se o request esta correto
                            begin
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
                                active_timer_reset <=1'b0;
                                choose_case <= s_idle;
                            end
                    end   
                s_receiver_data: //estado de receber os dados do DHT11 e realizar o tratamento desses dados para enviar a maquina principal
                    begin
                        active_timer_reset <=1'b0; //desativar o temporizador do sinal de reset
                        rst_sensor <=1'b0; //o sinal de reset tem ser apenas 1 pulso tipo butao, logo ja desativa ele
                        if(readout_done == 1'b1) //quando o sensor informar que foi terminada a leitura dos dados
                            begin
                                //request de umidade
                                //coloca nos locais certos a informação que chegou do sensor
                                if(request == 2'b00) 
                                    begin
                                        //separa os bits que o sensor mandou, e que contem o inteiro de humidade
                                        information[7] <= data_dht11[0];
                                        information[6] <= data_dht11[1];
                                        information[5] <= data_dht11[2];
                                        information[4] <= data_dht11[3];
                                        information[3] <= data_dht11[4];
                                        information[2] <= data_dht11[5];
                                        information[1] <= data_dht11[6];
                                        information[0] <= data_dht11[7];

                                        //sinaliza que a informação foi completamente lida, e na maquina principal pode continuar o fluxo
                                        info_fineshed = 1'b1;
                                        choose_case <= s_idle;
                                    end


                                else if(request <= 2'b01) //request de temperatura
                                    begin
                                        //separa os bits que o sensor mandou, e que contem o inteiro de temperatura 
                                        information[7] <= data_dht11[16];
                                        information[6] <= data_dht11[17];
                                        information[5] <= data_dht11[18];
                                        information[4] <= data_dht11[19];
                                        information[3] <= data_dht11[20];
                                        information[2] <= data_dht11[21];
                                        information[1] <= data_dht11[22];
                                        information[0] <= data_dht11[23];

                                        //sinaliza que a informação foi completamente lida, e na maquina principal pode continuar o fluxo
                                        info_fineshed = 1'b1;
                                        choose_case <= s_idle;
                                    end


                                else if(request <= 2'b10) //request de situação de leitura do sensor
                                    begin
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
                        else
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
                    if(counter == 27'b101111101011110000100000000) //contador que vai ate 2 segundos
                        begin
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
                end
        end

endmodule 