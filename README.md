<div align="center">
<h2> 🖥️ Sensor Digital em FPGA utilizando Comunicação Serial</h2>
<div align="center">

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/nailasuely/IOInterfacesProblem1/blob/master/LICENSE)

</div>
<div align= "center" >
<img width="800px" src="https://github.com/nailasuely/IOInterfacesProblem1/assets/98486996/6a542e6c-98a3-4993-bd41-25fce210f04f">




<div align="center"> 

</div>

> Este projeto não é profissional e tem como objetivo armazenar o conteúdo da disciplina Módulo Integrador Sistemas Digitais.



## Download do repositório


```
gh repo clone nailasuely/IOInterfacesProblem1
```
<div align="left">
  
## Apresentação
Nos últimos anos, temos observado um aumento notável na presença de objetos inteligentes que incorporam a capacidade de coletar dados, processá-los e estabelecer comunicação. Esse fenômeno está diretamente relacionado à ascensão da Internet das Coisas (IoT), um conceito que conecta esses objetos à rede global de computadores, possibilitando a interação entre usuários e dispositivos. A IoT abre as portas para uma variedade de aplicações inovadoras, que vão desde cidades inteligentes até soluções de saúde e automação de ambientes. [1]

Nossa equipe foi contratada para desenvolver um protótipo de sistema digital voltado para a gestão de ambientes por meio da IoT. O projeto será implementado de maneira incremental, e a primeira etapa abrange a criação de um protótipo que integra o sensor DHT11 que é  capaz de medir a temperatura e a umidade do ambiente. Este sistema será projetado com modularidade, possibilitando a realização de substituições e aprimoramentos em versões posteriores.

Esse protótipo é implementado utilizando a interface de comunicação serial (UART) que permite a recepção, interpretação, execução e resposta de comandos enviados.

## Requisitos
- A implementação do código deve ser realizada em linguagem C.
- Integração de Múltiplos Sensores
- A Iniciação da Comunicação deve acontecer por meio do computador, exceto quando o monitoramento contínuo for necessário.
- Deverá ser utilizada a interface de comunicação serial (UART)
- A comunicação entre o computador e a FPGA deve seguir um protocolo definido, incluindo comandos de requisição e respostas de 2 bytes, consistindo de comando e endereço do sensor.



## Sumário
- [Apresentação](#apresentação)
- [Requisitos](#requisitos)
- [Implementação](#implementação)
  - [Protocolo](#protocolo)
  - [UART Transmitter](#uart-transmitter)
  - [UART Receiver](#uart-receiver)
  - [DHT11](#dht11)
  - [Sensor 01](#sensor-01)
  - [Máquina Geral](#máquina-geral)
  - [Contadores](#contadores)
  - [Desenvolvimento em C](#desenvolvimento-em-c)
- [Testes](#testes)
- [Uso de Pinos e LEs](#uso-de-pinos-e-les)
- [Conclusão](#conclusão) 
- [Tutor](#tutor)
- [Equipe](#equipe)
- [Referências](#referências)




## Implementação



### Protocolo
| Código                                                                            | Descrição do comando                                                                                                                                                                 |
| :------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  0x00        | Solicita a situação atual do sensor     |
| 0x01                | Sensor funcionando normalmente                                                                                                                                                 |
| 0x02           | Solicita a medida de umidade atual                                                                                    |
| 0x03                  | Ativa sensoriamento contínuo de temperatura                                                                                                        |
| 0x04                  | Ativa sensoriamento contínuo de umidade                                                                                                                                                  |
| 0x05 | Desativa sensoriamento contínuo de temperatura                                                                                                                             |
| 0x06              | Desativa sensoriamento contínuo de umidade                                                                                                              |


| Código                                                                            | Descrição do comando                                                                                                                                                               |
| :------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0x1F | Sensor com problema                                                                                                                             |
| 0x07             | Sensor funcionando normalmente 
| 0x08        | Medida de umidade       |
| 0x09        | Medida de temperatura     |
| 0x0A        | Confirmação de desativação de sensoriamento contínuo de temperatura      |
| 0x0B        | Confirmação de desativação de sensoriamento contínuo de umidade     |
| 0xF0        | Medida de temperatura continua     |
| 0xFE         |Medida de umidade continua    |
|0xFC        | Byte secundario para complementar o byte primario     |
|0xFB        | Comando inválido      |
                     


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

- s1 (Idle - Ocioso):É O Estado Inicial.Espera que o sinal start seja detectado para iniciar a aquisição de dados.Se start e din forem ambos altos, transita para o estado s2.Se start não for detectado, o módulo permanece nesse estado.

- s2 (Atraso Baixo):Aguarda um período de atraso de nível baixo após a detecção de start.Após um atraso suficiente (aproximadamente 19 ms), transita para o estado s3.Se o período de atraso não for alcançado, permanece nesse estado.

- s3 (Espera Barramento de Dados):Aguarda um período de espera após o atraso de nível baixo para permitir que o sensor DHT11 libere o barramento de dados.Após o período de espera 20 a 40 µs, transita para o estado s4.Se o período de espera não for alcançado, permanece nesse estado.

- s4 (Resposta do Barramento):Aguarda a resposta do sensor DHT11 no barramento de dados.Se din for detectado como baixo (indicando a resposta), transita para o estado s5.Se din permanecer alto por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s5 (Resposta de Dados do Barramento):Aguarda a confirmação do sensor DHT11 de que está pronto para enviar dados.Se din for detectado como alto, transita para o estado s6.Se din permanecer baixo por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s6 (Sinal Inicial de Dados):Aguarda o início do sinal de dados do sensor DHT11.Se din for detectado como baixo, transita para o estado s7.Se din permanecer alto por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s7 (Detectar Início dos Dados):Detecta o início de um bit de dados enviado pelo sensor DHT11.Se din for detectado como alto, transita para o estado s8.Se din permanecer baixo por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s8 (Detectar Bit de Dados):Detecta o nível do bit de dados, se din for detectado como baixo, incrementa o contador de bits e armazena o bit de dados no registrador data_buf. Após receber os 40 bits de dados, transita para o estado s9.Se din permanecer alto por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s9 (Bloquear Dados e Aguardar Liberação):Bloqueia os dados lidos e aguarda que o sensor DHT11 libere o barramento de dados.Transfere os dados do registrador data_buf para data.Se din for detectado como alto, transita para o estado s10.Se din permanecer baixo por muito tempo (tempo limite), retorna ao estado s1 como uma medida de recuperação.

- s10 (Final da leitura):Marca o final da leitura de dados.Reinicia o estado para s1 e aguarda o próximo ciclo de aquisição de dados.

### Sensor 01
Este módulo opera em dois estados principais: s_idle (ocioso) e s_receiver_data (recebendo dados). O estado atual é determinado pelo registrador choose_case, que é atualizado em resposta a eventos e entradas.

A interação com o sensor DHT11 ocorre por meio da instância do módulo DHT11. Esse módulo específico é responsável por estabelecer a comunicação com o sensor, ler os dados fornecidos por ele e detectar qualquer erro de leitura.
O módulo faz uso de temporizadores para gerar atrasos temporais controlados. O temporizador timer_pulso_reset é ativado em resposta a um sinal de ativação e gera um atraso de aproximadamente 2 segundos antes de permitir a transição para o próximo estado. O temporizador timer_pulso_mudar_estado é usado de maneira semelhante, mas gera um atraso de cerca de 2 segundos em outro contexto.

A principal entrada deste módulo é request, que indica o tipo de informação desejada pelo sistema principal. Dependendo do valor de request, o módulo processa os dados recebidos do sensor DHT11 de maneira diferente.

Quando o sistema principal emite um pedido de dados, o módulo responde ativando o sensor, redefinindo-o para garantir que os dados anteriores sejam apagados e aguardando um tempo específico antes de passar para o próximo estado. Isso é feito para permitir que o sensor esteja pronto para fornecer dados atualizados.
Assim que os dados são lidos com sucesso do sensor DHT11, o módulo os processa de acordo com o tipo de informação solicitada. Ele separa os bits relevantes dos dados e os coloca nos locais apropriados no registrador information. Além disso, ele sinaliza que a leitura foi concluída definindo info_fineshed como 1.
Se o sensor DHT11 detectar algum erro durante a leitura, ele sinaliza isso por meio do sinal error_sensor. O módulo então define information de acordo para indicar a situação do sensor.



## Conclusão 
O objetivo principal deste trabalho era compreender a integração entre FPGA e códigos em linguagem C para desenvolver um sistema computacional, ao mesmo tempo em que se aprofundaram os conhecimentos sobre comunicação serial. Com a conclusão do projeto é verdadeiro afirmar que esse objetivo foi plenamente alcançado, visto que o projeto conseguiu estabelecer uma comunicação eficaz entre o computador e a placa, atendendo a todos os requisitos estabelecidos. 

Em relação à execução do projeto, a maioria das ferramentas utilizadas já eram familiares aos discentes, incluindo o software Quartus e o osciloscópio. No entanto, nesse projeto, a novidade incluiu a utilização da placa Mercurio IV e o sensor DHT11. As principais dificuldades associadas ao projeto surgiram em decorrência do uso das placas, por conta da quantidade limitada, e a imperícia dos alunos com relação aos cuidados no uso do DHT11. Com exceção desses desafios, o projeto transcorreu sem intercorrências significativas.

## Executando o projeto
O projeto é compatível com o kit de desenvolvimento Mercurio IV, em conjunto com o sensor DHT11. O módulo do programa em C pode ser adaptado para o sistema operacional Windows, mas foi inicialmente desenvolvido para o ambiente Linux. Como resultado, existem funcionalidades projetadas especialmente para o Linux.

Para executar o protótipo, é necessário seguir alguns passos. Inicialmente, baixar os arquivos disponíveis neste repositório e baixar algum software que permita configurar e montar as entradas e saídas da placa Mercurio IV, a exemplo o Quartus. Além disso, é essencial contar com um computador para controlar o sensor que estará conectado à placa. Uma vez que todos os materiais estejam disponíveis, será necessário configurar as entradas e saídas da placa, como os pinos da comunicação serial e da comunicação com o sensor. Por fim, basta executar o código C no terminal e fazer as solicitações desejadas. 


## Tutor 
- Anfranserai Morais Dias

## Equipe 
- [Naila Suele](https://github.com/nailasuely)
- [Rhian Pablo](https://github.com/rhianpablo11)
- [João Gabriel Araujo](https://github.com/joaogabrielaraujo)
- [Amanda Lima](https://github.com/AmandaLimaB)

## Referências 

> - [1] Santos, B. P., Silva, L. A., Celes, C. S. F. S., Borges, J. B., Neto, B. S. P., Vieira, M. A. M., ... & Loureiro, A. (2016). Internet das coisas: da teoria à prática. Minicursos SBRC-Simpósio Brasileiro de Redes de Computadores e Sistemas Distribuıdos, 31, 16.



</div>
