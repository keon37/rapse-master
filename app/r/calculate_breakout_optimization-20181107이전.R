
# install.packages("dbConnect") # R 설치 폴더에 필요한 library 사전설치 필요. R cmd창 실행 후 install.packages("lpSolve") install.packages("igraph")
library(dbConnect)
library(dplyr)
library(tidyr)
library(lpSolve)
library(igraph)

productionConnection <- function() {
  conn <- dbConnect(dbDriver("MySQL"),dbname = 'rapse',host = "host.docker.internal",user = "rapse_dlqldbwj",password = "CZwAfcWizT7qtkaDDQz", port = 33060 )
  dbGetQuery( conn, "set names 'utf8'" )
  return(conn)
}

developmentBrotherConnection <- function() {
  conn <- dbConnect(dbDriver("MySQL"),dbname = 'rapse',host = "host.docker.internal",user = "rapse_dlqldbwj",password = "CZwAfcWizT7qtkaDDQz" )
  dbGetQuery( conn, "set names 'utf8'" )
  return(conn)
}

developmentSnuConnection <- function() {
  conn <- dbConnect(dbDriver("MySQL"),dbname = 'livestock',host = "147.46.229.85",user = "ais",password = "ezfarm3414" )
  dbGetQuery( conn, "set names 'euckr'" )
  return(conn)
}

# 개발환경 / 실제서버에 따라 connection 분기처리 
getConnection <- function() {
  mode <- Sys.getenv("APPLICATION_MODE")

  if(mode=='DEVELOPMENT') {
    return(developmentBrotherConnection())
  } else {
    return(productionConnection())
  }
}

# getConnection <- function() { return(developmentSnuConnection()) }

#linear programing for multiple solutions
lp_solve <- function(obj.func, st.func, dir.func, rhs.func, numcols, numsols) {
  lp.sol <- lp('min', obj.func, st.func, dir.func, rhs.func, all.bin=T, num.bin.solns=numsols)
  solutions <- as.data.frame(matrix(head(lp.sol$solution, numcols*numsols), nrow=numsols, byrow=TRUE))
  solutions$neg <- apply(solutions,1,FUN=function(x) any(x<0))
  solutions$zero <- apply(solutions[,1:numcols],1,FUN=function(x) ifelse(sum(x==0)>=(numcols-1),T,F))
  sel_sols <- solutions[!(solutions$neg | solutions$zero),1:numcols]
  return(sel_sols)
}

# final solution fucntion
final_sol_func <- function(sel_sols,numcols,tb_adm_adj_clu){
  if(nrow(sel_sols)==0){
    final_sols <- sel_sols 
  } else {
    sel_sols$clu <- NA
    for(i in 1:nrow(sel_sols)){
      sol_sel <- sel_sols[i,1:numcols]
      sol.mat <- as.matrix(tb_adm_adj_clu[as.logical(sol_sel),as.logical(c(FALSE,sol_sel))])
      NET <- graph.adjacency(sol.mat,mode="undirected",weighted=NULL)
      sel_sols$clu[i] <- clusters(NET)$no
    }
    final_sols <- sel_sols[sel_sols$clu==1,1:numcols]    
  }
  return(final_sols)
}
# brk.place <- brk.place[1,1] ; brk.place <- '전라북도_익산시'
opt_clu_func <- function(type,species,tb_adm_adj,tb_adm_adj_long,brk.place,fac_capa_addr,farm_use_fac_addr,addr_trmat) {
  if( brk.place %in% c('경상북도_울릉군')){
    near2.df <- data.frame(address=brk.place,near_rank=0)
    # 발생지 중심으로 리스트 필터링
    fac_capa_clu <- merge(near2.df,fac_capa_addr,by='address',all.x=T)
    farm_use_fac_clu <- merge(near2.df,farm_use_fac_addr,by='address',all.x=T)

    brk.out <- addr_trmat[,1:2]
    mat1 <- as.matrix(addr_trmat[,-1])/max(as.matrix(addr_trmat[,-1]))
    colnames(brk.out) <- c('address','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$address==as.character(brk.place),2] <- 1
    brk.out[,3] <- t(t(brk.out[,2]) %*% mat1)
    colnames(brk.out)[3] <- 'spread_probability'
    sprd_prob_clu <- merge(near2.df,brk.out[,c(1,3)],by='address',all.x=T)
    sprd_prob_std <- sprd_prob_clu
    
    final_sol_list <- brk.out[,1:2]
    colnames(final_sol_list)[2] <- 'opt_clu1'
    
    eval_sol <- data.frame(matrix(rep(NA,17),nrow=1))
    colnames(eval_sol) <- c('num_sol',colnames(fac_capa_clu[,3:18]))
    fac_sel <- fac_capa_clu[,3:18]
    use_sel <- farm_use_fac_clu[,3:18]
    
    ind_rate <- (round((fac_sel/1.5-use_sel) / use_sel,3)+1)*100
    col_name <- colnames(ind_rate)
    ind_rate[is.na(ind_rate)] <- NA
    ind_rate <- as.data.frame(ifelse(ind_rate>100,100,ind_rate))
    colnames(ind_rate) <- col_name
      
    ind_rate[is.na(ind_rate)] <- 100
    eval_sol[1,1] <- 1
    eval_sol[1,2:17] <- ind_rate
    eval_sol$sprd_sum <- 1
    
  } else if(brk.place %in% c('제주특별자치도_제주시','제주특별자치도_서귀포시')) {
    near2.df <- data.frame(address=c('제주특별자치도_제주시','제주특별자치도_서귀포시'),near_rank=0)
    # 발생지 중심으로 리스트 필터링
    fac_capa_clu <- merge(near2.df,fac_capa_addr,by='address',all.x=T)
    farm_use_fac_clu <- merge(near2.df,farm_use_fac_addr,by='address',all.x=T)
    
    brk.out <- addr_trmat[,1:2]
    mat1 <- as.matrix(addr_trmat[,-1])/max(as.matrix(addr_trmat[,-1]))
    colnames(brk.out) <- c('address','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$address==as.character(brk.place),2] <- 1
    brk.out[,3] <- t(t(brk.out[,2]) %*% mat1)
    colnames(brk.out)[3] <- 'spread_probability'
    sprd_prob_clu <- merge(near2.df,brk.out[,c(1,3)],by='address',all.x=T)
    sprd_prob_std <- sprd_prob_clu
    
    brk.out[brk.out$address %in% c('제주특별자치도_제주시','제주특별자치도_서귀포시'),2] <- 1
    final_sol_list <- brk.out
    colnames(final_sol_list)[2] <- 'opt_clu1'
    
    eval_sol <- data.frame(matrix(rep(NA,17),nrow=1))
    colnames(eval_sol) <- c('num_sol',colnames(fac_capa_clu[,3:18]))
    fac_sel <- fac_capa_clu[,3:18]
    use_sel <- farm_use_fac_clu[,3:18]
    tmp <- cal_ind_rate(fac_sel,use_sel)
    tmp[is.na(tmp)] <- 100
    eval_sol[1,1] <- 1
    eval_sol[1,2:17] <- tmp
    eval_sol$sprd_sum <- 1
    
  }else { # 제주, 울릉 외 지역 final sol 계산
    near1 <- tb_adm_adj[which(tb_adm_adj[tb_adm_adj$address==brk.place,]==1)-1,1] # 최초발생지와 인접지역 필터링
    near1.df <- data.frame(address=near1,near_rank=1)      # 최초발생지 인접지역을 1로 코딩
    near1.df$address <- as.character(near1.df$address)
    near1.df[nrow(near1.df)+1,] <- c(brk.place,0)
    
    near2 <- NULL
    for(i in 1:length(near1)){
      near2 <- c(near2,tb_adm_adj[which(tb_adm_adj[tb_adm_adj$address==near1[i],]==1)-1,1])
    } 
    near2.df <- distinct(data.frame(address=near2))     # 최초발생지 인접지역의 인접지역 중복 제거
    near2 <- as.character(near2.df[,1])                 
    near2.df <- merge(near2.df,near1.df,by='address',all.x=T) # 최초발생지+인접지역 df를 merge 
    near2.df[is.na(near2.df)] <- 2                            # 최초발생지+인접지역 아닌 곳을 2로 코딩
    
    # 발생지 중심으로 리스트 필터링
    fac_capa_clu <- merge(near2.df,fac_capa_addr,by='address',all.x=T)
    farm_use_fac_clu <- merge(near2.df,farm_use_fac_addr,by='address',all.x=T)
    tb_adm_adj_clu <- tb_adm_adj_long %>% filter(address%in%near2.df$address, address2%in%near2.df$address) %>% spread(address2,adj,fill=0)
    
    # 시설용량, 확산확률 표준화 
    std.func <- function(x){x/sum(x)}
    fac_capa_clu_std <- cbind(fac_capa_clu[,1:2],round(apply(fac_capa_clu[,3:ncol(fac_capa_clu)],2,std.func),3))
    
    brk.out <- addr_trmat[,1:2]
    mat1 <- as.matrix(addr_trmat[,-1])/max(as.matrix(addr_trmat[,-1]))
    colnames(brk.out) <- c('address','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$address==as.character(brk.place),2] <- 1
    brk.out[,3] <- t(t(brk.out[,2]) %*% mat1)
    colnames(brk.out)[3] <- 'spread_probability'
    sprd_prob_clu <- merge(near2.df,brk.out[,c(1,3)],by='address',all.x=T)
    # sprd_prob_std <- as.numeric(round(sprd_prob_clu$spread_probability/max(sprd_prob_clu$spread_probability),3))
    if(sprd_prob_clu[sprd_prob_clu$near_rank==0,'spread_probability']==0) {
      sprd_prob_clu[sprd_prob_clu$near_rank==0,'spread_probability'] <- max(sprd_prob_clu$spread_probability)
    }
    if(sum(sprd_prob_clu$spread_probability)!=0){
      sprd_prob_std <- as.numeric(round(sprd_prob_clu$spread_probability/as.numeric(sprd_prob_clu[sprd_prob_clu$address==brk.place,'spread_probability']),3))  
    } else { 
      sprd_prob_clu[sprd_prob_clu$near_rank==0,'spread_probability'] <- 1
      sprd_prob_std <- as.integer(sprd_prob_clu$spread_probability)
    }
    
    min_sprd_prob <- 1.3 # LP 제약식에서 권역내 확산확률 합의 최소값
    min_capa_rate <- 0.1
    
    obj.func <- rep(1,nrow(near2.df))
    st.func1 <- as.integer(t(near2.df %>% mutate(brk.out=ifelse(near_rank==0,1,0)) %>% select(brk.out)))
    st.func2 <- sprd_prob_std
    
    if(type=='hpai'){
      if(species=='10'){
        st.func3 <- fac_capa_clu_std$f1_chi
        st.func4 <- fac_capa_clu_std$f2_chi
        st.func5 <- fac_capa_clu_std$f3_chi
        st.func6 <- fac_capa_clu_std$f4_chi
      } else if(species=='01'){
        st.func3 <- fac_capa_clu_std$f1_duc
        st.func4 <- fac_capa_clu_std$f2_duc
        st.func5 <- fac_capa_clu_std$f3_duc
        st.func6 <- fac_capa_clu_std$f4_duc
      } else {
        st.func3 <- (fac_capa_clu_std$f1_chi+fac_capa_clu_std$f1_chi)/2
        st.func4 <- (fac_capa_clu_std$f2_chi+fac_capa_clu_std$f2_chi)/2
        st.func5 <- (fac_capa_clu_std$f3_chi+fac_capa_clu_std$f3_chi)/2
        st.func6 <- (fac_capa_clu_std$f4_chi+fac_capa_clu_std$f4_chi)/2
      }
    } else {
      if(species=='10'){
        st.func3 <- fac_capa_clu_std$f1_pig
        st.func4 <- fac_capa_clu_std$f2_pig
        st.func5 <- fac_capa_clu_std$f3_pig
        st.func6 <- fac_capa_clu_std$f4_pig
      } else if(species=='01'){
        st.func3 <- fac_capa_clu_std$f1_cow
        st.func4 <- fac_capa_clu_std$f2_cow
        st.func5 <- fac_capa_clu_std$f3_cow
        st.func6 <- fac_capa_clu_std$f4_cow
      } else {
        st.func3 <- (fac_capa_clu_std$f1_pig+fac_capa_clu_std$f1_cow)/2
        st.func4 <- (fac_capa_clu_std$f2_pig+fac_capa_clu_std$f2_cow)/2
        st.func5 <- (fac_capa_clu_std$f3_pig+fac_capa_clu_std$f3_cow)/2
        st.func6 <- (fac_capa_clu_std$f4_pig+fac_capa_clu_std$f4_cow)/2
      }
    }
    
    st.func <- rbind(st.func1,st.func2,st.func3,st.func4,st.func5,st.func6)
    dir.func <- c("=",">",">=",">=",">=",">=")
    rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
    
    numsols <- 50; numcols <- nrow(near2.df)
    
    sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
    
    if(nrow(sel_sols)<=1) {
      min_capa_rate <- min_capa_rate - 0.05
      rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
      sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
      if(nrow(sel_sols)<=1) {
        min_capa_rate <- min_capa_rate - 0.05
        rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
        sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols) 
        if(nrow(sel_sols)<=1) {
          min_sprd_prob <- min_sprd_prob - 0.1
          rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
          sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
          if(nrow(sel_sols)<=1) {
            min_sprd_prob <- min_sprd_prob - 0.1
            rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
            sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
            if(nrow(sel_sols)<=1) {
              min_sprd_prob <- min_sprd_prob - 0.1
              rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
              sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
            }
          }
        }
      }
    }
    final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
    
    # if(nrow(sel_sols)!=0){
    #   near2.tmp <- cbind(near2.df,t(sel_sols))
    #   near2.tmp <- near2.tmp %>% filter(near_rank <= 1)
    #   near2.tmp$near_sum <- apply(near2.tmp[,3:ncol(near2.tmp)],1,sum)
    #   near2.tmp <- near2.tmp %>% filter(near_sum>=1) %>% select(address,near_rank)  
    # } else { near2.tmp <- near1.df }
  
    min_sprd_prob <- 1.3 # LP 제약식에서 권역내 확산확률 합의 최소값
    min_capa_rate <- 0.1
    if(nrow(final_sols)==0) {
      min_capa_rate <- min_capa_rate - 0.05
      rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
      sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
      final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
      if(nrow(final_sols)==0) {
        min_capa_rate <- min_capa_rate - 0.05
        rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
        sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
        final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
        if(nrow(final_sols)==0) {
          min_sprd_prob <- min_sprd_prob - 0.1
          rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
          sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
          final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
          if(nrow(final_sols)==0) {
            min_sprd_prob <- min_sprd_prob - 0.1
            rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
            sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
            final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
            if(nrow(final_sols)==0) {
              min_sprd_prob <- min_sprd_prob - 0.1
              rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
              sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
              final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
            }
          }
        }
      }
    }
    
    
    
    
    
    if(nrow(final_sols)==0) {
      near2.df <- near1.df 
      # 발생지 중심으로 리스트 필터링
      fac_capa_clu <- merge(near2.df,fac_capa_addr,by='address',all.x=T)
      farm_use_fac_clu <- merge(near2.df,farm_use_fac_addr,by='address',all.x=T)
      tb_adm_adj_clu <- tb_adm_adj_long %>% filter(address%in%near2.df$address, address2%in%near2.df$address) %>% spread(address2,adj,fill=0)
      
      # 시설용량, 확산확률 표준화 
      std.func <- function(x){x/sum(x)}
      fac_capa_clu_std <- cbind(fac_capa_clu[,1:2],round(apply(fac_capa_clu[,3:ncol(fac_capa_clu)],2,std.func),3))
      
      brk.out <- addr_trmat[,1:2]
      mat1 <- as.matrix(addr_trmat[,-1])/max(as.matrix(addr_trmat[,-1]))
      colnames(brk.out) <- c('address','breaks')
      brk.out[,2] <- 0 
      brk.out[brk.out$address==as.character(brk.place),2] <- 1
      brk.out[,3] <- t(t(brk.out[,2]) %*% mat1)
      colnames(brk.out)[3] <- 'spread_probability'
      sprd_prob_clu <- merge(near2.df,brk.out[,c(1,3)],by='address',all.x=T)
      # sprd_prob_std <- as.numeric(round(sprd_prob_clu$spread_probability/max(sprd_prob_clu$spread_probability),3))
      if(sprd_prob_clu[sprd_prob_clu$near_rank==0,'spread_probability']==0) {
        sprd_prob_clu[sprd_prob_clu$near_rank==0,'spread_probability'] <- max(sprd_prob_clu$spread_probability)
      }
      if(sum(sprd_prob_clu$spread_probability)!=0){
        sprd_prob_std <- as.numeric(round(sprd_prob_clu$spread_probability/as.numeric(sprd_prob_clu[sprd_prob_clu$address==brk.place,'spread_probability']),3))  
      } else { 
        sprd_prob_clu[sprd_prob_clu$near_rank==0,'spread_probability'] <- 1
        sprd_prob_std <- as.integer(sprd_prob_clu$spread_probability)
      }  
      min_sprd_prob <- 1.3 # LP 제약식에서 권역내 확산확률 합의 최소값
      min_capa_rate <- 0.1
      
      obj.func <- rep(1,nrow(near2.df))
      st.func1 <- as.integer(t(near2.df %>% mutate(brk.out=ifelse(near_rank==0,1,0)) %>% select(brk.out)))
      st.func2 <- sprd_prob_std
      
      if(type=='hpai'){
        if(species=='10'){
          st.func3 <- fac_capa_clu_std$f1_chi
          st.func4 <- fac_capa_clu_std$f2_chi
          st.func5 <- fac_capa_clu_std$f3_chi
          st.func6 <- fac_capa_clu_std$f4_chi
        } else if(species=='01'){
          st.func3 <- fac_capa_clu_std$f1_duc
          st.func4 <- fac_capa_clu_std$f2_duc
          st.func5 <- fac_capa_clu_std$f3_duc
          st.func6 <- fac_capa_clu_std$f4_duc
        } else {
          st.func3 <- (fac_capa_clu_std$f1_chi+fac_capa_clu_std$f1_chi)/2
          st.func4 <- (fac_capa_clu_std$f2_chi+fac_capa_clu_std$f2_chi)/2
          st.func5 <- (fac_capa_clu_std$f3_chi+fac_capa_clu_std$f3_chi)/2
          st.func6 <- (fac_capa_clu_std$f4_chi+fac_capa_clu_std$f4_chi)/2
        }
      } else {
        if(species=='10'){
          st.func3 <- fac_capa_clu_std$f1_pig
          st.func4 <- fac_capa_clu_std$f2_pig
          st.func5 <- fac_capa_clu_std$f3_pig
          st.func6 <- fac_capa_clu_std$f4_pig
        } else if(species=='01'){
          st.func3 <- fac_capa_clu_std$f1_cow
          st.func4 <- fac_capa_clu_std$f2_cow
          st.func5 <- fac_capa_clu_std$f3_cow
          st.func6 <- fac_capa_clu_std$f4_cow
        } else {
          st.func3 <- (fac_capa_clu_std$f1_pig+fac_capa_clu_std$f1_cow)/2
          st.func4 <- (fac_capa_clu_std$f2_pig+fac_capa_clu_std$f2_cow)/2
          st.func5 <- (fac_capa_clu_std$f3_pig+fac_capa_clu_std$f3_cow)/2
          st.func6 <- (fac_capa_clu_std$f4_pig+fac_capa_clu_std$f4_cow)/2
        }
      }
      
      st.func <- rbind(st.func1,st.func2,st.func3,st.func4,st.func5,st.func6)
      dir.func <- c("=",">",">=",">=",">=",">=")
      rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
      
      numsols <- 50; numcols <- nrow(near2.df)
      
      sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
      
      if(nrow(sel_sols)<=1) {
        min_capa_rate <- min_capa_rate - 0.05
        rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
        sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
        if(nrow(sel_sols)<=1) {
          min_capa_rate <- min_capa_rate - 0.05
          rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
          sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols) 
          if(nrow(sel_sols)<=1) {
            min_sprd_prob <- min_sprd_prob - 0.1
            rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
            sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
            if(nrow(sel_sols)<=1) {
              min_sprd_prob <- min_sprd_prob - 0.1
              rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
              sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
              if(nrow(sel_sols)<=1) {
                min_sprd_prob <- min_sprd_prob - 0.1
                rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
                sel_sols <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
              }
            }
          }
        }
      }
      final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
      
      min_sprd_prob <- 1.3 # LP 제약식에서 권역내 확산확률 합의 최소값
      min_capa_rate <- 0.1
      if(nrow(final_sols)==0) {
        min_capa_rate <- min_capa_rate - 0.05
        rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
        sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
        final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
        if(nrow(final_sols)==0) {
          min_capa_rate <- min_capa_rate - 0.05
          rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
          sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
          final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
          if(nrow(final_sols)==0) {
            min_sprd_prob <- min_sprd_prob - 0.1
            rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
            sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
            final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
            if(nrow(final_sols)==0) {
              min_sprd_prob <- min_sprd_prob - 0.1
              rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
              sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
              final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
              if(nrow(final_sols)==0) {
                min_sprd_prob <- min_sprd_prob - 0.1
                rhs.func <- c(1,min_sprd_prob,rep(min_capa_rate,4))
                sel_sols  <- lp_solve(obj.func, st.func, dir.func, rhs.func, numcols, numsols)   
                final_sols <- final_sol_func(sel_sols,numcols,tb_adm_adj_clu)
              }
            }
          }
        }
      }
    }
      
    if(nrow(final_sols)==0) {
      near2.tmp <- near1.df
      eval_sol <- data.frame(matrix(rep(NA,17),nrow=1))
      colnames(eval_sol) <- c('num_sol',colnames(fac_capa_clu[,3:18]))
      fac_capa_clu <- merge(near2.tmp,fac_capa_addr,by='address',all.x=T)
      farm_use_fac_clu <- merge(near2.tmp,farm_use_fac_addr,by='address',all.x=T)
      fac_sel <- fac_capa_clu[,3:18] 
      use_sel <- farm_use_fac_clu[,3:18] 
      tmp <- cal_ind_rate(fac_sel,use_sel)
      tmp[is.na(tmp)] <- 100
      eval_sol[1,1] <- 1
      eval_sol[1,2:17] <- tmp
      eval_sol$sprd_sum <- 1
      final_sol_list <- data.frame(address=brk.out$address)
      tmp <- data.frame(address=near2.tmp$address, variable=1)
      final_sol_list <- merge(final_sol_list,tmp,by='address',all.x=T)
      final_sol_list[is.na(final_sol_list$variable),2] <- 0
      colnames(final_sol_list)[2] <- paste('opt_clu',1,sep='')
    } else {
      eval_sol <- data.frame(matrix(rep(NA,17),nrow=1))
      colnames(eval_sol) <- c('num_sol',colnames(fac_capa_clu[,3:18]))
      for(i in 1:nrow(final_sols)){
        fac_sel <- fac_capa_clu[as.logical(final_sols[i,]),3:18] 
        use_sel <- farm_use_fac_clu[as.logical(final_sols[i,]),3:18] 
        tmp <- cal_ind_rate(fac_sel,use_sel)
        tmp[is.na(tmp)] <- 100
        eval_sol[i,1] <- i
        eval_sol[i,2:17] <- tmp
      }
      eval_sol$sprd_sum <- apply(final_sols,1,FUN=function(x) sum(sprd_prob_clu[as.logical(x),'spread_probability']))
      
      final_sol_list <- data.frame(address=brk.out$address)
      for(i in 1:nrow(final_sols)){
        tmp <- data.frame(address=near2.df[as.logical(final_sols[i,1:nrow(near2.df)]),'address'], variable=1)
        final_sol_list <- merge(final_sol_list,tmp,by='address',all.x=T)
        final_sol_list[is.na(final_sol_list$variable),i+1] <- 0
        colnames(final_sol_list)[i+1] <- paste('opt_clu',i,sep='')
      }
    }
    

  } # 제주, 울릉 판별 후 final sol 계산 파트 종료

  return(list(eval_sol,final_sol_list))
}

cal_ind_rate <- function(dat1,dat2){
  capa_sum <- apply(dat1,2,sum)
  use_sum <- apply(dat2,2,sum)
  ind_rate <- (round((capa_sum/1.5-use_sum) / use_sum,3)+1)*100
  col_name <- colnames(ind_rate)
  ind_rate <- ifelse(ind_rate>100,100,ind_rate)
  colnames(ind_rate) <- col_name
  return(as.data.frame(t(ind_rate)))
}


getResult <- function(type, species, weights, places, optimization) {
  # print(type) # 'fmd' / 'hpai'
  # print(species) # '10' / '01' / '11'
  # print(weights) # '0000000' ~ '5555555'
  # print(places) # list('서울특별시|2018-03-21', '서울특별시|2018-03-21', '서울특별시|2018-03-21')
  # print(optimization) # '전체시설균등' / '도축장 중심' / '사료공장 중심' / '종축장 중심'

  conn <- getConnection()
  # conn <- developmentSnuConnection()

  brk.place <- data.frame(address=rep(NA,3),date=rep(NA,3))
  for(i in 1:3) {
    if(places[i]!="|") {
      brk.place[i,1] <- strsplit(as.character(places[i]),split='|',fixed=T)[[1]][1]
      brk.place[i,2] <- strsplit(as.character(places[i]),split='|',fixed=T)[[1]][2]
    } else {
      brk.place[i,1] <- NA ; brk.place[i,2] <- NA
    }
  } 
  brk.place <- brk.place %>% arrange(date)
  if(nrow(na.omit(brk.place))==3){
    brk.place$interval <- NA
    brk.place$interval[1] <- as.integer(as.Date(brk.place$date[2]) - as.Date(brk.place$date[1]))
    brk.place$interval[2] <- as.integer(as.Date(brk.place$date[3]) - as.Date(brk.place$date[2]))  
  } else if(nrow(na.omit(brk.place))==2){
    brk.place$interval <- NA
    brk.place$interval[1] <- as.integer(as.Date(brk.place$date[2]) - as.Date(brk.place$date[1]))
  } else {
    brk.place$interval <- NA
  }
  one_trans_time <- 3
  brk.place$time <- floor(brk.place$interval / one_trans_time)
  if(type=='fmd') {
    if(as.character(species)=='10'){
      trans_tb <- dbGetQuery(conn, "select * from trmat_pig")
    } else if(as.character(species)=='01'){
      trans_tb <- dbGetQuery(conn, "select * from trmat_cow")
    } else if(as.character(species)=='11'){
      trans_tb <- dbGetQuery(conn, "select * from trmat_hoof")
    }    
  } else if(type=='hpai'){
    if(as.character(species)=='10'){
      trans_tb <- dbGetQuery(conn, "select * from trmat_chi")
    } else if(as.character(species)=='01'){
      trans_tb <- dbGetQuery(conn, "select * from trmat_duc")
    } else if(as.character(species)=='11'){
      trans_tb <- dbGetQuery(conn, "select * from trmat_poul")
    }
  }
  tb_adm_adj <- dbGetQuery(conn, "select * from tb_adm_adj")
  fac_capa_addr <- dbGetQuery(conn, "select * from fac_capa_addr")
  farm_use_fac_addr <- dbGetQuery(conn, "select * from farm_use_fac_addr")
  dbDisconnect(conn)
  trans_sum <- cbind(trans_tb[,1:2],data.frame(trans_tb[,3]*as.numeric(substr(weights,1,1))+trans_tb[,4]*as.numeric(substr(weights,2,2))+trans_tb[,5]*as.numeric(substr(weights,3,3))+trans_tb[,6]*as.numeric(substr(weights,4,4))+
                                                 trans_tb[,7]*as.numeric(substr(weights,5,5))+trans_tb[,8]*as.numeric(substr(weights,6,6))+trans_tb[,9]*as.numeric(substr(weights,7,7))))
  colnames(trans_sum)[3] <- 'freq'
  addr_trmat <- spread(trans_sum,addr_to,freq,fill=0)
  mat1 <- as.matrix(addr_trmat[,-1])/max(as.matrix(addr_trmat[,-1]))  # 최대값으로 전체를 나눠서 0~1사이 값으로...

# spread probability 계산파트 시작 :  발생 지역 개수별 조건문 
if(nrow(na.omit(brk.place[,1:2]))==1) {
  brk.out <- addr_trmat[,1:2]
  colnames(brk.out) <- c('city','breaks')
  brk.out[,2] <- 0 
  brk.out[brk.out$city==as.character(brk.place[1,1]),2] <- 1
  brk.out[,3] <- t(t(brk.out[,2]) %*% mat1)
  colnames(brk.out)[3] <- 'lv1'
  breakout_optimization_results <- brk.out[,c(1,3)] 
  colnames(breakout_optimization_results) <- c('address','spread_probability')
  # Exception: Data must be 1-dimensional 문제 해결
  breakout_optimization_results$spread_probability <- as.numeric(breakout_optimization_results$spread_probability)
} else if(nrow(na.omit(brk.place[,1:2]))==2) {
  if(brk.place[1,4]!=0){
    brk.out <- addr_trmat[,1:2]
    colnames(brk.out) <- c('city','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$city==as.character(brk.place[1,1]),2] <- 1
    num_lv <- brk.place[1,4] 
    for(i in 3:(num_lv+2)){
      brk.out[,i] <- t(t(brk.out[,i-1]) %*% mat1)
    }
    brk.out[brk.out$city==as.character(brk.place[2,1]),num_lv+2] <- 1
    brk.out[,num_lv+3] <- t(t(brk.out[,num_lv+2]) %*% mat1)
    
    colnames(brk.out)[3:(num_lv+3)] <- paste('lv',seq(1,(num_lv+1),1),sep='')
    breakout_optimization_results <- brk.out[,c(1,num_lv+3)] 
    colnames(breakout_optimization_results) <- c('address','spread_probability')
    # Exception: Data must be 1-dimensional 문제 해결
    breakout_optimization_results$spread_probability <- as.numeric(breakout_optimization_results$spread_probability)  
  } else {
    brk.out <- addr_trmat[,1:2]
    colnames(brk.out) <- c('city','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$city%in%as.character(c(brk.place[1,1],brk.place[2,1])),2] <- 1
    brk.out[,3] <- t(t(brk.out[,2]) %*% mat1)
    colnames(brk.out)[3] <- 'lv1'
    breakout_optimization_results <- brk.out[,c(1,3)] 
    colnames(breakout_optimization_results) <- c('address','spread_probability')
    # Exception: Data must be 1-dimensional 문제 해결
    breakout_optimization_results$spread_probability <- as.numeric(breakout_optimization_results$spread_probability)
  }
} else if(nrow(na.omit(brk.place[,1:2]))==3) {
  if(brk.place[1,4]!=0 & brk.place[2,4]!=0){
    brk.out <- addr_trmat[,1:2]
    colnames(brk.out) <- c('city','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$city==as.character(brk.place[1,1]),2] <- 1
    num_lv1 <- brk.place[1,4] 
    for(i in 3:(num_lv1+2)){
      brk.out[,i] <- t(t(brk.out[,i-1]) %*% mat1)
    }
    brk.out[brk.out$city==as.character(brk.place[2,1]),num_lv1+2] <- 1
    num_lv2 <- brk.place[2,4]
    for(i in (num_lv1+3):(num_lv1+num_lv2+2)){
      brk.out[,i] <- t(t(brk.out[,i-1]) %*% mat1)
    }
    brk.out[brk.out$city==as.character(brk.place[3,1]),num_lv1+num_lv2+2] <- 1
    brk.out[,num_lv1+num_lv2+3] <- t(t(brk.out[,num_lv1+num_lv2+2]) %*% mat1)
    colnames(brk.out)[3:(num_lv1+num_lv2+3)] <- paste('lv',seq(1,(num_lv1+num_lv2+1),1),sep='')
    breakout_optimization_results <- brk.out[,c(1,num_lv1+num_lv2+3)] 
    colnames(breakout_optimization_results) <- c('address','spread_probability')
    # Exception: Data must be 1-dimensional 문제 해결
    breakout_optimization_results$spread_probability <- as.numeric(breakout_optimization_results$spread_probability)
  } else if(brk.place[1,4]!=0 & brk.place[2,4]==0){
    brk.out <- addr_trmat[,1:2]
    colnames(brk.out) <- c('city','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$city%in%as.character(brk.place[1,1]),2] <- 1
    num_lv1 <- brk.place[1,4] 
    for(i in 3:(num_lv1+2)){
      brk.out[,i] <- t(t(brk.out[,i-1]) %*% mat1)
    }
    brk.out[brk.out$city==as.character(c(brk.place[2,1],brk.place[3,1])),num_lv1+2] <- 1
    brk.out[,num_lv1+3] <- t(t(brk.out[,num_lv1+2]) %*% mat1)
    colnames(brk.out)[3:(num_lv1+3)] <- paste('lv',seq(1,(num_lv1+1),1),sep='')
    breakout_optimization_results <- brk.out[,c(1,num_lv1+3)] 
    colnames(breakout_optimization_results) <- c('address','spread_probability')
    # Exception: Data must be 1-dimensional 문제 해결
    breakout_optimization_results$spread_probability <- as.numeric(breakout_optimization_results$spread_probability)
  } else if(brk.place[1,4]==0 & brk.place[2,4]!=0){
    brk.out <- addr_trmat[,1:2]
    colnames(brk.out) <- c('city','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$city%in%as.character(c(brk.place[1,1],brk.place[2,1])),2] <- 1
    num_lv1 <- brk.place[2,4] 
    for(i in 3:(num_lv1+2)){
      brk.out[,i] <- t(t(brk.out[,i-1]) %*% mat1)
    }
    brk.out[brk.out$city==as.character(c(brk.place[3,1])),num_lv1+2] <- 1
    brk.out[,num_lv1+3] <- t(t(brk.out[,num_lv1+2]) %*% mat1)
    colnames(brk.out)[3:(num_lv1+3)] <- paste('lv',seq(1,(num_lv1+1),1),sep='')
    breakout_optimization_results <- brk.out[,c(1,num_lv1+3)] 
    colnames(breakout_optimization_results) <- c('address','spread_probability')
    # Exception: Data must be 1-dimensional 문제 해결
    breakout_optimization_results$spread_probability <- as.numeric(breakout_optimization_results$spread_probability)
  } else if(brk.place[1,4]==0 & brk.place[2,4]==0){
    brk.out <- addr_trmat[,1:2]
    colnames(brk.out) <- c('city','breaks')
    brk.out[,2] <- 0 
    brk.out[brk.out$city%in%as.character(c(brk.place[1,1],brk.place[2,1],brk.place[3,1])),2] <- 1
    brk.out[,3] <- t(t(brk.out[,2]) %*% mat1)
    colnames(brk.out)[3] <- 'lv1'
    breakout_optimization_results <- brk.out[,c(1,3)] 
    colnames(breakout_optimization_results) <- c('address','spread_probability')
    # Exception: Data must be 1-dimensional 문제 해결
    breakout_optimization_results$spread_probability <- as.numeric(breakout_optimization_results$spread_probability)
  }
} # spread probabilty 계산 파트 종료

# 인접 시군 행렬 wide화 
  tb_adm_adj_long <- tb_adm_adj
  tb_adm_adj <- tb_adm_adj %>% spread(address2,adj)
  colnames(tb_adm_adj)[2:163] <- paste('V',1:162,sep='')

opt_capa_rank <- function(type,species,eval_sol){
  if(type=='hpai'){
    if(species=='10'){
      eval_sol <- eval_sol %>% mutate(cap_avg=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2), cap_f1=f1_chi, cap_f2=f2_chi, cap_f3=f3_chi, cap_f4=f4_chi)
    } else if(species=='01'){
      eval_sol <- eval_sol %>% mutate(cap_avg=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2), cap_f1=f1_duc, cap_f2=f2_duc, cap_f3=f3_duc, cap_f4=f4_duc)
    } else {
      eval_sol <- eval_sol %>% mutate(cap_avg=round((f1_chi+f2_chi+f3_chi+f4_chi+f1_duc+f2_duc+f3_duc+f4_duc)/8,2), cap_f1=(f1_chi+f1_duc)/2, cap_f2=(f2_chi+f2_duc)/2, cap_f3=(f3_chi+f3_duc)/2, cap_f4=(f4_chi+f4_duc)/2)
    }
  } else {
    if(species=='10'){
      eval_sol <- eval_sol %>% mutate(cap_avg=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2), cap_f1=f1_pig, cap_f2=f2_pig, cap_f3=f3_pig, cap_f4=f4_pig)
    } else if(species=='01'){
      eval_sol <- eval_sol %>% mutate(cap_avg=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2), cap_f1=f1_cow, cap_f2=f2_cow, cap_f3=f3_cow, cap_f4=f4_cow)
    } else {
      eval_sol <- eval_sol %>% mutate(cap_avg=round((f1_pig+f2_pig+f3_pig+f4_pig+f1_cow+f2_cow+f3_cow+f4_cow)/8,2), cap_f1=(f1_pig+f1_cow)/2, cap_f2=(f2_pig+f2_cow)/2, cap_f3=(f3_pig+f3_cow)/2, cap_f4=(f4_pig+f4_cow)/2)
    }
  }
  if(optimization=='전체시설균등') {
    eval_sol <- eval_sol %>% arrange(desc(cap_avg),desc(cap_f1),desc(cap_f2),desc(cap_f3),desc(cap_f4),desc(sprd_sum))
  } else if(optimization=='도축장중심') {
    eval_sol <- eval_sol %>% arrange(desc(cap_f1),desc(cap_avg),desc(cap_f2),desc(cap_f3),desc(cap_f4),desc(sprd_sum))
  } else if(optimization=='사료공장중심') {
    eval_sol <- eval_sol %>% arrange(desc(cap_f2),desc(cap_avg),desc(cap_f1),desc(cap_f3),desc(cap_f4),desc(sprd_sum))
  } else if(optimization=='종축장중심') {
    eval_sol <- eval_sol %>% arrange(desc(cap_f3),desc(cap_avg),desc(cap_f1),desc(cap_f2),desc(cap_f4),desc(sprd_sum))
  } else { 
    eval_sol <- eval_sol %>% arrange(desc(cap_f4),desc(cap_avg),desc(cap_f1),desc(cap_f2),desc(cap_f3),desc(sprd_sum))
  }
  return(eval_sol)
} 
  
if(type=='hpai') {
  facility_list <- c('도계/도압장','사료공장','종축장','분뇨처리장')
} else if(type=='fmd') {
  facility_list <- c('도축장','사료공장','종축장','분뇨처리장')
}

# 권역 산출 파트 시작 
if(nrow(na.omit(brk.place[,1:2]))==1) {
  result_list <- opt_clu_func(type,species,tb_adm_adj,tb_adm_adj_long,brk.place[1,1],fac_capa_addr,farm_use_fac_addr,addr_trmat) 
  eval_sol <- result_list[[1]]
  final_sol_list <- result_list[[2]]
  ### 우선순위 케이스별 최적 권역 선정 
  eval_sol <- opt_capa_rank(type,species,eval_sol)
  breakout_independence_rates <- data.frame(facility=facility_list,self_reliance=c(eval_sol$cap_f1[1],eval_sol$cap_f2[1],eval_sol$cap_f3[1],eval_sol$cap_f4[1]))  
  cluster_list <- final_sol_list[,c(1,(eval_sol[1,1])+1)]
  colnames(cluster_list)[2] <- 'optimal_cluster'
  breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
  breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
  # print(cluster_list[cluster_list$optimal_cluster==1,])
  
} else if(nrow(na.omit(brk.place[,1:2]))==2) {
  result_list <- opt_clu_func(type,species,tb_adm_adj,tb_adm_adj_long,brk.place[1,1],fac_capa_addr,farm_use_fac_addr,addr_trmat) 
  eval_sol1 <- result_list[[1]]
  final_sol_list1 <- result_list[[2]]
  eval_sol1 <- opt_capa_rank(type,species,eval_sol1)
  result_list <- opt_clu_func(type,species,tb_adm_adj,tb_adm_adj_long,brk.place[2,1],fac_capa_addr,farm_use_fac_addr,addr_trmat) 
  eval_sol2 <- result_list[[1]]
  final_sol_list2 <- result_list[[2]]
  eval_sol2 <- opt_capa_rank(type,species,eval_sol2)
  
  breakout_independence_rates <- data.frame(facility=facility_list,self_reliance=c((eval_sol1$cap_f1[1]+eval_sol2$cap_f1[1])/2,(eval_sol1$cap_f2[1]+eval_sol2$cap_f2[1])/2,(eval_sol1$cap_f3[1]+eval_sol2$cap_f3[1])/2,(eval_sol1$cap_f4[1]+eval_sol2$cap_f4[1])/2))  
  cluster_tmp <- cbind(final_sol_list1[,c(1,(eval_sol1[1,1])+1)],final_sol_list2[,c(1,(eval_sol2[1,1])+1)])
  cluster_tmp$optimal_cluster <- as.integer(as.logical(cluster_tmp[,2]) | as.logical(cluster_tmp[,4]))
  cluster_list <- cluster_tmp[,c(1,5)]
  breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
  breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
  # print(cluster_list[cluster_list$optimal_cluster==1,])
} else if(nrow(na.omit(brk.place[,1:2]))==3) {
  result_list <- opt_clu_func(type,species,tb_adm_adj,tb_adm_adj_long,brk.place[1,1],fac_capa_addr,farm_use_fac_addr,addr_trmat) 
  eval_sol1 <- result_list[[1]]
  final_sol_list1 <- result_list[[2]]
  eval_sol1 <- opt_capa_rank(type,species,eval_sol1)
  result_list <- opt_clu_func(type,species,tb_adm_adj,tb_adm_adj_long,brk.place[2,1],fac_capa_addr,farm_use_fac_addr,addr_trmat) 
  eval_sol2 <- result_list[[1]]
  final_sol_list2 <- result_list[[2]]
  eval_sol2 <- opt_capa_rank(type,species,eval_sol2)
  
  result_list <- opt_clu_func(type,species,tb_adm_adj,tb_adm_adj_long,brk.place[3,1],fac_capa_addr,farm_use_fac_addr,addr_trmat) 
  eval_sol3 <- result_list[[1]]
  final_sol_list3 <- result_list[[2]]
  eval_sol3 <- opt_capa_rank(type,species,eval_sol3)

  breakout_independence_rates <- data.frame(facility=facility_list,self_reliance=c((eval_sol1$cap_f1[1]+eval_sol2$cap_f1[1]+eval_sol3$cap_f1[1])/3,(eval_sol1$cap_f2[1]+eval_sol2$cap_f2[1]+eval_sol3$cap_f2[1])/3,(eval_sol1$cap_f3[1]+eval_sol2$cap_f3[1]+eval_sol3$cap_f3[1])/3,(eval_sol1$cap_f4[1]+eval_sol2$cap_f4[1]+eval_sol3$cap_f4[1])/3))  
  cluster_tmp <- cbind(final_sol_list1[,c(1,(eval_sol1[1,1])+1)],final_sol_list2[,c(1,(eval_sol2[1,1])+1)],final_sol_list3[,c(1,(eval_sol3[1,1]+1))])
  cluster_tmp$optimal_cluster <- as.integer(as.logical(cluster_tmp[,2]) | as.logical(cluster_tmp[,4]) | as.logical(cluster_tmp[,6]))
  cluster_list <- cluster_tmp[,c(1,7)]
  breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
  breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
  # print(cluster_list[cluster_list$optimal_cluster==1,])
}

breakout_independence_rates$self_reliance <- breakout_independence_rates$self_reliance/100  
return(list(breakout_optimization_results, breakout_independence_rates))
}

