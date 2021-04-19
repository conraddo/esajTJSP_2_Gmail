Este repositório é dispoibilizado gratuitamente e sem quaisquer garantias. Nele você encontrará o necessário para automatizar o envio de emails de acompanhamento de processos digitais do TJSP utilizando o RStudio (https://www.rstudio.com) e o Gmail (https://www.gmail.com). Além da biblioteca padrão do R, esse repositório faz uso dos pacotes "tjsp" (https://github.com/jjesusfilho/tjsp) e mailR (https://github.com/rpremraj/mailR).

Para utilizar um dos scripts .R disponibilizados, basta abri-lo no RStudio, clicar em "Source" e seguir as instruções no console. Ambos enviam emails com as informações recentes do processo no mesmo formato básico, mas se diferenciam pelo seguinte:
		a)"acompanha input.R" pede UM número do processo, uma descrição e o email de destino. Só o número do processo é obrigatório. O email será enviado para o destinatário padrão caso nenhum outro seja informado. Para acompanhar vários processos, você pode rodar esse script outras vezes ou usar a opção b) abaixo.
		b) "acompanha todos" lê números de processo e descrições a partir da tabela "processos_tjsp.csv" e envia os emails sempre para o destinatário padrão. Uma barra de progresso acompanha a execução do programa.

Antes de usar os scripts, você vai precisar: 
	1) alterar as informações na tabela config.csv (os valores atuais são apenas exemplos e NÃO FUNCIONARÃO).
		1.1.	"login esaj" deve ser CPF de um advogado com acesso ao esaj do tjsp
		1.2.	"senha esaj" deve ser a senha do usuário 1.1
		1.3.	"pasta raiz" é o endereço completo do repositório baixado, por exemplo "C:\Users\usuario\Documents\esajTJSP_2_Gmail"
		1.4.	"login gmail" é o enrereço de email do remetente (atenção ao ponto 2 abaixo)
		1.5.	"senha gmail" deve ser a senha do usuário 1.4
		1.6.	"num_mov" indica o número máximo de movimentações que serão copiadas pro email (pessoalmente uso 7)
		1.7.	"destinatario" é o destinatário padrão dos emails enviados
	2) permitir o acesso de "aplicativos menos seguros" ao seu gmail (https://support.google.com/accounts/answer/6010255).
	3) editar a tabela "processos_tjsp.csv" com os processos que pretende acompanhar (os valores atuais são exemplos funcionais).
	4) tornar a pasta raiz (1.3) o diretorio de trabalho do RStudio com setwd(). Para evitar erros, o ideal é inserir o endereço da pasta raiz diretamente na linha comentada no código de cada script.

Devido uma atualização do esaj, uma das funções do pacote tjsp utilizada (para cada processo) gera um aviso, que pode ser ignorado.