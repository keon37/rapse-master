r = getOption("repos")
r["CRAN"] = "http://cran.us.r-project.org"
options(repos = r)

install.packages("dbConnect")
install.packages("dplyr")
install.packages("tidyr")
install.packages("lpSolve")
install.packages("igraph")
