options(warn=-1) #faz rodar bonitinho, mas é perigoso não desfazer

#setwd("DESCOMENTE ESSA LINHA E INSIRA AQUI O ENDEREÇO DA PASTA RAIZ PARA EVITAR ERROS")

require(tjsp)
require(mailR)

config <- read.csv("config.csv", row.names=1)

setwd(config["pasta_raiz","input_padrao"])


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
    destinatario<-config["destinatario","input_padrao"]}
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

### FunÃ§Ãµes bonitinhas   /\
##########################
## BagunÃ§a que funciona \/

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
    
    corpo_2 <- paste(numMov1a,"Últimas movimentações:\n")
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
    
    p <- paste(numMov2a,"Últimas movimentações:\n")
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

envia_emails <- function(processos, descricoes){
  len <- length(processos)
  
  pb <- progress_bar$new(total = len,
                         show_after = 0.01,
                         clear = FALSE,
                         complete = "=",
                         incomplete = ":",
                         current = ">",
                         format = "Tempo estimado: :eta. E-mails enviados: :current/:total (:percent) :bar")
  pb$tick(len=0)
  Sys.sleep(0.5)
  pb$tick(len=0)
  
  for (elem in 1:len){
    proc <- processos[elem]
    desc <- descricoes[elem]
    x <- c()
    x <- monta_email(proc, desc)
    send_email_NOW(x[1],x[2])
    rm(x)
    pb$tick()
  }
}

progress_bar <- progress::progress_bar

#print("Início do script")
delete_old_htmls() #precisa fazer pra nÃ£o sair dado duplicado
nome_csv <- "processos_tjsp.csv"
processos <- read.csv(nome_csv)
try(envia_emails(processos$num_cnj,processos$desc),silent = TRUE,simpleWarning(message="Oops..."))

#options(warn=0) # TEM QUE FAZER ISSO AQUI PRA NÃO DAR RUIM DEPOIS