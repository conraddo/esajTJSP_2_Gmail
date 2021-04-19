options(warn=-1) #faz rodar bonitinho, mas é perigoso não desfazer

#setwd("DESCOMENTE ESSA LINHA E INSIRA AQUI O ENDEREÇO DA PASTA RAIZ PARA EVITAR ERROS")

config <- read.csv("config.csv", row.names=1)

setwd(config["pasta_raiz","input_padrao"])

require(tjsp)
require(mailR)

login <- autenticar(
  config["login esaj","input_padrao"],
  config["senha esaj","input_padrao"])

pasta_processo <- function(num_proc){
  path <- paste("Processos\\",num_proc,sep="")
  tryCatch( ok <- dir.create(path),
            silent=TRUE,
            simpleWarning(message = "log: acesso a pasta existente")
  )
  #if (ok) {print("Pasta criada")}
  return(path)
}

delete_old_htmls <- function(){
  unlink("Processos", recursive = TRUE)
  dir.create("Processos")
}

send_email_NOW <- function(assunto, corpo, destinatario=""){
  login <- config["login gmail","input_padrao"]
  if (destinatario==""){
    destinatario<-config["destinatario","input_padrao"]
    }
  pass <- config["senha gmail","input_padrao"]
  mailR::send.mail(
    from = login,
    to = destinatario,
    subject = assunto,
    body = corpo,
    smtp = list(host.name = "smtp.gmail.com",
                port = 587,
                user.name = login,
                passwd = pass,
                tls = TRUE),
    authenticate = TRUE,
    send = TRUE,
    html = FALSE)
}

### Funcoes bonitinhas                      /\
##############################################
### Bagunca que funciona                    \/

monta_email <- function(proc, desc){
  LIMITE_MOV <- strtoi(config["num mov","input_padrao"]) #Limite de linhas porque movimentaÃ§Ã£o Ã© uma baita tabela
  assunto <- paste("Acompanhamento |", desc) %>% paste("|") %>% paste(proc)
  corpo <- paste(assunto, "|") %>% paste(Sys.Date())
  
  path <- pasta_processo(proc);
  
  ## Baixa o html atualizado da 1a instancia
  
  path1a <- paste(path,"\\Primeira Instância",sep="")
  tryCatch(dir.create( path1a), silent=TRUE)
  baixar_cpopg(processos= proc, diretorio=path1a)
  
  ## Extrai as partes e começa a montar o email
  partes1a <- ler_partes(diretorio = path1a)
  if (nrow(partes1a) >0) {
    
    corpo <- paste(corpo, "\n1ª Instância", sep="\n")
    for (lin in 1:nrow(partes1a)) {
      p <- ""
      p <- paste ( p, partes1a[lin,"tipo_parte"], sep="\n") %>% 
        paste (partes1a[lin, "parte"])
      corpo <- paste(corpo, p, sep="")
    }
    rm(p)
    ## Aqui jÃ¡ coloquei as partes
    
    #Extrai a movimentaÃ§Ã£o de 1a instancia e continua a montar o corpo do email.
    
    mov1a <- ler_movimentacao_cposg(diretorio = path1a)
    numMov1a <- nrow(mov1a)
    if (numMov1a > LIMITE_MOV) {numMov1a <- LIMITE_MOV}
    
    corpo_2 <- paste(LIMITE_MOV,"Últimas movimentações:\n")
    corpo_2 <- paste("\n",corpo_2,sep="")
    
    for (lin in 1:numMov1a) {
      mov_atual <- mov1a[lin, "data"]
      mov_atual <- mov_atual %>% toString() %>% as.Date.numeric() %>% stringr::str_remove_all(" UTC") %>% paste("||")
      mov_atual <- paste(lin,mov_atual,sep=". ")
      
      corpo_2 <- paste(corpo_2, mov_atual)  %>% paste(
        toString(mov1a[lin,"movimentacao"]) %>% 
          stringr::str_remove_all("\t") %>% 
          stringr::str_remove_all("\n")
        ) %>%
        paste("\n")
    }
    
    corpo <- paste(corpo,corpo_2,sep="\n")
    rm(corpo_2)
  }
  
  #Aqui jÃ¡ terminei de montar pra primeira instÃ¢ncia
  
  
  ## Baixa o html atualizado da 2a
  path2a <- paste(path,"\\Segunda InstÃ¢ncia",sep="")
  tryCatch(dir.create(path2a), silent=TRUE)
  baixar_cposg(processos= proc, diretorio=path2a)
  partes2a <- ler_partes(diretorio = path2a)
  
  ## Vou comeÃ§ar a momtaa parte da 2a instancia
  
  if (nrow(partes2a) > 0){
    corpo_2 <- "\n2ª Instância"
    
    p <- ""
    for (lin in 1:nrow(partes2a) ) {
      p <- paste (p, partes2a[lin,"tipo_parte"], sep="\n") %>% 
        paste (partes2a[lin, "parte"])
    }
    corpo_2 <- paste(corpo_2, p, sep="\n")
    rm(p)
    
    mov2a <- ler_movimentacao_cposg(diretorio = path2a)
    numMov2a <- nrow(mov2a)
    if (numMov2a > LIMITE_MOV) {numMov2a <- LIMITE_MOV}
    
    p <- paste(LIMITE_MOV,"Últimas movimentações:\n")
    p <- paste("\n",p,sep="")
    
    for (lin in 1:numMov2a) {
      mov_atual <- mov2a[lin, "data"]
      mov_atual <- mov_atual %>% toString() %>% as.Date.numeric() %>% stringr::str_remove_all(" UTC") %>% paste("||")
      mov_atual <- paste(lin,mov_atual,sep=". ")
      
      p <- paste(p, mov_atual)  %>% paste(
        toString(mov2a[lin,"movimentacao"]) %>% 
          stringr::str_remove_all("\t") %>% 
          stringr::str_remove_all("\n") %>%
          stringr::str_remove_all("   ")
          
      ) %>%
        paste("\n")
    }
    
    corpo_2 <- paste(corpo_2,p,sep="\n")
    rm(p)
    corpo <- paste(corpo,corpo_2)
}
  
  
  return( c(assunto,corpo))
}


delete_old_htmls() #precisa fazer pra nÃ£o sair dado duplicado
processo <- readline("Digite o número do processo a consultar no e-SAJ: ")
descrição <- readline("Insira a descrição p/ assunto. P.ex. RRD x Sicrano: ")
d <- readline("Insira o destinatario do email ou aperte ENTER para usar o padrão: ")
e <- c(2)
try(e <- monta_email(processo, descrição),silent = TRUE,simpleMessage(message="Oops..."))
printar <- paste("Você também consultar o arquivo temporário em", getwd()) %>% paste("Processos/",sep="/")
print("Te enviaremos um email com o resultado!")
print( printar )
send_email_NOW(e[1],e[2], destinatario=d)

#options(warn=0) # TEM QUE FAZER ISSO AQUI PRA NÃO DAR RUIM DEPOIS