

module DHT11_Made_in_china(
	input wire       	clock			,  //1MHz clock
	input wire 		  	start     ,//Aquisição de gatilho de borda ascendente
	input wire	     	rst_n		,
	inout	          	dat_io		,
	output  reg [39:0]	data     ,
	output  			error					,//É 1 quando o grau dos dados está errado.
	output  			done//Atualizações de dados após concluir uma conversão
	//output [39:0]dado
);


	//wire [39:0] dado;
	//assign dado = data;
	
	wire din, clk;//ler dados
	reg read_flag;
	reg dout;
	reg[3:0] state;
	localparam s1 = 0;
	localparam s2 = 1;
	localparam s3 = 2;
	localparam s4 = 3;
	localparam s5 = 4;
	localparam s6 = 5;
	localparam s7 = 6;
	localparam s8 = 7;
	localparam s9 = 8;
	localparam s10 = 9;
	
	generate_clock_1MHZ clock_1MHz (clock, clk);

	//COLOCAR LEVEL TO PULSE O RESET
	
	
	
	assign dat_io = read_flag ? 1'bz : dout;
	assign din = dat_io;
	assign done = (state == s10)?1'b1:1'b0;
	assign error = (data[7:0] == data[15:8] + data[23:16] + data[31:24] + data[39:32])?1'b0:1'b1;
	reg [5:0]data_cnt;
	reg start_f1,start_f2,start_rising;
	always@(posedge clk, negedge rst_n)
	begin
		if(!rst_n)begin
			start_f1 <=1'b0;
			start_f2 <= 1'b0;
			start_rising<= 1'b0;
		end
		else begin
			start_f1 <= start;
			start_f2 <= start_f1;
			start_rising <= start_f1 & (~start_f2);
		end
	end
	reg [39:0] data_buf;
	reg [15:0]cnt ;
	always@(posedge clk, negedge rst_n)
	begin
		if(rst_n == 1'b0)begin
			read_flag <= 1'b1;
			state <= s1;
			dout <= 1'b1;
			data_buf <= 40'd0;
			cnt <= 16'd0;
			data_cnt <= 6'd0;
			data<=40'd0;
		end
		else begin
			case(state)
				s1:begin//Quando o barramento de dados está ocioso, a coleta é iniciada quando a coleta de dados é recebida.
						if(start_rising && din==1'b1)begin
							state <= s2;
							read_flag <= 1'b0;//Anfitrião pega ônibus
							dout <= 1'b0;//Puxar para baixo
							cnt <= 16'd0;
							data_cnt <= 6'd0;
						end
						else begin
							read_flag <= 1'b1;
							dout<=1'b1;
							cnt<=16'd0;
						end	
					end
				s2:begin//O host emite um atraso de baixo nível de 19 ms e, após o término, o host envia um atraso de alto nível
						if(cnt >= 16'd19000)begin
							state <= s3;
							dout <= 1'b1;
							cnt <= 16'd0;
						end
						else begin
							cnt<= cnt + 1'b1;
						end
					end
				s3:begin//O host atrasa de 20 a 40us, libera o barramento de dados após o término e está pronto para ler os dados.
						if(cnt>=16'd20)begin
							cnt<=16'd0;
							read_flag <= 1'b1;
							state <= s4;
						end
						else begin
							cnt <= cnt + 1'b1;
						end
					end
				s4:begin//Aguarde a resposta do escravo
						if(din == 1'b0)begin//Resposta do escravo
							state<= s5;
							cnt <= 16'd0;
						end
						else begin
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin//Auto-recuperação de tempo limite
								state <= s1;
								cnt<=16'd0;
								read_flag <= 1'b1;
							end	
						end
					end
				s5:begin//Verifique se a máquina escrava responde
						if(din==1'b1)begin
							state <= s6;
							cnt<=16'd0;
							data_cnt <= 6'd0;
						end
						else begin
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin//Auto-recuperação de tempo limite
								state <= s1;
								cnt<=16'd0;
								read_flag <= 1'b1;
							end								
						end
					end
				s6:begin//Aguarde o ponto de sinal inicial dos primeiros dados
						if(din == 1'b0)begin//O bit de dados começa a receber
							state <= s7;
							cnt <= cnt + 1'b1;
						end
						else begin
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin//Auto-recuperação de tempo limite
								state <= s1;
								cnt<=16'd0;
								read_flag <= 1'b1;
							end							
						end
					end
				s7:begin//
						if(din == 1'b1)begin//Determine o ponto de partida de alto nível dos dados
							state <= s8;
							cnt <= 16'd0;
						end
						else begin
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin//Auto-recuperação de tempo limite
								state <= s1;
								cnt<=16'd0;
								read_flag <= 1'b1;
							end							
						end
					end
				s8:begin//Detecte o tempo de alto nível e determine se os dados são 0 1
						if(din == 1'b0)begin
							data_cnt <= data_cnt + 1'b1;
							state <= (data_cnt >= 6'd39)?s9:s7;//Após receber os dados de 40 bits, insira s9, caso contrário, insira s7 para continuar recebendo o próximo bit.
							cnt<=16'd0;
							if(cnt >= 16'd60)begin
								data_buf<={data_buf[39:0],1'b1};
							end
							else begin
								data_buf<={data_buf[39:0],1'b0};
							end
						end
						else begin
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin//Tempo limite de auto-recuperação
								state <= s1;
								cnt<=16'd0;
								read_flag <= 1'b1;
							end	
						end
					end
				s9:begin//Trave os dados e espere o escravo liberar o barramento
						//data <= (data_buf[7:0] == (data_buf[15:8] + data_buf[23:16] + data_buf[31:24] + data_buf[39:32]))?data_buf : data;
						data <= data_buf;
						if(din == 1'b1)begin
							state <= s10;
							cnt<=16'd0;
						end
						else begin
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin//Auto-recuperação de tempo limite
								state <= s1;
								cnt<=16'd0;
								read_flag <= 1'b1;
							end	
						end
					end
				s10:begin//Uma batida vazia gera um sinal para completar uma leitura de dados.
						state <= s1;
						cnt <= 16'd0;
					end
				default:begin
						state <= s1;
						cnt <= 16'd0;
					end	
			endcase
		end		
	end
	
endmodule



/*
A intensão desse modulo é basicamente gerar um clock de 1mhz para funcionamento
da maquina de controle do sensor do dht11
posteriormente colocar esse modulo dentro do proprio modulo do dht11
    objetivo: simplificar o codigo modularizado
*/
module generate_clock_1MHZ(clock, clk);
    input clock;
    output reg clk;

    reg [5:0] counter = 6'd0;

    always @(posedge clock)
        begin
            if(counter == 6'd50)
                begin
							counter = 6'd0;
                    clk <= 1'b1;
                end
            else
                begin
                    clk <= 1'b0;
                    counter = counter + 1'b1;
                end
        end

endmodule 