<div align="center">
<h2> 🖥️ Sensor Digital em FPGA utilizando Comunicação Serial</h2>
<div align="center">

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/LICENSE)

</div>
<div align= "center" >
<img width="800px" src="https://github.com/nailasuely/IOInterfacesProblem1/assets/98486996/6a542e6c-98a3-4993-bd41-25fce210f04f">




<div align="center"> 

</div>

> Esse é um projeto da disciplina TEC 499 - Módulo Integrador Sistemas Digitais, no qual ocorre a criação de um projeto de um Sensor Digital em FPGA utilizando Comunicação Serial.



## Download do repositório


```
gh repo clone nailasuely/IOInterfacesProblem1
```
<div align="left">
	
## Sumário
- [Apresentação](#apresentação)
- [Requisitos](#requisitos)
- [Implementação](#implementação)
  - [Protocolo](#protocolo)
  - [UART Transmitter](#uart-transmitter)
  - [UART Receiver](#uart-receiver)
  - [DHT11](#dht11)
  - [Sensor 01](#sensor-01)
  - [Máquina de Estados Geral](#máquina-de-estados-geral)
  - [Contadores](#contadores)
  - [Selecionando Endereço e Requisição](#selecionando-endereço-e-requisição)
  - [Recebendo Dados do Sensor](#recebendo-dados-do-sensor)
  - [Desenvolvimento em C](#desenvolvimento-em-c)
- [Executando o Projeto](#executando-o-projeto)
- [Testes](#testes)
- [Uso de Pinos e LEs](#uso-de-pinos-e-les)
- [Conclusão](#conclusão) 
- [Tutor](#tutor)
- [Equipe](#equipe)
- [Referências](#referências)


![-----------------------------------------------------](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/rainbow.png)
## Apresentação
Nos últimos anos, temos observado um aumento notável na presença de objetos inteligentes que incorporam a capacidade de coletar dados, processá-los e estabelecer comunicação. Esse fenômeno está diretamente relacionado à ascensão da Internet das Coisas (IoT), um conceito que conecta esses objetos à rede global de computadores, possibilitando a interação entre usuários e dispositivos. A IoT abre as portas para uma variedade de aplicações inovadoras, que vão desde cidades inteligentes até soluções de saúde e automação de ambientes. [1]

Nossa equipe foi contratada para desenvolver um protótipo de sistema digital voltado para a gestão de ambientes por meio da IoT. O projeto será implementado de maneira incremental, e a primeira etapa abrange a criação de um protótipo que integra o sensor DHT11 que é  capaz de medir a temperatura e a umidade do ambiente. Este sistema será projetado com modularidade, possibilitando a realização de substituições e aprimoramentos em versões posteriores.

Esse protótipo é implementado utilizando a interface de comunicação serial (UART) que permite a recepção, interpretação, execução e resposta de comandos enviados.

![-----------------------------------------------------](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/rainbow.png)
 
## Requisitos
- A implementação do código deve ser realizada em linguagem C.
- Integração de Múltiplos Sensores
- A Iniciação da Comunicação deve acontecer por meio do computador, exceto quando o monitoramento contínuo for necessário.
- Deverá ser utilizada a interface de comunicação serial (UART)
- A comunicação entre o computador e a FPGA deve seguir um protocolo definido, incluindo comandos de requisição e respostas de 2 bytes, consistindo de comando e endereço do sensor.

![-----------------------------------------------------](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/rainbow.png)
 
## Implementação
 <div align="center">
        <img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/diagrama_geral.png" alt="Diagrama Geral">
	 <p>
      	Diagrama Geral
    </p>
    </div>



### Protocolo

- O Protocolo de Requisição é utilizado para o envio de comandos e solicitações específicas para a interface do sistema. Cada código listado na tabela abaixo representa um comando que pode ser enviado para FPGA, permitindo o controle e obtenção de informações.

 <div align="center">
	 
| Código                                                                            | Descrição do comando                                                                                                                                                                 |
| :------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  0x00        | Solicita a situação atual do sensor     |
| 0x01                | Sensor funcionando normalmente                                                                                                                                                 |
| 0x02           | Solicita a medida de umidade atual                                                                                    |
| 0x03                  | Ativa sensoriamento contínuo de temperatura                                                                                                        |
| 0x04                  | Ativa sensoriamento contínuo de umidade                                                                                                                                                  |
| 0x05 | Desativa sensoriamento contínuo de temperatura                                                                                                                             |
| 0x06              | Desativa sensoriamento contínuo de umidade                                                                          
<p>
      	Protocolo de Requisição
    </p>
</div>

- O Protocolo de Resposta descreve as respostas que o dispositivo fornece em resposta aos comandos enviados pelo protocolo de requisição. Cada código na tabela abaixo representa uma resposta correspondente ao comando enviado, auxiliando na interpretação das informações retornadas pelo sistema.

<div align="center">
	
| Código                                                                            | Descrição do comando                                                                                                                                                               |
| :------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0x1F             | Sensor com problema                                                                                                                             |
| 0x07             | Sensor funcionando normalmente 
| 0x08             | Medida de umidade       |
| 0x09             | Medida de temperatura     |
| 0x0A             | Confirmação de desativação de sensoriamento contínuo de temperatura      |
| 0x0B             | Confirmação de desativação de sensoriamento contínuo de umidade     |
| 0xF0             | Medida de temperatura continua     |
| 0xFE             |Medida de umidade continua    |
|0xFC              | Byte secundario para complementar o byte primario     |
|0xFB              | Comando inválido      |

<p>
      Protocolo de Resposta
    </p>
</div>

### UART Transmitter
- Clk (Clock): Esta é uma entrada que representa o sinal de clock do sistema.

- Initial_data (Dados Iniciais): Esta entrada é um sinal de controle que indica a presença de dados a serem transmitidos. Quando "initial_data" é igual a 1, isso significa que há dados a serem transmitidos e inicia o processo de transmissão.

- Data_transmission (Dados a Serem Transmitidos): Esta é uma entrada de 8 bits que contém os dados que serão transmitidos. Os bits presentes em "data_transmission" representam o byte de dados a ser serializado e transmitido através da porta UART.

- Out_tx (Saída de Transmissão): Esta saída representa o sinal serial UART que é transmitido para a comunicação com outros dispositivos. Durante a transmissão, o valor de "out_tx" é controlado para enviar os bits de dados corretamente, bem como os bits de start e stop, seguindo o protocolo UART.

- Done (Concluído): Esta é uma saída que sinaliza o término da transmissão..

Este módulo é projetado para realizar a transmissão assíncrona de dados serializados, que segue o protocolo da UART.

O estado de ociosidade (idle) é feito o monitoramento de sincronização ou seja existe uma entrada “initial_data” que se em nível lógico alto, indica a presença de dados para transmissão. O módulo carrega os dados no registrador e se prepara para fazer a transmissão de dados,a saída tx permanece em nível lógico alto nesse estado e o “done” utilizado para indicar que houve o término da transmissão de dados também permanece em nível baixo.

Neste estado de início (start) é a saída é colocada em nível baixo para indicar o inicio do quadro de dados.Ao mesmo tempo, o contador “counter” é iniciado para sincronizar o tempo do clock, isso garante que o bit de start tenha duração correta. O sinal “done” permanece em 0 para indicar que a transmissão está em andamento.

O estado de data, os bits de dados são transmitidos um por um. O sinal de saída tx assume o valor do bit atual do registrador utilizado baseado no índice. O contador “counter” é usado para controlar a taxa de transmissão, garantindo que os bits sejam transmitidos no tempo correto. À medida que cada bit transmitido, ele é armazenado em um registrador, sincronizado com o clock. O indice “bit_index” é atualizado para o próximo bit após a transmissão bem-sucedida. O sinal de “done” é deixado em 0 durante a transmissão de dados.

No estado de parada(stop), gera o bit de stop indicando o término da transmissão. O sinal de saída tx é colocado em nível alto para indicar o fim do quadro de dados. O mesmo contador utilizado anteriormente serve para garantir que o bit de stop tenha duração correta, e após a conclusão do bit de stop, a saída “done” é posta em nível alto identificando que a transmissão foi concluída.   

	
### UART Receiver
- Clk: Esta é a entrada do clock do sistema, que normalmente é fornecida por um oscilador ou uma fonte de clock externa. O sinal de clock é usado para sincronizar todas as operações dentro do módulo.
- Input_rx: Esta entrada recebe os dados seriais assíncronos da porta serial de comunicação. Os dados normalmente chegam como uma sequência de pulsos elétricos representando bits individuais.
- Done: Esta saída é um sinal que indica quando um dado foi recebido completamente e está pronto para ser lido. Quando este sinal está ativo (alto), significa que os bits de dados foram capturados e formaram um byte completo.
- Out_rx: Esta saída representa os dados recebidos em formato paralelo. É uma palavra de 8 bits que contém os dados recebidos após a conversão da comunicação serial assíncrona. Cada vez que um byte de dados é recebido completamente, ele é disponibilizado nesta saída.

Agora, vamos explicar o papel de cada uma dessas entradas e saídas:

A entrada clk é fundamental para sincronizar todas as operações dentro do módulo. Ele garante que os dados sejam capturados no momento correto e que a máquina de estados funcione em conformidade com a taxa de baud configurada.

A entrada input_rx é onde os dados seriais externos são inseridos no módulo. O módulo monitora essa entrada para detectar o início e o fim da comunicação e para receber os bits de dados serializados.

A saída done é um indicador importante para o sistema hospedeiro. Quando está ativa, ela informa que um dado foi recebido completamente e está disponível para ser processado. Isso é essencial para garantir que o sistema saiba quando os dados podem ser lidos com segurança.

A saída out_rx é onde os dados recebidos são disponibilizados em formato paralelo. Cada byte de dados recebido é colocado nesta saída para que o sistema hospedeiro possa acessá-lo facilmente em sua forma de 8 bits.

A função deste módulo está em receber dados seriais assíncronos, que irão ser controlados pelo clock utilizado, nesse caso 50 mhz, e convertê-los em dados que possam ser utilizados pelo restante do sistema. Essa função é realizada por meio de uma máquina de estados finitos implementada para fazer a sincronização de em quais situações as funcionalidades vão ser necessárias.
O primeiro estado a ser citado, é o estado de espera (idle) vai utilizar um receptor que aguarda o início da comunicação, monitorando continuamente, e quando ocorre a detecção de um sinal válido é feita a troca de estados para o de início (start).
Após detectar o sinal de início, o estado de início (start)  estado sincroniza seu contador de baud rate  com o início do bit de dados e monitora a transição do sinal serial para determinar quando deve começar a leitura dos dados.
No estado data, o receptor recebe um sinal de dados serializados e os converte em uma palavra de 8 bits paralelamente. Os bits de dados são armazenados em um registrador à medida que são recebidos e sincronizados com o clock utilizado.
	Após a recepção dos dados, o sistema transiciona para o estado de stop, que utiliza um contador para determinar quando a recepção de dados terminou. Desta maneira ocorre a transição de volta para o estado de espera (idle)

### DHT11

O módulo DHT11 possui as seguintes entradas e saídas:

- Clock: Uma entrada de sinal de clock de 1MHz.
- Start: Uma entrada que aciona a aquisição de dados no sensor DHT11 quando ocorre uma borda de subida.
- Rst_n: Uma entrada de reset ativo em nível baixo.
- Dat_io: Uma porta bidirecional para comunicação de dados.
- Data: Uma saída que representa os 40 bits de dados lidos do sensor DHT11.
- Error: Uma saída que indica se os dados recebidos do sensor contêm erros (1 em caso de erro, 0 caso contrário).
- Done: Uma saída que sinaliza quando a aquisição de dados foi concluída (1 quando completa, 0 caso contrário).
  
O módulo opera como uma máquina de estados finitos para controlar a comunicação com o sensor DHT11 e a aquisição de dados. Ele segue uma sequência de estados (de s1 a s10) para gerenciar a temporização, a leitura de dados e a detecção de erros. Cada estado desempenha um papel específico no processo de aquisição de dados.

- s1 (Ocioso):É O Estado Inicial.Espera que o sinal start seja detectado para iniciar a aquisição de dados.Se start e din forem ambos altos, transita para o estado s2.Se start não for detectado, o módulo permanece nesse estado.

- s2 (Inicio):Aguarda um período de atraso de nível baixo após a detecção de start.Após um atraso suficiente (aproximadamente 19 ms), transita para o estado s3.Se o período de atraso não for alcançado, permanece nesse estado.

- s3 (Envia Alto):Aguarda um período de espera após o atraso de nível baixo para permitir que o sensor DHT11 libere o barramento de dados.Após o período de espera 20, transita para o estado s4.Se o período de espera não for alcançado, permanece nesse estado.

- s4 (Espera Baixa):Aguarda a resposta do sensor DHT11 no barramento de dados.Se din for detectado como baixo (indicando a resposta), transita para o estado s5.Se din permanecer alto por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s5 (Espera Alta):Aguarda a confirmação do sensor DHT11 de que está pronto para enviar dados.Se din for detectado como alto, transita para o estado s6.Se din permanecer baixo por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s6 (Finaliza Sincronização):Aguarda o início do sinal de dados do sensor DHT11.Se din for detectado como baixo, transita para o estado s7.Se din permanecer alto por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s7 (Prepara Leitura):Detecta o início de um bit de dados enviado pelo sensor DHT11.Se din for detectado como alto, transita para o estado s8.Se din permanecer baixo por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s8 (Começa Leitura):Detecta o nível do bit de dados, se din for detectado como baixo, incrementa o contador de bits e armazena o bit de dados no registrador data_buf. Após receber os 40 bits de dados, transita para o estado s9.Se din permanecer alto por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s9 (Colhe os Bits de Dados):Bloqueia os dados lidos e aguarda que o sensor DHT11 libere o barramento de dados.Transfere os dados do registrador data_buf para data.Se din for detectado como alto, transita para o estado s10.Se din permanecer baixo por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s10 (Final da leitura):Marca o final da leitura de dados.Reinicia o estado para s1 e aguarda o próximo ciclo de aquisição de dados.

  <div align="center">
	<img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/DHT11_n%20(1).png" alt="Sensor"">
	 <p>
      	Máquina de estados do DHT11.
    </p>
    </div>	



### Sensor 01
Este módulo opera em dois estados principais: s_idle (ocioso) e s_receiver_data (recebendo dados). O estado atual é determinado pelo registrador choose_case, que é atualizado em resposta a eventos e entradas.

A interação com o sensor DHT11 ocorre por meio da instância do módulo DHT11. Esse módulo específico é responsável por estabelecer a comunicação com o sensor, ler os dados fornecidos por ele e detectar qualquer erro de leitura.
O módulo faz uso de temporizadores para gerar atrasos temporais controlados. O temporizador timer_pulso_reset é ativado em resposta a um sinal de ativação e gera um atraso de aproximadamente 2 segundos antes de permitir a transição para o próximo estado. O temporizador timer_pulso_mudar_estado é usado de maneira semelhante, mas gera um atraso de cerca de 2 segundos em outro contexto.

A principal entrada deste módulo é request, que indica o tipo de informação desejada pelo sistema principal. Dependendo do valor de request, o módulo processa os dados recebidos do sensor DHT11 de maneira diferente.

Quando o sistema principal emite um pedido de dados, o módulo responde ativando o sensor, redefinindo-o para garantir que os dados anteriores sejam apagados e aguardando um tempo específico antes de passar para o próximo estado. Isso é feito para permitir que o sensor esteja pronto para fornecer dados atualizados.
Assim que os dados são lidos com sucesso do sensor DHT11, o módulo os processa de acordo com o tipo de informação solicitada. Ele separa os bits relevantes dos dados e os coloca nos locais apropriados no registrador information. Além disso, ele sinaliza que a leitura foi concluída definindo info_fineshed como 1.
Se o sensor DHT11 detectar algum erro durante a leitura, ele sinaliza isso por meio do sinal error_sensor. O módulo então define information de acordo para indicar a situação do sensor.

<div align="center">
	<img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/mef_sensor.png" alt="Sensor"width="720" height="533">
	 <p>
      	Diagrama de funcionamento para interface do sensor.
    </p>
    </div>	

### Máquina de Estados Geral
Um dos principais módulos do problema, a "general_MEF", tem função de controle geral do sistema, no que lhe confere a armazenar a informação recebida pela porta serial, realizar checagem desse protocolo, para analise se é correto ou um comando invalido, realizar chamada para ativar a máquina que faz interface para lidar com o sensor, a "Sensor_01_MEF", além disso ele faz o envio dos 2 bytes, 1 sendo o protocolo de resposta, e o outro o dado requisitado, ou um byte com informação nula, somente para preenchimento do segundo espaço. 
Para que possa funcionar, esta máquina de estados finitos, possui 6 estados, sendo eles: idle, check_code, invalid_code, reading, information, continuous. Para determinação do estado atual, é utilizado o registrador choose_case, em que vai guardando os códigos dos estados e permitindo o funcionamento. Segue uma explicação de cada estado:

- **Idle:**
Estado de espera, em que a máquina permanece ate receber um sinal indicando para iniciar. Nesse estado alguns registradores são setados com o valor padrão, como o info_sensor_made (indicar se a informação do segundo byte provém do sensor), continuous_mode(indicar se o modo contínuo está ativo), além de desativar os dißplays de led, junto aos ativadores dos contadores. 
- **Check_code:**
Estado em que verifica se o comando recebido está çorreto ao verificar a variável sentada por um decodificador, o code_verify. A depender do protocolo, ele pode ir para o estado de comando invalido, ou prosseguir para o estado de reading. Vale lembrar que nesse estado o display de 7 segmentos da esquerda acende para informar que chegou o comando. 
- **Invalid_code:**
Esse estado serve para enviar informação de que o comando recebido é invalido. Ele faz o envio do primeiro byte, que corresponde ao protocolo de resposta, e prossegue para o estado information para realizar o envio do segundo byte.
- **Reading:**
O maior estado da máquina de estados, e que é responsável por ativar a máquina de interface do sensor, para que os dados provindos dele sejam capturados. Esse estado realiza a verificação para analisar qual requisição está sendo feita, e assim poder mandar para o computador o protocolo correto, junto com a informação correta provinda do sensor, se for o caso. Além disso, ele faz a seleção para ver qual dos 32 possíveis sensores será ativado. Tanto para o endereço dos sensores, como para o protocolo de requisição, há verificação para se, um dos não estiver correto, irá para o estado de código inválido, o invalid_code. Ainda nesse estado é enviado o código do protocolo de resposta adequado a requisição, ativada a máquina que faz interface com o sensor, e por fim vai ao estado information, ou para o continuous_letter. O primeiro desses, serve  para envio do segundo byte  feito pelo sensor, mas com o continuous desabilitado, caso esteja habilitado, ele vai para o continuous_lstter realizar essa operação e volta para o estado information a fim de esperar o temporizador/contador atingir a contagem dele de 10 segundos, e retornar ao estado de reading, a fim de continuar a rotina do modo contínuo.
- **Information**
Esse estado tem como base o envio do segundo byte para o computador através da porta serial. Antes disso ocorrer, ele realiza algumas verificações para saber qual informação ele irá enviar,  como: se a informação do segundo byte é produzida pelo sensor ou não e  se o modo contínuo está ativo ou não. Em caso da informação não ser setada pelo sensor, é enviado um byte já pré-definido, e no caso do contínuo está ativo, esse estado é mantido, até o contador chegar ao alvo de contagem, que resulta no tempo de 10 segundos. Vale ressaltar que por conta dos outros temporizadores contidos no código, o modo contínuo tem atualizações a cada  20 segundos, aproximadamente. Para envio da informação, quando ela é referente ao sensor, há um temporizador de 4 segundos, que manda a informação após passado esse tempo, a fim de garantir que o sensor respondeu.
- **Continuous_letter**
Tal estado serve para envio do segundo byte, quando o modo contínuo está ativo. Logo ele permite que no estado de reading seja enviado o byte informando o protocolo de resposta, e ao chegar nesse estado enviar a informação do sensor. Nesse momento, também há um temporizador de 4 segundos, assim como no estado information. Seu próximo estado, é o information para que fique lá até o tempo de ser necessário enviar novamente a informação de modo contínuo.


<div align="center">
	<img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/mef_geral.png" alt="Sensor">
	 <p>
      	Síntese do uso de Pinos e LEs
    </p>
    </div>

### Contadores
O projeto contém alguns contadores, que exercem a função de temporizador, na medida que algumas funções esperam a contagem terminar para poder realizar outras, similar a função sleep() presente na linguagem C. Ressalta-se ainda que eles funcionam com um sinal de ativação, para iniciar a contagem somente quando necessário, assim como ao terminar a contagem enviam um sinal indicando isso. Excetua-se do sinal de ativação apenas o generate_clock1Mhz, já que este precisa estar o tempo todo ativo, por funcionar como um divisor de clock. Dentre eles, há:

- **Timer_pulso_reset:**
Este serve para deixar o sinal de reset enviado para o módulo DHT11_Made_in_china, ativo por um tempo para questão de sincronização, e captura desse sinal, para que esta máquina possa ser ativada, e começar receber os dados do sensor.
- **Timer_muda_state:**
Com o intuito de indicar a temporização para efetuar a mudança de estado, quando usado no módulo sensor_01_MEF, e quando no módulo general_MEF realiza a operação de esperar para poder enviar o segundo byte, garantindo que houve leitura e captura dos dados do sensor.
- **Timer_continuous:**
Tem a função de contagem até o valor de 500 mil, o que com clock de 50 MHz, gera um tempo de 10 segundos, o qual é o intervalo para atualizar o dado do modo contínuo. 
- **Gerador_clock_1MHz:** 
Pensando no funcionamento da máquina do DHT11, em que trabalha a 1 MHz, e em contrapartida a placa possui um clock base de 50MHz. Em resolução, foi criado este contador que vai até o valor 50, decimal, e ao atingir o valor emite um valor 1, e logo após o contador ir a 0, o valor emitido volta a 0, possibilitando obter um sinal de clock de 1 MHz como necessário. 

### Selecionando Endereço e Requisição

A seleção de endereço e armazenamento é essencial para o funcionamento do projeto, visto que sem esse armazenamento a primeira informação sempre seria perdida, já que seria sobrescrevida pela segunda informação. Para que esta etapa funcione, há uma estrutura always a qual atualiza com o pulso de clock da placa, um registrador utilizado como seletor, e por fim o sinal de rx_done, que informa quando a informação foi completamente recebida.
Usando um conjunto de if e else, tem-se no primeiro a verificação se a informação foi recebida, e o seletor está com o valor 0, nesse caso está tratando do protocolo de requisição, e entao salva essa informação no primeiro buffer, chamado protocol_01, e muda o valor do seletor para 1, ao fazer isso, quando receber a próxima informação, esta será salva no segundo buffer, que armazena o endereço do sensor, esse buffer chamado de protocol_02.

<div align="center">
	<img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/MAP003.png" alt="Informação gerada pelo sensor mostrada pelo osciloscópio."width="800" height="480">
	 <p>
      	Informação gerada pelo sensor e exibida pelo osciloscópio
    </p>
    </div>


### Recebendo Dados do Sensor

O recebimento de dados provenientes do sensor ocorre por meio do módulo DHT11_Made_in_china, o qual contém temporizadores para poder tanto mandar o pulso de ativação do sensor, que leva o tempo de aproximadamente 18ms a 20ms, tanto como receber os 40 bits que o sensor irá enviar e identificar qual tem o valor 0 ou 1, para compor a informação. Junto a este módulo há outro que faz interface, o sensor_01_MEF,  para que a comunicação entre a general_MEF e o DHT11_Made_in_china, ocorra sem maiores problemas, do formato da informação. Dessa forma a general_MEF envia um código de requisição para modulo sensor_01_MEF, este por sua vez envia o sinal para ativar o módulo DHT11_Made_in_china, após os dados recuperados do sensor, eles são enviados para o módulo sensor_01_MEF, e este seleciona dentre os 40 bits, apenas 8, escolhidos a depender da requisição, seja os 8 primeiros para …, ou o terceiro bloco de 8 bits para o …, ou no caso de pedida a situação do sensor, verifica-se o sinal de error enviado pelo DHT11_Made_in_china. Por fim, este byte é enviado para a general_MEF e enviado para o computador a informação.

### Desenvolvimento em C
Para possibilitar a funcionalidade contínua e manual do sistema, dois códigos em C foram utilizados de maneira separada: um para a leitura e outro para a escrita dos dados via UART.

- Write

O código descrito em C foi desenvolvido com o propósito de estabelecer comunicação entre um sistema Linux presente nos computadores do Laboratório de Eletrônica Digital e Sistemas(LEDS) e uma FPGA, permitindo a interação com um sensor por meio de transmissão UART. Utilizando a biblioteca "termios", ele configura a porta serial ("/dev/ttyS0") com uma taxa de baud de 9600 e parâmetros de comunicação adequados. O programa apresenta um menu interativo ao usuário, permitindo a escolha de diferentes comandos, como a obtenção da situação atual do sensor, medições de temperatura e umidade, além de ativar ou desativar o sensoriamento contínuo de temperatura ou umidade. Após a seleção do comando, o código envia o código correspondente para a FPGA via UART e aguarda alguns segundos para a resposta.

- Read

Esse código é o responsável para receber os dados. Quando dados são recebidos, o programa interpreta os primeiros bytes para determinar qual é o protocolo recebido e exibir para o usuário a medida de temperatura ou umidade. O código fornece uma interface para processar os dados recebidos da FPGA via UART, permitindo a leitura e interpretação das informações do sensor em tempo real. O programa opera em um loop contínuo, lendo e interpretando dados em determinado intervalo.


![-----------------------------------------------------](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/rainbow.png)

## Uso de Pinos e LEs
 <div align="center">
        <img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/statistics.png" alt="Síntese">
	 <p>
      	Síntese do uso de Pinos e LEs
    </p>
    </div>
    
![-----------------------------------------------------](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/rainbow.png)
 
## Executando o projeto
O projeto é compatível com o kit de desenvolvimento Mercurio IV, em conjunto com o sensor DHT11. O módulo do programa em C pode ser adaptado para o sistema operacional Windows, mas foi inicialmente desenvolvido para o ambiente Linux. Como resultado, existem funcionalidades projetadas especialmente para o Linux.

Para executar o protótipo, é necessário seguir alguns passos. Inicialmente, baixar os arquivos disponíveis neste repositório e baixar algum software que permita configurar e montar as entradas e saídas da placa Mercurio IV, a exemplo o Quartus. Além disso, é essencial contar com um computador para controlar o sensor que estará conectado à placa. Uma vez que todos os materiais estejam disponíveis, será necessário configurar as entradas e saídas da placa, como os pinos da comunicação serial e da comunicação com o sensor. Por fim, basta executar o código C no terminal e fazer as solicitações desejadas. 

![-----------------------------------------------------](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/rainbow.png)

## Testes

- **Teste de temperatura:** Foi pedido ao sistema que fornecesse a temperatura atual, e a resposta do sistema foi uma confirmação da solicitação, 0x09, acompanhada da temperatura atual.
  
 <div align="center">
	 <img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/Captura%20de%20tela%20de%202023-09-26%2015-29-08.png" alt="Síntese">
	 <p>
      	Teste para medida de temperatura.
    </p>
</div>

- **Teste de umidade:** Foi pedido ao sistema que fornecesse a umidade atual, e a resposta do sistema foi uma confirmação da solicitação, 0x08, acompanhada da temperatura atual.
<div align="center">
     <img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/Captura%20de%20tela%20de%202023-09-26%2015-30-35.png" alt="Síntese">
	 <p>
      	Teste para medida de umidade.
    </p>
</div>

- **Teste de sensoriamento de umidade contínua:** O exemplo ilustra o funcionamento do sensoriamento contínuo, onde o sistema responde com uma confirmação da solicitação, 0xFE, e a temperatura a cada intervalo de 20 segundos.

<div align="center">
    <img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/Captura%20de%20tela%20de%202023-09-26%2015-33-17.png" alt="Síntese">
	 <p>
      	Teste para sensoriamento de umidade contínua.
    </p>
</div>

- **Teste para desativar o sensoriamento contínuo:** O exemplo demonstra como o sistema reage quando o sensoriamento contínuo é desativado, fornecendo uma confirmação do desligamento do sensoriamento contínuo.
<div align="center">
    <img src="https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/Captura%20de%20tela%20de%202023-09-26%2015-31-54.png" alt="Síntese">
	 <p>
      	Teste para desativar sensoriamento contínuo. 
    </p>	 
</div>

![-----------------------------------------------------](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/rainbow.png)


## Conclusão 
O objetivo principal deste trabalho era compreender a integração entre FPGA e códigos em linguagem C para desenvolver um sistema computacional, ao mesmo tempo em que se aprofundaram os conhecimentos sobre comunicação serial. Com a conclusão do projeto é verdadeiro afirmar que esse objetivo foi plenamente alcançado, visto que o projeto conseguiu estabelecer uma comunicação eficaz entre o computador e a placa, atendendo a todos os requisitos estabelecidos. 

Em relação à execução do projeto, a maioria das ferramentas utilizadas já eram familiares aos discentes, incluindo o software Quartus e o osciloscópio. No entanto, nesse projeto, a novidade incluiu a utilização da placa Mercurio IV e o sensor DHT11. As principais dificuldades associadas ao projeto surgiram em decorrência do uso das placas, por conta da quantidade limitada, e a imperícia dos alunos com relação aos cuidados no uso do DHT11. Com exceção desses desafios, o projeto transcorreu sem intercorrências significativas.


![-----------------------------------------------------](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/img/rainbow.png)
 
## Tutor 
- Anfranserai Morais Dias

## Equipe 
- [Naila Suele](https://github.com/nailasuely)
- [Rhian Pablo](https://github.com/rhianpablo11)
- [João Gabriel Araujo](https://github.com/joaogabrielaraujo)
- [Amanda Lima](https://github.com/AmandaLimaB)



## Referências 

> - [1] Santos, B. P., Silva, L. A., Celes, C. S. F. S., Borges, J. B., Neto, B. S. P., Vieira, M. A. M., ... & Loureiro, A. (2016). Internet das coisas: da teoria à prática. Minicursos SBRC-Simpósio Brasileiro de Redes de Computadores e Sistemas Distribuıdos, 31, 16.
> - Tocci, R. J., Widmer, N. S., & Moss, G. L. (2010). Sistemas digitais. Pearson Educación.



</div>
