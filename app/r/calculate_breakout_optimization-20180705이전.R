
# install.packages("dbConnect") # R 설치 폴더에 필요한 library 사전설치 필요. R cmd창 실행 후 install.packages("dbConnect")
library(dbConnect)
library(dplyr)
library(tidyr)

productionConnection <- function() {
  conn <- dbConnect(dbDriver("MySQL"),dbname = 'rapse',host = "10.0.2.2",user = "rapse_dlqldbwj",password = "CZwAfcWizT7qtkaDDQz", port = 33060 )
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

# type <- 'fmd'; species <- '01'; weights <- '1111111' 
# places <- list('경상북도_상주시|2018-03-21', '서울특별시|2018-03-22', '서울특별시|2018-03-23')
# optimization <- '전체시설균등'
# tt <- getResult('fmd','01','1111111',list('전라북도_익산시|2018-03-21', '서울특별시|2018-03-22', '서울특별시|2018-03-23'),'전체시설균등')
# aa <- tt[[1]]
# bb <- tt[[2]]

getResult <- function(type, species, weights, places, optimization) {
  # print(type) # 'fmd' / 'hpai'
  # print(species) # '10' / '01' / '11'
  # print(weights) # '0000000' ~ '5555555' 
  # print(places) # list('서울특별시|2018-03-21', '서울특별시|2018-03-21', '서울특별시|2018-03-21')
  # print(optimization) # '전체시설균등' / '도축장 중심' / '사료공장 중심' / '종축장 중심'  
  # places <- list('충청북도_진천군|2018-03-21', '서울특별시|2018-03-22', '서울특별시|2018-03-23')
 
  conn <- getConnection()

  blk.place <- data.frame(address=rep(NA,3),date=rep(NA,3))
  for(i in 1:3) {
    blk.place[i,1] <- strsplit(as.character(places[1]),split='|',fixed=T)[[1]][1]
    blk.place[i,2] <- strsplit(as.character(places[1]),split='|',fixed=T)[[1]][2]
  } 
  
  # type<-'fmd'; species<-'10'
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
  # fac_capa <- dbGetQuery(conn, "select * from fac_capa")
  # farm_use_fac <- dbGetQuery(conn, "select * from farm_use_fac")
  fac_capa_addr <- dbGetQuery(conn, "select * from fac_capa_addr")
  farm_use_fac_addr <- dbGetQuery(conn, "select * from farm_use_fac_addr")
  dbDisconnect(conn)
  # weights <- '1234567'
  trans_sum <- cbind(trans_tb[,1:2],data.frame(trans_tb[,3]*as.numeric(substr(weights,1,1))+trans_tb[,4]*as.numeric(substr(weights,2,2))+trans_tb[,5]*as.numeric(substr(weights,3,3))+trans_tb[,6]*as.numeric(substr(weights,4,4))+
                                                 trans_tb[,7]*as.numeric(substr(weights,5,5))+trans_tb[,8]*as.numeric(substr(weights,6,6))+trans_tb[,9]*as.numeric(substr(weights,7,7))))
  colnames(trans_sum)[3] <- 'freq'
  addr_trmat <- spread(trans_sum,addr_to,freq,fill=0)
  mat1 <- as.matrix(addr_trmat[,-1])/max(as.matrix(addr_trmat[,-1]))  # 최대값으로 전체를 나눠서 0~1사이 값으로...
  brk.out <- addr_trmat[,1:2]
  colnames(brk.out) <- c('city','breaks')
  brk.out[,2] <- 0 
  brk.out[brk.out$city==as.character(blk.place[1,1]),2] <- 1
  for(i in 3:22){
    brk.out[,i] <- t(t(brk.out[,i-1]) %*% mat1)
  }
  colnames(brk.out)[3:22] <- paste('lv',seq(1,20,1),sep='')
  breakout_optimization_results <- brk.out[,c(1,3)] 
  colnames(breakout_optimization_results) <- c('address','spread_probability')
  # Exception: Data must be 1-dimensional 문제 해결
  breakout_optimization_results$spread_probability <- as.numeric(breakout_optimization_results$spread_probability)
  
  tb_adm_adj <- tb_adm_adj %>% spread(address2,adj)
  colnames(tb_adm_adj)[2:163] <- paste('V',1:162,sep='')

  near1 <- tb_adm_adj[which(tb_adm_adj[tb_adm_adj$address==blk.place[1,1],]==1)-1,1] # 최초발생지와 인접지역 필터링
  near1.df <- data.frame(address=near1,near_rank=1)      # 최초발생지 인접지역을 1로 코딩
  near1.df$address <- as.character(near1.df$address)
  near1.df[nrow(near1.df)+1,] <- c(blk.place[1,1],0)
  
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
  # nrow(near2.df[near2.df$near_rank==1,])
  
  # # 발생지역만으로 자립도 계산 : rank=0
  #   capa_sum0 <- fac_capa_clu[fac_capa_clu$near_rank==0,] 
  #   use_sum0 <- farm_use_fac_clu[farm_use_fac_clu$near_rank==0,]
  #   
  #   ind_rate0 <- (round((capa_sum0[,3:18]-use_sum[,3:18]) / use_sum0[,3:18],3)+1)*100
  #   col_name <- colnames(ind_rate0)
  #   ind_rate0 <- as.data.frame(ifelse(ind_rate0>100,100,ind_rate0))
  #   colnames(ind_rate0) <- col_name
  #   
  # # 발생 인근지역으로 자립도 계산 : rank=1
  #   capa_sum2 <- apply(fac_capa_clu[fac_capa_clu$near_rank==1,][,3:18],2,sum)
  #   use_sum2 <- apply(farm_use_fac_clu[farm_use_fac_clu$near_rank==1,][,3:18],2,sum)
  #   ind_rate <- (round((capa_sum2-use_sum2) / use_sum2,3)+1)*100
  #   col_name <- colnames(ind_rate)
  #   ind_rate <- as.data.frame(ifelse(ind_rate>100,100,ind_rate))
  #   colnames(ind_rate) <- col_name
    
  # 입력된 지역리스트로 자립도 계산함수 
  cal_ind_rate <- function(dat1,dat2){
    capa_sum <- apply(dat1,2,sum)
    use_sum <- apply(dat2,2,sum)
    ind_rate <- (round((capa_sum/1.5-use_sum) / use_sum,3)+1)*100
    col_name <- colnames(ind_rate)
    ind_rate <- ifelse(ind_rate>100,100,ind_rate)
    colnames(ind_rate) <- col_name
    return(as.data.frame(t(ind_rate)))
  }
  
  # 인접지역 대상 자립도 계산 
  len_clu <- nrow(near2.df[near2.df$near_rank==1,])
  tmp <- NA
  for(i in 1:(len_clu-1)){
    tt <- as.data.frame(t(combn(1:len_clu, i)))
    na.df <- data.frame(matrix(data = NA, nrow = nrow(tt), ncol = len_clu-i))
    ttt <- cbind(tt,na.df)
    colnames(ttt) <- paste('V',1:len_clu,sep='')
    tmp <- rbind(tmp,ttt)
  }
  case_list <- tmp
  case_list[(nrow(case_list)+1),] <- 1:len_clu
  
  capa_list <- fac_capa_clu[fac_capa_clu$near_rank==1,]
  capa_list$no <- 1:nrow(capa_list)
  use_list <- farm_use_fac_clu[farm_use_fac_clu$near_rank==1,]
  use_list$no <- 1:nrow(use_list)
  
  case_list2 <- data.frame(case_list,f1_chi=NA,f2_chi=NA,f3_chi=NA,f4_chi=NA,f1_duc=NA,f2_duc=NA,f3_duc=NA,f4_duc=NA,f1_pig=NA,f2_pig=NA,f3_pig=NA,f4_pig=NA,f1_cow=NA,f2_cow=NA,f3_cow=NA,f4_cow=NA)
  fac_sel <- fac_capa_clu[fac_capa_clu$near_rank==0,][,3:18]  
  use_sel <- farm_use_fac_clu[farm_use_fac_clu$near_rank==0,][,3:18]
  tmp <- cal_ind_rate(fac_sel,use_sel)
  tmp[is.na(tmp)] <- 100
  case_list2[1,len_clu:(len_clu+16)] <- tmp
  
  for(i in 2:nrow(case_list)){
    fac_sel <- capa_list %>% filter(no %in% as.numeric(case_list[i,])) %>% select(3:18)
    fac_sel <- rbind(fac_sel,fac_capa_clu[fac_capa_clu$near_rank==0,][,3:18])  
    use_sel <- use_list %>% filter(no %in% as.numeric(case_list[i,])) %>% select(3:18)  
    use_sel <- rbind(use_sel,farm_use_fac_clu[farm_use_fac_clu$near_rank==0,][,3:18])  
    
    tmp <- cal_ind_rate(fac_sel,use_sel)
    tmp[is.na(tmp)] <- 100
    case_list2[i,len_clu:(len_clu+16)] <- tmp
  }
  
  case_list2$num_city <- len_clu - apply(case_list2[,1:len_clu],1,FUN = function(x) sum(is.na(x)))
  
  ## 인접 2단계 확장 
  len_clu <- nrow(near2.df[near2.df$near_rank==1,])
  len_clu2 <- nrow(near2.df[near2.df$near_rank==2,])
  tmp <- NA
  for(i in 1:3){  # 속도 문제로 3개까지만 검토
    tt <- as.data.frame(t(combn(1:len_clu2, i)))
    na.df <- data.frame(matrix(data = NA, nrow = nrow(tt), ncol = len_clu-i))
    ttt <- cbind(tt,na.df)
    colnames(ttt) <- paste('V',1:len_clu,sep='')
    tmp <- rbind(tmp,ttt)
  }
  
  case2_list <- tmp[-1,]
  
  capa2_list <- fac_capa_clu[fac_capa_clu$near_rank==2,]
  capa2_list$no <- 1:nrow(capa2_list)
  use2_list <- farm_use_fac_clu[farm_use_fac_clu$near_rank==2,]
  use2_list$no <- 1:nrow(use2_list)
  
  case2_list2 <- data.frame(case2_list,f1_chi=NA,f2_chi=NA,f3_chi=NA,f4_chi=NA,f1_duc=NA,f2_duc=NA,f3_duc=NA,f4_duc=NA,f1_pig=NA,f2_pig=NA,f3_pig=NA,f4_pig=NA,f1_cow=NA,f2_cow=NA,f3_cow=NA,f4_cow=NA)
  
  for(i in 1:nrow(case2_list)){
    fac_sel <- capa_list %>% filter(no %in% as.numeric(case_list[i,])) %>% select(3:18)
    fac_sel <- rbind(fac_sel,fac_capa_clu[fac_capa_clu$near_rank<=1,][,3:18])  
    use_sel <- use_list %>% filter(no %in% as.numeric(case_list[i,])) %>% select(3:18)  
    use_sel <- rbind(use_sel,farm_use_fac_clu[farm_use_fac_clu$near_rank<=1,][,3:18])  
    
    tmp <- cal_ind_rate(fac_sel,use_sel)
    tmp[is.na(tmp)] <- 100
    case2_list2[i,len_clu:(len_clu+16)] <- tmp
  }
  case2_list2$num_city <- len_clu - apply(case2_list2[,1:len_clu],1,FUN = function(x) sum(is.na(x))) 
  
  ### 우선순위 케이스별 최적 권역 선정 
  
  if(type=='hpai' & species=='10' & optimization=='전체시설균등') { ####### 닭 케이스
    case_list3 <- case_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(avg_chi),desc(f1_chi),desc(f2_chi),desc(f3_chi),desc(f4_chi),desc(desc(num_city)))
    case2_list3 <- case2_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(avg_chi),desc(f1_chi),desc(f2_chi),desc(f3_chi),desc(f4_chi),desc(desc(num_city)))
    if(case_list3$avg_chi[1] >= case2_list3$avg_chi[1]){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_chi[1],case_list3$f2_chi[1],case_list3$f3_chi[1],NA,case_list3$f4_chi[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_chi[1],case2_list3$f2_chi[1],case2_list3$f3_chi[1],NA,case2_list3$f4_chi[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='10' & optimization=='도축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f1_chi),desc(avg_chi),desc(f2_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f1_chi),desc(avg_chi),desc(f2_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    if(case_list3$f1_chi[1] >= case2_list3$f1_chi[1]){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_chi[1],case_list3$f2_chi[1],case_list3$f3_chi[1],NA,case_list3$f4_chi[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_chi[1],case2_list3$f2_chi[1],case2_list3$f3_chi[1],NA,case2_list3$f4_chi[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='10' & optimization=='사료공장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f2_chi),desc(avg_chi),desc(f1_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f2_chi),desc(avg_chi),desc(f1_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    if(case_list3$f2_chi[1] >= case2_list3$f2_chi[1]){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_chi[1],case_list3$f2_chi[1],case_list3$f3_chi[1],NA,case_list3$f4_chi[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_chi[1],case2_list3$f2_chi[1],case2_list3$f3_chi[1],NA,case2_list3$f4_chi[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='10' & optimization=='종축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f3_chi),desc(avg_chi),desc(f1_chi),desc(f2_chi),desc(f4_chi),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f3_chi),desc(avg_chi),desc(f1_chi),desc(f2_chi),desc(f4_chi),desc(num_city))
    if(case_list3$f3_chi[1] >= case2_list3$f3_chi[1]){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_chi[1],case_list3$f2_chi[1],case_list3$f3_chi[1],NA,case_list3$f4_chi[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_chi[1],case2_list3$f2_chi[1],case2_list3$f3_chi[1],NA,case2_list3$f4_chi[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='01' & optimization=='전체시설균등') { ###### 오리 케이스 
    case_list3 <- case_list2 %>% mutate(avg_duc=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2)) %>% arrange(desc(avg_duc),desc(f1_duc),desc(f2_duc),desc(f3_duc),desc(f4_duc),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_duc=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2)) %>% arrange(desc(avg_duc),desc(f1_duc),desc(f2_duc),desc(f3_duc),desc(f4_duc),desc(num_city))
    if(case_list3$avg_duc >= case2_list3$avg_duc){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_duc[1],case_list3$f2_duc[1],case_list3$f3_duc[1],NA,case_list3$f4_duc[1]))
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_duc[1],case2_list3$f2_duc[1],case2_list3$f3_duc[1],NA,case2_list3$f4_duc[1]))
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='01' & optimization=='도축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_duc=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2)) %>% arrange(desc(f1_duc),desc(avg_duc),desc(f2_duc),desc(f3_duc),desc(f4_duc),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_duc=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2)) %>% arrange(desc(f1_duc),desc(avg_duc),desc(f2_duc),desc(f3_duc),desc(f4_duc),desc(num_city))
    if(case_list3$f1_duc >= case2_list3$f1_duc){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_duc[1],case_list3$f2_duc[1],case_list3$f3_duc[1],NA,case_list3$f4_duc[1]))
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_duc[1],case2_list3$f2_duc[1],case2_list3$f3_duc[1],NA,case2_list3$f4_duc[1]))
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='01' & optimization=='사료공장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_duc=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2)) %>% arrange(desc(f2_duc),desc(avg_duc),desc(f1_duc),desc(f3_duc),desc(f4_duc),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_duc=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2)) %>% arrange(desc(f2_duc),desc(avg_duc),desc(f1_duc),desc(f3_duc),desc(f4_duc),desc(num_city))
    if(case_list3$f2_duc >= case2_list3$f2_duc){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_duc[1],case_list3$f2_duc[1],case_list3$f3_duc[1],NA,case_list3$f4_duc[1]))
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_duc[1],case2_list3$f2_duc[1],case2_list3$f3_duc[1],NA,case2_list3$f4_duc[1]))
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='01' & optimization=='종축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_duc=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2)) %>% arrange(desc(f3_duc),desc(avg_duc),desc(f1_duc),desc(f2_duc),desc(f4_duc),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_duc=round((f1_duc+f2_duc+f3_duc+f4_duc)/4,2)) %>% arrange(desc(f3_duc),desc(avg_duc),desc(f1_duc),desc(f2_duc),desc(f4_duc),desc(num_city))
    if(case_list3$f3_duc >= case2_list3$f3_duc){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_duc[1],case_list3$f2_duc[1],case_list3$f3_duc[1],NA,case_list3$f4_duc[1]))
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_duc[1],case2_list3$f2_duc[1],case2_list3$f3_duc[1],NA,case2_list3$f4_duc[1]))
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='11' & optimization=='전체시설균등') { ####### 닭+오리 케이스
    case_list3 <- case_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(avg_chi),desc(f1_chi),desc(f2_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(avg_chi),desc(f1_chi),desc(f2_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    if(case_list3$avg_chi[1] >= case2_list3$avg_chi[1]){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_chi[1],case_list3$f2_chi[1],case_list3$f3_chi[1],NA,case_list3$f4_chi[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_chi[1],case2_list3$f2_chi[1],case2_list3$f3_chi[1],NA,case2_list3$f4_chi[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='11' & optimization=='도축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f1_chi),desc(avg_chi),desc(f2_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f1_chi),desc(avg_chi),desc(f2_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    if(case_list3$f1_chi[1] >= case2_list3$f1_chi[1]){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_chi[1],case_list3$f2_chi[1],case_list3$f3_chi[1],NA,case_list3$f4_chi[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_chi[1],case2_list3$f2_chi[1],case2_list3$f3_chi[1],NA,case2_list3$f4_chi[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='11' & optimization=='사료공장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f2_chi),desc(avg_chi),desc(f1_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f2_chi),desc(avg_chi),desc(f1_chi),desc(f3_chi),desc(f4_chi),desc(num_city))
    if(case_list3$f2_chi[1] >= case2_list3$f2_chi[1]){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_chi[1],case_list3$f2_chi[1],case_list3$f3_chi[1],NA,case_list3$f4_chi[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_chi[1],case2_list3$f2_chi[1],case2_list3$f3_chi[1],NA,case2_list3$f4_chi[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='hpai' & species=='11' & optimization=='종축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f3_chi),desc(avg_chi),desc(f1_chi),desc(f2_chi),desc(f4_chi),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_chi=round((f1_chi+f2_chi+f3_chi+f4_chi)/4,2)) %>% arrange(desc(f3_chi),desc(avg_chi),desc(f1_chi),desc(f2_chi),desc(f4_chi),desc(num_city))
    if(case_list3$f3_chi[1] >= case2_list3$f3_chi[1]){
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case_list3$f1_chi[1],case_list3$f2_chi[1],case_list3$f3_chi[1],NA,case_list3$f4_chi[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도계/도압장','사료공장','종축장','부화장','분뇨처리장'),self_reliance=c(case2_list3$f1_chi[1],case2_list3$f2_chi[1],case2_list3$f3_chi[1],NA,case2_list3$f4_chi[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  }  else if(type=='fmd' & species=='10' & optimization=='전체시설균등') { ####### 돼지 케이스
    case_list3 <- case_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(avg_pig),desc(f1_pig),desc(f2_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(avg_pig),desc(f1_pig),desc(f2_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    if(case_list3$avg_pig[1] >= case2_list3$avg_pig[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_pig[1],case_list3$f2_pig[1],case_list3$f3_pig[1],NA,case_list3$f4_pig[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_pig[1],case2_list3$f2_pig[1],case2_list3$f3_pig[1],NA,case2_list3$f4_pig[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='fmd' & species=='10' & optimization=='도축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f1_pig),desc(avg_pig),desc(f2_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f1_pig),desc(avg_pig),desc(f2_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    if(case_list3$f1_pig[1] >= case2_list3$f1_pig[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_pig[1],case_list3$f2_pig[1],case_list3$f3_pig[1],NA,case_list3$f4_pig[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_pig[1],case2_list3$f2_pig[1],case2_list3$f3_pig[1],NA,case2_list3$f4_pig[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }  
  } else if(type=='fmd' & species=='10' & optimization=='사료공장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f2_pig),desc(avg_pig),desc(f1_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f2_pig),desc(avg_pig),desc(f1_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    if(case_list3$f2_pig[1] >= case2_list3$f2_pig[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_pig[1],case_list3$f2_pig[1],case_list3$f3_pig[1],NA,case_list3$f4_pig[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_pig[1],case2_list3$f2_pig[1],case2_list3$f3_pig[1],NA,case2_list3$f4_pig[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }  
  } else if(type=='fmd' & species=='10' & optimization=='종축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f3_pig),desc(avg_pig),desc(f1_pig),desc(f2_pig),desc(f4_pig),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f3_pig),desc(avg_pig),desc(f1_pig),desc(f2_pig),desc(f4_pig),desc(num_city))
    if(case_list3$f3_pig[1] >= case2_list3$f3_pig[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_pig[1],case_list3$f2_pig[1],case_list3$f3_pig[1],NA,case_list3$f4_pig[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_pig[1],case2_list3$f2_pig[1],case2_list3$f3_pig[1],NA,case2_list3$f4_pig[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }  
  } else if(type=='fmd' & species=='01' & optimization=='전체시설균등') { ###### 소 케이스 
    case_list3 <- case_list2 %>% mutate(avg_cow=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2)) %>% arrange(desc(avg_cow),desc(f1_cow),desc(f2_cow),desc(f3_cow),desc(f4_cow),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_cow=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2)) %>% arrange(desc(avg_cow),desc(f1_cow),desc(f2_cow),desc(f3_cow),desc(f4_cow),desc(num_city))
    if(case_list3$avg_cow[1] >= case2_list3$avg_cow[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_cow[1],case_list3$f2_cow[1],case_list3$f3_cow[1],NA,case_list3$f4_cow[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_cow[1],case2_list3$f2_cow[1],case2_list3$f3_cow[1],NA,case2_list3$f4_cow[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='fmd' & species=='01' & optimization=='도축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_cow=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2)) %>% arrange(desc(f1_cow),desc(avg_cow),desc(f2_cow),desc(f3_cow),desc(f4_cow),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_cow=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2)) %>% arrange(desc(f1_cow),desc(avg_cow),desc(f2_cow),desc(f3_cow),desc(f4_cow),desc(num_city))
    if(case_list3$f1_cow[1] >= case2_list3$f1_cow[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_cow[1],case_list3$f2_cow[1],case_list3$f3_cow[1],NA,case_list3$f4_cow[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_cow[1],case2_list3$f2_cow[1],case2_list3$f3_cow[1],NA,case2_list3$f4_cow[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='fmd' & species=='01' & optimization=='사료공장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_cow=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2)) %>% arrange(desc(f2_cow),desc(avg_cow),desc(f1_cow),desc(f3_cow),desc(f4_cow),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_cow=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2)) %>% arrange(desc(f2_cow),desc(avg_cow),desc(f1_cow),desc(f3_cow),desc(f4_cow),desc(num_city))
    if(case_list3$f2_cow[1] >= case2_list3$f2_cow[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_cow[1],case_list3$f2_cow[1],case_list3$f3_cow[1],NA,case_list3$f4_cow[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_cow[1],case2_list3$f2_cow[1],case2_list3$f3_cow[1],NA,case2_list3$f4_cow[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='fmd' & species=='01' & optimization=='종축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_cow=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2)) %>% arrange(desc(f3_cow),desc(avg_cow),desc(f1_cow),desc(f2_cow),desc(f4_cow),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_cow=round((f1_cow+f2_cow+f3_cow+f4_cow)/4,2)) %>% arrange(desc(f3_cow),desc(avg_cow),desc(f1_cow),desc(f2_cow),desc(f4_cow),desc(num_city))
    if(case_list3$f3_cow[1] >= case2_list3$f3_cow[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_cow[1],case_list3$f2_cow[1],case_list3$f3_cow[1],NA,case_list3$f4_cow[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_cow[1],case2_list3$f2_cow[1],case2_list3$f3_cow[1],NA,case2_list3$f4_cow[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='fmd' & species=='11' & optimization=='전체시설균등') { ####### 돼지+소 케이스
    case_list3 <- case_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(avg_pig),desc(f1_pig),desc(f2_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(avg_pig),desc(f1_pig),desc(f2_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    if(case_list3$avg_pig[1] >= case2_list3$avg_pig[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_pig[1],case_list3$f2_pig[1],case_list3$f3_pig[1],NA,case_list3$f4_pig[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_pig[1],case2_list3$f2_pig[1],case2_list3$f3_pig[1],NA,case2_list3$f4_pig[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }
  } else if(type=='fmd' & species=='11' & optimization=='도축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f1_pig),desc(avg_pig),desc(f2_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f1_pig),desc(avg_pig),desc(f2_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    if(case_list3$f1_pig[1] >= case2_list3$f1_pig[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_pig[1],case_list3$f2_pig[1],case_list3$f3_pig[1],NA,case_list3$f4_pig[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_pig[1],case2_list3$f2_pig[1],case2_list3$f3_pig[1],NA,case2_list3$f4_pig[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }  
  } else if(type=='fmd' & species=='11' & optimization=='사료공장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f2_pig),desc(avg_pig),desc(f1_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f2_pig),desc(avg_pig),desc(f1_pig),desc(f3_pig),desc(f4_pig),desc(num_city))
    if(case_list3$f2_pig[1] >= case2_list3$f2_pig[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_pig[1],case_list3$f2_pig[1],case_list3$f3_pig[1],NA,case_list3$f4_pig[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_pig[1],case2_list3$f2_pig[1],case2_list3$f3_pig[1],NA,case2_list3$f4_pig[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }  
  } else if(type=='fmd' & species=='11' & optimization=='종축장 중심') {
    case_list3 <- case_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f3_pig),desc(avg_pig),desc(f1_pig),desc(f2_pig),desc(f4_pig),desc(num_city))
    case2_list3 <- case2_list2 %>% mutate(avg_pig=round((f1_pig+f2_pig+f3_pig+f4_pig)/4,2)) %>% arrange(desc(f3_pig),desc(avg_pig),desc(f1_pig),desc(f2_pig),desc(f4_pig),desc(num_city))
    if(case_list3$f3_pig[1] >= case2_list3$f3_pig[1]){
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case_list3$f1_pig[1],case_list3$f2_pig[1],case_list3$f3_pig[1],NA,case_list3$f4_pig[1]))  
      cluster_list <- capa_list %>% filter(no %in% case_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=blk.place[1,1],optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    } else {
      breakout_independence_rates <- data.frame(facility=c('도축장','사료공장','종축장','AI센터','분뇨처리장'),self_reliance=c(case2_list3$f1_pig[1],case2_list3$f2_pig[1],case2_list3$f3_pig[1],NA,case2_list3$f4_pig[1]))  
      cluster_list <- capa2_list %>% filter(no %in% case2_list3[1,1:len_clu]) %>% select(address) %>% mutate(optimal_cluster=1)
      cluster_list <- rbind(cluster_list,data.frame(address=c(blk.place[1,1],as.character(capa_list$address)),optimal_cluster=1))
      breakout_optimization_results <- merge(breakout_optimization_results,cluster_list,by='address',all.x=T)
      breakout_optimization_results[is.na(breakout_optimization_results$optimal_cluster),3] <- 0
    }  
  }

  breakout_independence_rates$self_reliance <- breakout_independence_rates$self_reliance/100  
  return(list(breakout_optimization_results, breakout_independence_rates))
}

