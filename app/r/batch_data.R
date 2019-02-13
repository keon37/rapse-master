library(dbConnect)

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

batchData <- function() {
  conn <- productionConnection()
  # table : job
  # 가장 마지막 data row를 가져와서 JOB_STATE, END_DT를 업데이트 해야 함
  # JOB_STATE : r -> running , s -> success, f -> failed
  # END_DT : datetime 형식  
  dbDisconnect(conn)
}

batchData()