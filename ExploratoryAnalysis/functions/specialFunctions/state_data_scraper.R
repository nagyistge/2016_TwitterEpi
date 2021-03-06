#sources:

#not available, but contacted responsible person
#Minnesota: http://www.health.state.mn.us/divs/idepc/diseases/flu/stats/weeklyold.html
#North Dakota: http://www.ndflu.com/
#South Dakota: https://doh.sd.gov/diseases/infectious/flu/surveillance.aspx
#Wisconsin: https://www.dhs.wisconsin.gov/influenza/index.htm
#Iowa: http://idph.iowa.gov/influenza/reports
#Arkansas: http://www.healthy.arkansas.gov/programsservices/infectiousdisease/immunizations/seasonalflu/pages/flureport.aspx
#California
#Washington
#Oregon
#Virginia: http://www.vdh.virginia.gov/epidemiology/influenza-flu-in-virginia/influenza-surveillance/sentinel-influenza-reporting-for-virginia-2016-2017/


#not available, not yet contacted
#North Carolina: http://www.flu.nc.gov/
#Georgia: https://dph.georgia.gov/flu-activity-georgia



#available, but only in pdf-format
##Michigan: http://www.michigan.gov/mdhhs/0,5885,7-339-71550_2955_22779_40563-143382--,00.html
#Illinois: http://www.dph.illinois.gov/topics-services/diseases-and-conditions/influenza/surveillance
#Missouri: http://health.mo.gov/living/healthcondiseases/communicable/influenza/reports.php#1112
#Louisiana: http://new.dhh.louisiana.gov/index.cfm/page/2584
#Maine: http://www.maine.gov/dhhs/mecdc/infectious-disease/epi/influenza/influenza-surveillance-archives.htm 
#Arizona: http://www.azdhs.gov/preparedness/epidemiology-disease-control/flu/index.php#surveillance-2014-2015

#available, only in pdf-format, but scraped
#New Jersey: http://www.nj.gov/health/cd/statistics/flu-stats/
#Mississippi: http://www.msdh.state.ms.us/msdhsite/_static/14,0,199,230.html

#library("rvest")
#install.packages("rvest")
#install.packages("R.utils")
#library("R.utils")
#install.packages("stringr")
library("stringr")
#install.packages("data.table")
#library("data.table")
#install.packages("bit64")
#library("bit64")

#two possibilities to extract info from pdf-tools
#install.packages("pdftools")
#https://ropensci.org/blog/2016/03/01/pdftools-and-jeroen
library("pdftools")

#install.packages("ghit")
#ghit::install_github(c("ropensci/tabulizerjars", "ropensci/tabulizer"))
library("tabulizer")


#get ILI rates from the state of Mississippi----
setwd("/home/drosoneuro/Dropbox/UZH_Master/Masterarbeit/TwitterEpi/ExploratoryAnalysis/ili_data/Mississippi")
url_base <- c("http://msdh.ms.gov/msdhsite/_static/14,0,199,600.html",
              "http://msdh.ms.gov/msdhsite/_static/14,0,199,601.html",
              "http://msdh.ms.gov/msdhsite/_static/14,0,199,629.html",
              "http://msdh.ms.gov/msdhsite/_static/14,0,199,630.html",
              "http://msdh.ms.gov/msdhsite/_static/14,0,199,738.html")

url_static <- "http://msdh.ms.gov/msdhsite/_static/"
str_to_match <- "resources/[0-9]*\\.pdf"

extract_last_of_url<- function(url){
  temp <- strsplit(url,split="/")
  return(tail(temp[[1]],1))
}

download_ili_files <- function(url_base,url_static,str_to_match,dl=T){
  #extract available pdf_files
  urls <- character()
  for (url in url_base){
    html <- paste(readLines(url), collapse="\n")
    matched <- str_match_all(html, "<a href=\"(.*?)\"")
    matched <- sapply(str_match_all(matched, str_to_match),unique)
    urls_temp <- paste0(url_static,matched)
    urls <- c(urls,urls_temp)
  }
  
  #get names of pdfs
  pdf_names <- as.vector(sapply(urls,extract_last_of_url))
  
  #download the files
  if(dl==T){
    for (i in 1:length(urls)){
      download.file(url=urls[i],
                    destfile=pdf_names[i])
    }
  } 
  return(pdf_names)
}

extract_ili_rates <- function(ili_rates_txt){
  district <- c()
  ili <- c()
  for (i in ili_rates_txt){
    split_text <- strsplit(i,split= " ")
    split_text <- split_text[[1]][!(split_text[[1]] %in% "")]
    if (split_text[1]=="District"){
      week <- as.numeric(rep(split_text[5],length(ili_rates_txt)-1))
    }
    else {
      district <- c(district,split_text[1])
      ili <- c(ili,as.numeric(split_text[3]))
    }
  }
  ili_rates <- as.data.table(district)
  ili_rates <- cbind(ili_rates,ili,week)  
  check_value1 <- c("State","1","2","3","4","5","6","7","8","9")
  check_value2 <- c("State","I","II","III","IV","V","VI","VII","VIII","IX")
  if (all(ili_rates$district == check_value1)){
    return(ili_rates)
  }  else if (all(ili_rates$district == check_value2)){
    ili_rates$district <- check_value1
    return(ili_rates)
  } else{
    warning("region indices incorrect")
    # ind <- which(ili_rates$district != check_value)
    # for (i in ind){
    #   ili_rates[i,] <- list(as.character(ili_rates$ili[i]),as.numeric(ili_rates$district[i]),ili_rates$week[i])
    # }
    # return(ili_rates)
  }

}

get_ili_rates_ms <- function(pdf_names,ili_rates_ms){
  for (i in pdf_names){
    name <- as.numeric(gsub(".pdf","",i))
    if (name<5989){
      area_list <- list(c(90, 357, 332, 564))
    } else if (name < 6111){
      area_list <- list(c(67,364,307,562)) 
    } else if (name < 6399){
      #area_list <- list(c(507, 362, 737, 560))
      area_list <- list(c(479,389,717,590)) 
      #area_list <- list(c(90, 357, 332, 564))
    } else if (name < 6616 || name == 6621) {
      area_list <- list(c(90, 357, 332, 564))
    } else {
        area_list <- list(c(482, 362, 737, 567))
    }

    out <- extract_tables(i,pages=2,area=area_list)
    if (name <5596){
      extract_pattern <- "^[0-9,D,i,s,t,r,c, ,W,e,w,k,d,S,a,\\.]*$"
    } else {
      extract_pattern <- "^[0-9,D,i,s,t,r,c, ,W,e,w,k,d,S,a,\\.,I,V,X,a,o,v,l,b,n,N,-]*$"
    }
    print(i)
    for (j in 1:length(out)){
      for (k in out[[j]]){
        if (any(grep("MSDH District ILI Rates",k))){
          if (ncol(out[[j]])>=2){
            out[[j]] <- apply(out[[j]], 1, paste, collapse=" ") 
          }
          ili_rates_txt <- as.vector(out[[j]])
          year <- grep("20[0-9]*-20[0-9]*",ili_rates_txt,value=T)
          ili_rates_txt <- ili_rates_txt[! (ili_rates_txt %in% "" | ili_rates_txt %in% " ")] #remove empty strings
          ili_rates_txt <- ili_rates_txt[str_length(ili_rates_txt)>=9]
          ili_rates_txt <- grep(extract_pattern,ili_rates_txt,value=T)
          start <- grep("District Week",ili_rates_txt)
          ili_rates_txt <- ili_rates_txt[start:(start+10)]
          print(ili_rates_txt)
          ili_rates <- extract_ili_rates(ili_rates_txt)
          ili_rates[,year:=year]
          print(ili_rates)
          ili_rates_ms <- rbind(ili_rates_ms,ili_rates)
        }
      }
    }
  }
  return(ili_rates_ms)
}

#download pdfs
pdf_names <- download_ili_files(url_base,url_static,str_to_match,dl=F)

#get the ili_rates
ili_rates_ms <- data.table(district=character(),ili=numeric(),week=numeric(),year=character())
ili_rates_ms <- get_ili_rates_ms(pdf_names,ili_rates_ms)
save(ili_rates_ms,file="ili_rates_ms.RData")




#get ILI rates from the state of Maine----
setwd("/home/drosoneuro/Dropbox/UZH_Master/Masterarbeit/TwitterEpi/ExploratoryAnalysis/ili_data/Maine")
library("XML")
library("RCurl")
url_base <- c("http://www.maine.gov/dhhs/mecdc/infectious-disease/epi/influenza/influenza-surveillance-archives.htm")
str_to_match <- "http://www.maine.gov/tools/whatsnew/attach.php\\?id=[0-9]*&an=2"

extract_last_of_url<- function(url){
  temp <- str_match(url,"[0-9]+&")[,1]
  temp <- gsub("&",".pdf",temp)
  return(temp)
}

download_ili_files <- function(url_base,url_static,str_to_match,dl=T){
  #extract available pdf_files
  #urls <- character()
  for (url in url_base){
    html <- paste(readLines(url), collapse="\n")
    #html <- htmlParse(url)
    #htmltxt <- paste(capture.output(html, file=NULL), collapse="\n")
    matched <- str_match_all(html, "<a target=\"_blank\" href=\"(.*?)\"")
    #matched <- sapply(str_match_all(matched, str_to_match),unique)
    urls <- sapply(str_match_all(matched, str_to_match),unique)
    #urls_temp <- paste0(url_static,matched)
    #urls <- c(urls,urls_temp)
  }
  
  #get names of pdfs
  pdf_names <- as.vector(sapply(urls,extract_last_of_url))
  
  #download the files
  if(dl==T){
    for (i in 1:length(urls)){
      download.file(url=urls[i],
                    destfile=pdf_names[i])
    }
  } 
  return(pdf_names)
}

extract_ili_rates <- function(ili_rates_txt){
  district <- c()
  ili <- c()
  for (i in ili_rates_txt){
    split_text <- strsplit(i,split= " ")
    split_text <- split_text[[1]][!(split_text[[1]] %in% "")]
    if (split_text[1]=="District"){
      week <- as.numeric(rep(split_text[5],length(ili_rates_txt)-1))
    }
    else {
      district <- c(district,split_text[1])
      ili <- c(ili,as.numeric(split_text[3]))
    }
  }
  ili_rates <- as.data.table(district)
  ili_rates <- cbind(ili_rates,ili,week)  
  check_value1 <- c("State","1","2","3","4","5","6","7","8","9")
  check_value2 <- c("State","I","II","III","IV","V","VI","VII","VIII","IX")
  if (all(ili_rates$district == check_value1)){
    return(ili_rates)
  }  else if (all(ili_rates$district == check_value2)){
    ili_rates$district <- check_value1
    return(ili_rates)
  } else{
    warning("region indices incorrect")
    # ind <- which(ili_rates$district != check_value)
    # for (i in ind){
    #   ili_rates[i,] <- list(as.character(ili_rates$ili[i]),as.numeric(ili_rates$district[i]),ili_rates$week[i])
    # }
    # return(ili_rates)
  }
  
}

get_ili_rates_ms <- function(pdf_names,ili_rates_ms){
  for (i in pdf_names){
    name <- as.numeric(gsub(".pdf","",i))
    if (name<5989){
      area_list <- list(c(90, 357, 332, 564))
    } else if (name < 6111){
      area_list <- list(c(67,364,307,562)) 
    } else if (name < 6399){
      #area_list <- list(c(507, 362, 737, 560))
      area_list <- list(c(479,389,717,590)) 
      #area_list <- list(c(90, 357, 332, 564))
    } else if (name < 6616 || name == 6621) {
      area_list <- list(c(90, 357, 332, 564))
    } else {
      area_list <- list(c(482, 362, 737, 567))
    }
    
    out <- extract_tables(i,pages=2,area=area_list)
    if (name <5596){
      extract_pattern <- "^[0-9,D,i,s,t,r,c, ,W,e,w,k,d,S,a,\\.]*$"
    } else {
      extract_pattern <- "^[0-9,D,i,s,t,r,c, ,W,e,w,k,d,S,a,\\.,I,V,X,a,o,v,l,b,n,N,-]*$"
    }
    print(i)
    for (j in 1:length(out)){
      for (k in out[[j]]){
        if (any(grep("MSDH District ILI Rates",k))){
          if (ncol(out[[j]])>=2){
            out[[j]] <- apply(out[[j]], 1, paste, collapse=" ") 
          }
          ili_rates_txt <- as.vector(out[[j]])
          year <- grep("20[0-9]*-20[0-9]*",ili_rates_txt,value=T)
          ili_rates_txt <- ili_rates_txt[! (ili_rates_txt %in% "" | ili_rates_txt %in% " ")] #remove empty strings
          ili_rates_txt <- ili_rates_txt[str_length(ili_rates_txt)>=9]
          ili_rates_txt <- grep(extract_pattern,ili_rates_txt,value=T)
          start <- grep("District Week",ili_rates_txt)
          ili_rates_txt <- ili_rates_txt[start:(start+10)]
          print(ili_rates_txt)
          ili_rates <- extract_ili_rates(ili_rates_txt)
          ili_rates[,year:=year]
          print(ili_rates)
          ili_rates_ms <- rbind(ili_rates_ms,ili_rates)
        }
      }
    }
  }
  return(ili_rates_ms)
}

#download pdfs
pdf_names <- download_ili_files(url_base,url_static,str_to_match,dl=F)

#get the ili_rates
ili_rates_ms <- data.table(district=character(),ili=numeric(),week=numeric(),year=character())
ili_rates_ms <- get_ili_rates_ms(pdf_names,ili_rates_ms)
save(ili_rates_ms,file="ili_rates_ms.RData")




#get ILI rates from state of New Jersey
#install.packages("qdap")
library("qdap") #for mgsub
setwd("/home/drosoneuro/Dropbox/UZH_Master/Masterarbeit/TwitterEpi/ExploratoryAnalysis/ili_data/NewJersey")

get_ili_rates_ms <- function(pdf_names,ili_rates_nj){
  for (i in pdf_names){
    week <- as.numeric(gsub("^.*_([0-9]+).*$","\\1", i))
    year <- as.numeric(str_split(i,pattern="/")[[1]][1])
    if ((year >= 2015) && (week >= 40)){
      pages <- 9
    } else if (year < 2011){
      pages <- 12
    } else {
      pages <- 6
    }
    area_list1 <- list(c(185,20,563,355))
    area_list2 <- list(c(185,560,563,769))
    print(i)

    # name <- as.numeric(gsub(".pdf","",i))
    # if (name<5989){
    #   area_list <- list(c(90, 357, 332, 564))
    # } else if (name < 6111){
    #   area_list <- list(c(67,364,307,562)) 
    # } else if (name < 6399){
    #   #area_list <- list(c(507, 362, 737, 560))
    #   area_list <- list(c(479,389,717,590)) 
    #   #area_list <- list(c(90, 357, 332, 564))
    # } else if (name < 6616 || name == 6621) {
    #   area_list <- list(c(90, 357, 332, 564))
    # } else {
    #   area_list <- list(c(482, 362, 737, 567))
    # }
    
    out1 <- extract_tables(i,pages=pages,area=area_list1,guess=F)
    out1[[1]][,4] <- multigsub("%","",out1[[1]][,4]) #to remove percentage sign
    out1 <- as.data.table(out1)
    out2 <- extract_tables(i,pages=pages,area=area_list2,guess=F)
    out2[[1]][,3] <- multigsub("%","",out2[[1]][,3])
    out2 <- as.data.table(out2)
    out_joined <- cbind(out1,out2)
    cols <- seq(2,7)
    out_numeric <-  apply(out_joined[,cols,with=F], 2, function(x) as.numeric(x))
    ili_rates <- cbind(out_joined[,1,with=F],out_numeric)
    colnames(ili_rates) <- c("district","enrolledLTC","reportsLTC","iliLTC","enrolledHED","reportsHED","iliHED")
    ili_rates[,week:=week]
    ili_rates[,year:=year]
    print(ili_rates)
    ili_rates_nj <- rbind(ili_rates_nj,ili_rates)
    # if (name <5596){
    #   extract_pattern <- "^[0-9,D,i,s,t,r,c, ,W,e,w,k,d,S,a,\\.]*$"
    # } else {
    #   extract_pattern <- "^[0-9,D,i,s,t,r,c, ,W,e,w,k,d,S,a,\\.,I,V,X,a,o,v,l,b,n,N,-]*$"
    # }
    # print(i)
    # for (j in 1:length(out)){
    #   for (k in out[[j]]){
    #     if (any(grep("MSDH District ILI Rates",k))){
    #       if (ncol(out[[j]])>=2){
    #         out[[j]] <- apply(out[[j]], 1, paste, collapse=" ") 
    #       }
    #       ili_rates_txt <- as.vector(out[[j]])
    #       year <- grep("20[0-9]*-20[0-9]*",ili_rates_txt,value=T)
    #       ili_rates_txt <- ili_rates_txt[! (ili_rates_txt %in% "" | ili_rates_txt %in% " ")] #remove empty strings
    #       ili_rates_txt <- ili_rates_txt[str_length(ili_rates_txt)>=9]
    #       ili_rates_txt <- grep(extract_pattern,ili_rates_txt,value=T)
    #       start <- grep("District Week",ili_rates_txt)
    #       ili_rates_txt <- ili_rates_txt[start:(start+10)]
    #       print(ili_rates_txt)
    #       ili_rates <- extract_ili_rates(ili_rates_txt)
     #   }
      #}
   # }
  }
  return(ili_rates_nj)
}


#get the ili_rates
ili_rates_nj <- data.table(district=character(),
                           enrolledLTC=numeric(),
                           reportsLTC=numeric(),
                           iliLTC=numeric(),
                           enrolledHED=numeric(),
                           reportsHED=numeric(),
                           iliHED=numeric(),
                           week=numeric(),
                           year=numeric())
years <- c(2010,2011,2012,2013,2014,2015)
for (i in years){
  files <- list.files(path=as.character(eval(i)))
  pdf_names <- paste0(i,"/",grep("flummwr_[0-9]*\\.pdf",files,value=T))
  ili_rates_nj <- get_ili_rates_ms(pdf_names,ili_rates_nj)
}

rm(list=ls()[-which("ili_rates_nj"==ls())])
save(ili_rates_nj,file="ili_rates_nj.RData")
