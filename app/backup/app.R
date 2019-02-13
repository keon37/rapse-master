# in terminal : defaults write org.R-project.R force.LANG en_US.UTF-8

# install.packages("shiny")
# install.packages("shinydashboard")
# install.packages("reshape2")
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("dbConnect")
# install.packages("leaflet")
# install.packages("maptools")
# install.packages("rgeos")
library(shiny)
library(shinydashboard)
library(reshape2)
library(dplyr)
library(tidyr)
library(dbConnect)
library(leaflet)
library(maptools)
library(reshape2)
# library(shinyjs)
# library(ggplot2)

ui <- dashboardPage(
  dashboardHeader(title = "방역 권역화 시나리오",
                  dropdownMenu(type = "messages",
                               messageItem(
                                 from = "Sales Dept",
                                 message = "Sales are steady this month."
                               ),
                               messageItem(
                                 from = "New User",
                                 message = "How do I register?",
                                 icon = icon("question"),
                                 time = "13:45"
                               ),
                               messageItem(
                                 from = "Support",
                                 message = "The new server is ready.",
                                 icon = icon("life-ring"),
                                 time = "2014-12-01"
                               )
                  ),
                  dropdownMenu(type = "notifications",
                               notificationItem(
                                 text = "5 new users today",
                                 icon("users")
                               ),
                               notificationItem(
                                 text = "12 items delivered",
                                 icon("truck"),
                                 status = "success"
                               ),
                               notificationItem(
                                 text = "Server load at 86%",
                                 icon = icon("exclamation-triangle"),
                                 status = "warning"
                               )
                  ),
                  dropdownMenu(type = "tasks", badgeStatus = "success",
                               taskItem(value = 90, color = "green",
                                        "Documentation"
                               ),
                               taskItem(value = 17, color = "aqua",
                                        "Project X"
                               ),
                               taskItem(value = 75, color = "yellow",
                                        "Server deployment"
                               ),
                               taskItem(value = 80, color = "red",
                                        "Overall project"
                               )
                  )
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("발생시 HPAI 시나리오", tabName = "hpai_sc", icon = icon("area-chart")),
      menuItem("발생시 HPAI 차량모니터링", tabName = "hpai_car", icon = icon("area-chart")),
      menuItem("평시 FMD 권역화", tabName = "fmd_cl", icon = icon("area-chart"), badgeLabel = "안전", badgeColor = "green"),
      menuItem("평시 HPAI 권역화", tabName = "hpai_cl", icon = icon("area-chart"), badgeLabel = "위험", badgeColor = "red")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "fmd_cl",
              h3("조건별 FMD 권역화 시나리오"),
              fluidRow(
                box(
                  title = "분석조건입력", status = "warning", solidHeader = TRUE, width = 12,
                  column(3,
                  selectizeInput("lstk_no0",
                                 label = h4("축종"),
                                 choices = list(
                                   "돼지,소" = "LS_hoof",
                                   "돼지" = "LS_hoof",
                                   "소" = "LS_hoof"
                                 ),
                                 multiple = F,
                                 options = list(maxItems = 1, placeholder = '축종을 고르세요')
                  )),
                  column(4,
                  selectizeInput("fieldset0",
                                 label = h4("시설"),
                                 choices = list(
                                   "도축장+사료공장" = "FC_hf_sl_fe",
                                   "도축장+사료공장+종축장" = "FC_hf_sl_fe_br",
                                   "도축장+사료공장+종축장+분뇨처리장" = "FC_hf_sl_fe_br_di"
                                 ),
                                 multiple = F,
                                 options = list(maxItems = 1, placeholder = '방문시설을 고르세요(택1)')
                  )),
                  column(4,
                  sliderInput(inputId = "cluster0",
                              label = "권역화 단계:",
                              min = 1,
                              max = 4,
                              value = 1)
                  ),
                  column(1,
                  actionButton("submit0", "보기")
                )
              )
              ),
              fluidRow(
                box(
                  title = "Cut Score", status = "primary", solidHeader = T, width = 2,
                  collapsible = T, tableOutput("table0"), downloadButton('downloadData0', '원본다운')
                ),
                box(
                  title = "권역화 시나리오", status = "primary", solidHeader = TRUE, width = 10,
                  collapsible = TRUE,
                  leafletOutput("plot0",height = 600)
                  #plotOutput("plot0", height = 800)
                )
              )
      ),

      tabItem(tabName = "hpai_cl",
              h3("조건별 HPAI 권역화 시나리오"),
              fluidRow(
                box(
                  title = "분석조건입력", status = "warning", solidHeader = TRUE, width = 12,
                  column(3,
                         selectizeInput("lstk_no1",
                                        label = h4("축종"),
                                        choices = list(
                                          "닭,오리" = "LS_poul",
                                          "닭" = "LS_poul",
                                          "오리" = "LS_poul"
                                        ),
                                        multiple = F,
                                        options = list(maxItems = 1, placeholder = '축종을 고르세요')
                         )),
                  column(4,
                         selectizeInput("fieldset1",
                                        label = h4("시설"),
                                        choices = list(
                                          "도계장+사료공장" = "FC_pl_sl_fe",
                                          "도계장+사료공장+종축장" = "FC_pl_sl_fe_br",
                                          "도계장+사료공장+종축장+분뇨처리장" = "FC_pl_sl_fe_br_di"
                                        ),
                                        multiple = F,
                                        options = list(maxItems = 1, placeholder = '방문시설을 고르세요(택1)')
                         )),
                  column(4,
                         sliderInput(inputId = "cluster1",
                                     label = "권역화 단계:",
                                     min = 1,
                                     max = 4,
                                     value = 1)
                  ),
                  column(1,
                         actionButton("submit1", "보기")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Cut Score", status = "primary", solidHeader = T, width = 2,
                  collapsible = T, tableOutput("table1"), downloadButton('downloadData1', '원본다운')
                ),
                box(
                  title = "권역화 시나리오", status = "primary", solidHeader = TRUE, width = 10,
                  collapsible = TRUE,
                  leafletOutput("plot1",height = 600)
                )
              )
      ),
      
      tabItem(tabName = "hpai_sc",
              h3("HPAI 발생후 차단방역 권역화 시나리오"),
              fluidRow(
                # box(
                #   title = "조건입력", status = "warning", solidHeader = TRUE, width = 4,
                  column(2, 
                         selectizeInput("lstk_no2",
                                        label = h4("축종"),
                                        choices = list(
                                          "닭,오리" = "LS_poul",
                                          "닭" = "LS_chi",
                                          "오리" = "LS_duc"
                                        ),
                                        multiple = F,
                                        options = list(maxItems = 1, placeholder = '축종을 고르세요')
                         ),
                         selectInput('no_slc2', '도계장', 1:5),
                         selectInput('no_sld2', '도압장', 1:5),  
                         selectInput('no_br12', '종축장', 1:5),
                         selectInput('no_br22', '부화장', 1:5),
                         selectInput('no_fe2', '사료공장', 1:5),
                         selectInput('no_di2', '분뇨처리장', 1:5),
                         sliderInput(inputId = "time2",
                                     label = "발생 후 시간경과:",
                                     min = 1,
                                     max = 20,
                                     value = 1),
                         actionButton("submit2", "보기")
                        ),
                # ),
                box(
                  title = "권역화 시나리오 : 보기버튼을 누른 후 발생지를 클릭 하세요", status = "primary", solidHeader = TRUE, width = 10,
                  collapsible = F,
                column(10, 
                  leafletOutput("plot2",height=800)
                )
                )
              )
      ),
      
      tabItem(tabName = "hpai_car",
              h3("HPAI 발생후 발생지 방문 차량 모니터링"),
              fluidRow(
                # box(
                #   title = "조건입력", status = "warning", solidHeader = TRUE, width = 4,
                column(2, 
                       selectizeInput("lstk_no3",
                                      label = h4("축종"),
                                      choices = list(
                                        "닭,오리" = "LS_poul",
                                        "닭" = "LS_chi",
                                        "오리" = "LS_duc"
                                      ),
                                      multiple = F,
                                      options = list(maxItems = 1, placeholder = '축종을 고르세요')
                       ),
                       selectizeInput('addr3', '주소(동/리)', selected = NULL, choices = list(
                         "경기도" = c(`경기도 포천시 관인면 탄동리` = 'GG1', `경기도 여주시 흥천면 복대리` = 'GG2'),
                         "경상북도" = c(`경상북도 안동시 남선면 이천리` = 'GB1', `경상북도 경산시 진량읍 선화리` = 'GB2'),
                         "전라북도" = c(`전라북도 고창군 흥덕면 치룡리` = 'JB1', `전라북도 익산시 망성면 어량리` = 'JB2'),
                         "전라남도" = c(`전라남도 영암군 삼호읍 난전리` = 'JN1', `전라남도 보성군 보성읍 쾌상리` = 'JN2')
                       ), multiple = T, options = list(maxItems = 1, placeholder = '주소를 검색하세요')),
                       dateInput("brk_date3", label=h4("발생일"), value = "2017-04-30", min = "2017-04-01", max = "2017-04-30",
                                 format = "yyyy-mm-dd", startview = "month", weekstart = 0,
                                 language = "en", width = NULL),
                       sliderInput(inputId = "time3",
                                   label = "발생 전 기간(일):",
                                   min = 1,
                                   max = 21,
                                   value = 1),
                       actionButton("submit3", "보기")
                ),
                # ),
                box(
                  title = "발생지역 방문차량 모니터링", status = "primary", solidHeader = TRUE, width = 10,
                  collapsible = F,
                  column(10, 
                         leafletOutput("plot3",height=800)
                  )
                )
              )
      )
      
    )
  )
)


server <- function(input, output) {
  observeEvent(input$submit0, {
    if (is.na(input$fieldset0)==1) print("최소한 한 개의 요소는 골라야 합니다.")
    else {
      if(input$fieldset0 == 'FC_hf_sl_fe'){
        # ??????? start
        # 
        col.idx <- 12
        sc.idx <- 5
        # ??????? end
      } else if(input$fieldset0 == 'FC_hf_sl_fe_br'){
        col.idx <- 16       
        sc.idx <- 6
      } else if(input$fieldset0 == 'FC_hf_sl_fe_br_di'){
        col.idx <- 20       
        sc.idx <- 7
      }
        conn <- dbConnect(dbDriver("MySQL"),dbname = 'livestock',host = "147.46.229.85",user = "ais",password = "ezfarm3414" )
        dbGetQuery( conn, "set names 'utf8'" )
        score30 <- dbGetQuery(conn, "SELECT * FROM cut_score")
        kor_adm2b <- dbGetQuery(conn, "SELECT * FROM kor_adm2b")
        # 시설물 gis 좌표
        gis_fac <- dbGetQuery(conn, "SELECT * FROM gis_fac")
        dbDisconnect(conn)
        # ??????? start
        setwd("/Users/bpk/Works/ezfarm/map/KOR_adm_shp")
        kor_LL <- readShapePoly("KOR_adm2")
        kor_adm2b <- kor_adm2b[,c(1:19,(19+col.idx+input$cluster0))]
        cut.score <- score30[,c(1,sc.idx)]
        colnames(kor_adm2b)[20] <- 'cluster'
        colnames(cut.score)[2] <- 'score'
        # 울릉도는 항상 클러스터 예외처리 필요
        kor_adm2b[which(kor_adm2b$cluster==kor_adm2b[kor_adm2b$NL_NAME_2=='울릉군','cluster']),'cluster'] <- NA
        kor_LL@data <- kor_adm2b
        print("hi")
        factpal <- colorFactor(topo.colors(5), domain = NULL)
        pal <- colorFactor(c("red",'orange','navy','blue','violet','black'), domain = c("출하",'분뇨/비료','사료', "종축",'검정/소독','철새/기타'))        
        output$plot0 <- renderLeaflet({
          leaflet() %>% addTiles() %>% setView(lng=127.8494, lat=36.45452,zoom=7)
        })
        leafletProxy('plot0') %>% addPolygons(data=kor_LL, weight=1, color=~factpal(kor_LL$cluster), smoothFactor = 1.0, opacity = 1, fillOpacity = 0.5, group='권역Layer')
        shp.cl <- unionSpatialPolygons(kor_LL, kor_LL$cluster)
        leafletProxy('plot0') %>% addPolygons(data=shp.cl, weight = 1, opacity = 1, color = 'white', dashArray = "3", fillOpacity = 0, highlightOptions = highlightOptions(color = "red", weight = 5,bringToFront = TRUE))
        leafletProxy('plot0')%>% addCircleMarkers(data=gis_fac[gis_fac$wide=='출하',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                         radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                         color = 'red',
                         stroke = FALSE, fillOpacity = 1, group='마커(출하)') %>%
          addMarkers(data=gis_fac[gis_fac$wide=='출하',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(출하)') %>%
          addCircleMarkers(data=gis_fac[gis_fac$wide=='종축',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                           radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                           color = 'orange',
                           stroke = FALSE, fillOpacity = 1, group='마커(종축)') %>%
          addMarkers(data=gis_fac[gis_fac$wide=='종축',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(종축)') %>%
          addCircleMarkers(data=gis_fac[gis_fac$wide=='사료',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                           radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                           color = 'navy',
                           stroke = FALSE, fillOpacity = 1, group='마커(사료)') %>%
          addMarkers(data=gis_fac[gis_fac$wide=='사료',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(사료)') %>%
          addCircleMarkers(data=gis_fac[gis_fac$wide=='분뇨/비료',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                           radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                           color = 'blue',
                           stroke = FALSE, fillOpacity = 1, group='마커(분뇨/비료)') %>%
          addMarkers(data=gis_fac[gis_fac$wide=='분뇨/비료',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(분뇨/비료)') %>%
          addCircleMarkers(data=gis_fac[gis_fac$wide=='검정/소독',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                           radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                           color = 'violet',
                           stroke = FALSE, fillOpacity = 1, group='마커(검정/소독)') %>%
          addMarkers(data=gis_fac[gis_fac$wide=='검정/소독',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(검정/소독)') %>%
          addCircleMarkers(data=gis_fac[gis_fac$wide=='철새/기타',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                           radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                           color = 'black',
                           stroke = FALSE, fillOpacity = 1, group='마커(철새/기타)') %>%
          addMarkers(data=gis_fac[gis_fac$wide=='철새/기타',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(철새/기타)') %>%
          addLayersControl(
            baseGroups = c("권역Layer",'권역제거'),
            overlayGroups = c("마커(출하)",'마커(종축)','마커(사료)','마커(분뇨/비료)','마커(검정/소독)','마커(철새/기타)'),
            options = layersControlOptions(collapsed = FALSE) ) %>% hideGroup(c("마커(출하)",'마커(종축)','마커(사료)','마커(분뇨/비료)','마커(검정/소독)','마커(철새/기타)'))

        output$table0 <- renderTable({
          cut.score %>% filter(level<=input$cluster0) %>% rename()
        }, digits = 3)
        output$downloadData0 <- downloadHandler(
          filename = 'result_table.csv',
          content = function(file) {
            write.csv(kor_adm2b, file, row.names=F, fileEncoding = "euckr")
          })

        # ??????? end
    }
  })

  observeEvent(input$submit1, {
    if (is.na(input$fieldset1)==1) print("최소한 한 개의 요소는 골라야 합니다.")
    else {
      if(input$fieldset1 == 'FC_pl_sl_fe'){
        col.idx <- 0
        sc.idx <- 2
      } else if(input$fieldset1 == 'FC_pl_sl_fe_br'){
        col.idx <- 4       
        sc.idx <- 4
      } else if(input$fieldset1 == 'FC_pl_sl_fe_br_di'){
        col.idx <- 8       
        sc.idx <- 6
      }
      conn <- dbConnect(dbDriver("MySQL"),dbname = 'livestock',host = "147.46.229.85",user = "ais",password = "ezfarm3414" )
      dbGetQuery( conn, "set names 'utf8'" )
      score30 <- dbGetQuery(conn, "SELECT * FROM cut_score")
      kor_adm2b <- dbGetQuery(conn, "SELECT * FROM kor_adm2b")
      gis_fac <- dbGetQuery(conn, "SELECT * FROM gis_fac")
      dbDisconnect(conn)
      
      setwd("/Users/bpk/Works/ezfarm/map/KOR_adm_shp")
      kor_LL <- readShapePoly("KOR_adm2")
      kor_adm2b <- kor_adm2b[,c(1:19,(19+col.idx+input$cluster1))]
      cut.score <- score30[,c(1,sc.idx)]
      colnames(kor_adm2b)[20] <- 'cluster'
      colnames(cut.score)[2] <- 'score'
      kor_adm2b[which(kor_adm2b$cluster==kor_adm2b[kor_adm2b$NL_NAME_2=='울릉군','cluster']),'cluster'] <- NA
      kor_LL@data <- kor_adm2b
      print("hi")
      factpal <- colorFactor(topo.colors(5), domain = NULL)
      pal <- colorFactor(c("red",'orange','navy','blue','violet','black'), domain = c("출하",'분뇨/비료','사료', "종축",'검정/소독','철새/기타'))
      output$plot1 <- renderLeaflet({
        leaflet() %>% addTiles() %>% setView(lng=127.8494, lat=36.45452,zoom=7)
      })
      leafletProxy('plot1') %>% addPolygons(data=kor_LL, weight=1, color=~factpal(kor_LL$cluster), smoothFactor = 1.0, opacity = 1, fillOpacity = 0.5, highlightOptions = highlightOptions(color = "red", weight = 5,bringToFront = TRUE),group='권역Layer')
      shp.cl <- unionSpatialPolygons(kor_LL, kor_LL$cluster)
      leafletProxy('plot1') %>% addPolygons(data=shp.cl, weight = 1, opacity = 1, color = "white", dashArray = "3", fillOpacity = 0, highlightOptions = highlightOptions(color = "red", weight = 5,bringToFront = TRUE)) 
      leafletProxy('plot1') %>% addCircleMarkers(data=gis_fac[gis_fac$wide=='출하',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                       radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                       color = 'red',
                       stroke = FALSE, fillOpacity = 1, group='마커(출하)') %>%
        addMarkers(data=gis_fac[gis_fac$wide=='출하',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(출하)') %>%
        addCircleMarkers(data=gis_fac[gis_fac$wide=='종축',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                         radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                         color = 'orange',
                         stroke = FALSE, fillOpacity = 1, group='마커(종축)') %>%
        addMarkers(data=gis_fac[gis_fac$wide=='종축',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(종축)') %>%
        addCircleMarkers(data=gis_fac[gis_fac$wide=='사료',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                         radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                         color = 'navy',
                         stroke = FALSE, fillOpacity = 1, group='마커(사료)') %>%
        addMarkers(data=gis_fac[gis_fac$wide=='사료',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(사료)') %>%
        addCircleMarkers(data=gis_fac[gis_fac$wide=='분뇨/비료',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                         radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                         color = 'blue',
                         stroke = FALSE, fillOpacity = 1, group='마커(분뇨/비료)') %>%
        addMarkers(data=gis_fac[gis_fac$wide=='분뇨/비료',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(분뇨/비료)') %>%
        addCircleMarkers(data=gis_fac[gis_fac$wide=='검정/소독',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                         radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                         color = 'violet',
                         stroke = FALSE, fillOpacity = 1, group='마커(검정/소독)') %>%
        addMarkers(data=gis_fac[gis_fac$wide=='검정/소독',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(검정/소독)') %>%
        addCircleMarkers(data=gis_fac[gis_fac$wide=='철새/기타',],~lng, ~lat, clusterOptions = markerClusterOptions(),
                         radius = ~ifelse(wide=='출하', 20, ifelse(wide%in%c('종축','사료'),15,ifelse(wide=='분뇨/비료',10,5))),
                         color = 'black',
                         stroke = FALSE, fillOpacity = 1, group='마커(철새/기타)') %>%
        addMarkers(data=gis_fac[gis_fac$wide=='철새/기타',],~lng, ~lat, popup = ~as.character(type), label = ~as.character(type),clusterOptions = markerClusterOptions(),group='마커(철새/기타)') %>%
        addLayersControl(
          baseGroups = c("권역Layer",'권역제거'),
          overlayGroups = c("마커(출하)",'마커(종축)','마커(사료)','마커(분뇨/비료)','마커(검정/소독)','마커(철새/기타)'),
          options = layersControlOptions(collapsed = FALSE) ) %>% hideGroup(c("마커(출하)",'마커(종축)','마커(사료)','마커(분뇨/비료)','마커(검정/소독)','마커(철새/기타)'))
      
      output$table1 <- renderTable({
        cut.score %>% filter(level<=input$cluster1) %>% rename()
      }, digits = 3)
      output$downloadData1 <- downloadHandler(
        filename = 'result_table.csv',
        content = function(file) {
          write.csv(kor_adm2b, file, row.names=F, fileEncoding = "euckr")
        })
    }
  })
  

  observeEvent(input$submit2, {
    if (is.na(input$lstk_no2)) print("최소한 한 개의 축종은 골라야 합니다.")
    else {
      conn <- dbConnect(dbDriver("MySQL"),dbname = 'livestock',host = "147.46.229.85",user = "ais",password = "ezfarm3414" )
      dbGetQuery( conn, "set names 'utf8'" )
      kor_adm2 <- dbGetQuery(conn, "SELECT * FROM kor_adm2")
      dbDisconnect(conn)
     
      setwd("/Users/bpk/Works/ezfarm/map/KOR_adm_shp")
      kor_LL <- readShapePoly("KOR_adm2")
      kor_LL@data <- kor_adm2      
      output$plot2 <- renderLeaflet({
        m <- leaflet() %>% addTiles() %>% setView(lng=127.5676, lat=36.76795, zoom=7)
        m %>% addPolygons(data=kor_LL, group=kor_LL$NL_NAME_4, weight = 2, opacity = 1, color = "white", dashArray = "3", fillOpacity = 0.3,highlightOptions = highlightOptions(color = "orange", weight = 3,bringToFront = TRUE))
     })
      

      
      observeEvent(input$plot2_shape_click, { # update the location selectInput on map clicks
        p <- input$plot2_shape_click
        print(p$group)
        conn <- dbConnect(dbDriver("MySQL"),dbname = 'livestock',host = "147.46.229.85",user = "ais",password = "ezfarm3414" )
        dbGetQuery( conn, "set names 'utf8'" )
        kor_adm2 <- dbGetQuery(conn, "SELECT * FROM kor_adm2")
        if(input$lstk_no2 == 'LS_poul'){
          addr_trmat <- dbGetQuery(conn, "select * from trmat_pl")
        } else if(input$lstk_no2 == 'LS_chi'){
          addr_trmat <- dbGetQuery(conn, "select * from trmat_ch")
        } else if(input$lstk_no2 == 'LS_duc'){
          addr_trmat <- dbGetQuery(conn, "select * from trmat_du")
        }
        gis_fac <- dbGetQuery(conn, "SELECT * FROM gis_fac")
        dbDisconnect(conn)
        # ??????? start
        mat1 <- as.matrix(addr_trmat[,-1])/max(as.matrix(addr_trmat[,-1]))  # 최대값으로 전체를 나눠서 0~1사이 값으로...
        brk.out <- addr_trmat[,1:2]
        colnames(brk.out) <- c('city','breaks')
        brk.out[,2] <- 0 ; brk.out[brk.out$city==p$group,2] <- 1
        for(i in 3:22){
          brk.out[,i] <- t(t(brk.out[,i-1]) %*% mat1)
        }
        colnames(brk.out)[3:22] <- paste('lv',seq(1,20,1),sep='')
        brk.out <- brk.out %>% separate(city,c('addr1','addr2'),sep='_',remove=F)
        brk.out[brk.out$city=='세종특별자치시','addr2'] <- '연기군'
        kor_adm2 <- merge(kor_adm2,brk.out[,-1],by.x=c('NL_NAME_1','NL_NAME_2'),by.y=c('addr1','addr2'),all.x=T)
        kor_adm2[,24:43] <- apply(kor_adm2[,24:43],2,as.numeric)
        kor_adm2 <- kor_adm2 %>% arrange(OBJECTID)
        
        brk.gis <- kor_adm2[which(ifelse(kor_adm2$NL_NAME_4==p$group,T,F)),c('lng','lat')]
        brk.lng <- as.numeric(brk.gis[1]) ; brk.lat <- as.numeric(brk.gis[2])
        gis_fac <- gis_fac %>% mutate(dist_fac=sqrt((lng-brk.lng)^2+(lat-brk.lat)^2))
        near_fac <- function(fac_type,num) {
          tmp <- gis_fac %>% filter(type==fac_type) %>% arrange(dist_fac) %>% filter(row_number()<=num)
          return(tmp)
        }
        nr.slc <- near_fac('도계장',as.numeric(input$no_slc2))
        nr.sld <- near_fac('도압장',as.numeric(input$no_sld2))
        nr.fe <- near_fac('사료공장',as.numeric(input$no_fe2))
        nr.br1 <- near_fac('종축장',as.numeric(input$no_br12))
        nr.br2 <- near_fac('부화장',as.numeric(input$no_br22))
        nr.di <- near_fac('가축분뇨처리장',as.numeric(input$no_di2))
        
        setwd("/Users/bpk/Works/ezfarm/map/KOR_adm_shp")
        kor_LL <- readShapePoly("KOR_adm2")
        kor_LL@data <- kor_adm2      
        bins <- c(0, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, Inf)
        pal <- colorBin("YlOrRd", domain = NULL, bins = bins)
        tmp <- colnames(kor_LL@data)[23+input$time2]
        colnames(kor_LL@data)[23+input$time2] <- 'lv'
        kor_LL$lv <- kor_LL$lv * 100
        
          leafletProxy('plot2') %>% setView(lng=brk.lng, lat=brk.lat,zoom=8) %>%
            clearShapes() %>% addPolygons(data=kor_LL, group=kor_LL$NL_NAME_4, fillColor = ~pal(lv), weight = 2, opacity = 1, color = "white", dashArray = "3", fillOpacity = 0.5,
                          highlightOptions = highlightOptions(color = "red", weight = 5,bringToFront = TRUE)) %>% clearMarkers() %>%
            clearControls() %>% leaflet::addLegend('bottomright',pal = pal, values = kor_LL$lv, title = "Probability", labFormat = labelFormat(suffix = "%"), opacity = 1) %>%
            addCircleMarkers(data=nr.slc,~lng, ~lat, radius = 10, color = 'red', stroke = FALSE, fillOpacity = 1, group='도계장') %>%
            addMarkers(data=nr.slc,~lng, ~lat, popup = ~as.character(round(dist_fac,2)), label = ~as.character(type), group='도계장') %>%
            addCircleMarkers(data=nr.sld,~lng, ~lat, radius = 10, color = 'orange', stroke = FALSE, fillOpacity = 1, group='도압장') %>%
            addMarkers(data=nr.sld,~lng, ~lat, popup = ~as.character(round(dist_fac,2)), label = ~as.character(type), group='도압장') %>%
            addCircleMarkers(data=nr.fe,~lng, ~lat, radius = 10, color = 'green', stroke = FALSE, fillOpacity = 1, group='사료공장') %>%
            addMarkers(data=nr.fe,~lng, ~lat, popup = ~as.character(round(dist_fac,2)), label = ~as.character(type), group='사료공장') %>%
            addCircleMarkers(data=nr.br1,~lng, ~lat, radius = 10, color = 'cyan', stroke = FALSE, fillOpacity = 1, group='종축장') %>%
            addMarkers(data=nr.br1,~lng, ~lat, popup = ~as.character(round(dist_fac,2)), label = ~as.character(type), group='종축장') %>%
            addCircleMarkers(data=nr.br2,~lng, ~lat, radius = 10, color = 'blue', stroke = FALSE, fillOpacity = 1, group='부화장') %>%
            addMarkers(data=nr.br2,~lng, ~lat, popup = ~as.character(round(dist_fac,2)), label = ~as.character(type), group='부화장') %>%
            addCircleMarkers(data=nr.di,~lng, ~lat, radius = 10, color = 'purple', stroke = FALSE, fillOpacity = 1, group='분뇨처리장') %>%
            addMarkers(data=nr.di,~lng, ~lat, popup = ~as.character(round(dist_fac,2)), label = ~as.character(type), group='분뇨처리장') %>%
            addLayersControl(
            baseGroups = c("시군Layer"),
            overlayGroups = c('도계장','도압장','사료공장','종축장','부화장','분뇨처리장'),
            options = layersControlOptions(collapsed = FALSE) )

      })
      
    
    }
  })
  
  addr_list <- data.frame(addr_code=c('GG1','GG2','GB1','GB2','JB1','JB2','JN1','JN2'),
                          addr_name=c('경기도 포천시 관인면 탄동리','경기도 여주시 흥천면 복대리','경상북도 안동시 남선면 이천리','경상북도 경산시 진량읍 선화리',
                                      '전라북도 고창군 흥덕면 치룡리','전라북도 익산시 망성면 어량리','전라남도 영암군 삼호읍 난전리','전라남도 보성군 보성읍 쾌상리'))
  
  # ??????? end

  observeEvent(input$submit3, {
    if (is.na(input$lstk_no3)) print("최소한 한 개의 축종은 골라야 합니다.")
    else {
      # input <- NULL
      # input$addr3 <- 'JB1'
      # input$time3 <- 10
      # end_date <- "2017-04-30"

      # ??????? start
      brk.addr <- addr_list[addr_list$addr_code==input$addr3,2]
      end_date <- input$brk_date3
      start_date <- strftime(as.Date(end_date,format="%Y-%m-%d") - 21, format="%Y-%m-%d")
      query <- sprintf("SELECT * FROM data_carmon where ( date  between \"%s\" and \"%s\" ) and ( addr2_from = \"%s\"  )",
                       start_date, end_date, brk.addr)
      conn <- dbConnect(dbDriver("MySQL"),dbname = 'livestock',host = "147.46.229.85",user = "ais",password = "ezfarm3414" )
      dbGetQuery( conn, "set names 'utf8'" )
      data_fil <- dbGetQuery(conn, query)
      addr_gis <- dbGetQuery(conn, "select * from addr_gis ")
      dbDisconnect(conn)

      car_visit <- data_fil[,c(1:18)]
      visit_gis <- melt(id=c(1:7),car_visit)
      visit_gis <- merge(visit_gis,addr_gis[,6:8],by.x='value',by.y='address',all.x=T)
      date_visit<- data_fil[,c(1,2,3,19:29)]
      visit_date <- melt(id=c(1:3),date_visit)
      visit_gis <- visit_gis %>% arrange(FRMHS_NO,VISIT_DE,VISIT_VHCLE_NO,variable) 
      visit_date <- visit_date %>% arrange(FRMHS_NO,VISIT_DE,VISIT_VHCLE_NO,variable)
      visit_gis <- cbind(visit_gis,visit_date[,5])
      colnames(visit_gis)[12] <- 'date_new'
      brk.lng <- unique(visit_gis[visit_gis$variable=='addr2_from',10])
      brk.lat <- unique(visit_gis[visit_gis$variable=='addr2_from',11])

      car_type <- data.frame(VISIT_PURPS_CN=c("사료운반","가축운반","원유운반","컨설팅","인공수정","가축분뇨운반","진료.예방접종","시료채취,방역","알운반","퇴비운반","동물(의)약품운반"))
      pal <- colorFactor(c('grey','blue','darkgreen',"coral",'brown','red','black','cyan','green','pink','darkred'), domain = as.character(t(car_type[,1])))
      dat.daily <- visit_gis %>% filter(as.character(date_new)<=strftime(as.Date(end_date,format="%Y-%m-%d") - as.numeric(input$time3), format="%Y-%m-%d"))
      car.dat <- list()
      for(i in 1:11) {
        car.dat[[i]] <- dat.daily %>% filter(VISIT_PURPS_CN==as.character(car_type[i,1]))
        if(nrow(car.dat[[i]])==0) {
          car.dat[[i]] <- visit_gis[1,]
          car.dat[[i]][1,8] <- "최초 발생지"
          car.dat[[i]][1,4] <- ""
        }
      }
      car_type2 <- dat.daily %>% group_by(VISIT_PURPS_CN) %>% tally() %>% select(1)

      output$plot3 <- renderLeaflet({
        leaflet() %>% setView(lng=brk.lng, lat=brk.lat,zoom=6) %>% addTiles(group='기본') %>%
          addCircleMarkers(data=car.dat[[1]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[1,1])) %>%
          addCircleMarkers(data=car.dat[[2]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[2,1])) %>%
          addCircleMarkers(data=car.dat[[3]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[3,1])) %>%
          addCircleMarkers(data=car.dat[[4]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[4,1])) %>%
          addCircleMarkers(data=car.dat[[5]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[5,1])) %>%
          addCircleMarkers(data=car.dat[[6]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[6,1])) %>%
          addCircleMarkers(data=car.dat[[7]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[7,1])) %>%
          addCircleMarkers(data=car.dat[[8]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[8,1])) %>%
          addCircleMarkers(data=car.dat[[9]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[9,1])) %>%
          addCircleMarkers(data=car.dat[[10]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[10,1])) %>%
          addCircleMarkers(data=car.dat[[11]],~lng, ~lat, radius = 6, color=~pal(as.factor(VISIT_PURPS_CN)), stroke = F, fillOpacity = 0.5, popup = ~as.character(value), label = ~as.character(paste(VISIT_PURPS_CN,VISIT_VHCLE_NO)), group=as.character(car_type[11,1])) %>%
          leaflet::addLegend('bottomright',pal = pal, values = dat.daily$VISIT_PURPS_CN, title = "차량유형", labFormat = labelFormat(suffix = ""), opacity = 1) %>%
          addLayersControl(
            baseGroups = c("기본"),
            overlayGroups = as.character(t(car_type2[,1])),
            options = layersControlOptions(collapsed = FALSE) ) #%>% hideGroup(as.character(t(car_type2[car_type2$VISIT_PURPS_CN!='사료운반',1])))

      })
      # ??????? end

    }
  })
  
}

shinyApp(ui, server)