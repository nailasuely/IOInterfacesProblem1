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
  - [Desenvolvimento em C](#desenvolvimento-em-c)
  - [Desenvolvimento em Verilog](#desenvolvimento-em-verilog)
- [Tutor](#tutor)
- [Equipe](#equipe)
- [Referências](#referências)


## Implementação

## Protocolo
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
                     

## Tutor 
- Anfranserai Morais Dias

## Equipe 
- [Naila Suele](https://github.com/nailasuely)
- [Rhian Pablo](https://github.com/rhianpablo11)
- [João Gabriel Araujo](https://github.com/joaogabrielaraujo)
- [Amanda Lima](https://github.com/AmandaLimaB)
  
</div>
