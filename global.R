suppressPackageStartupMessages(library("data.table"))
suppressPackageStartupMessages(library("magrittr"))
suppressPackageStartupMessages(library("purrr"))
suppressPackageStartupMessages(library("glue"))
suppressPackageStartupMessages(library("ggplot2"))

invisible(sapply(list.files("R", full.names = TRUE), source))

USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36'
httr::set_config(httr::user_agent(USER_AGENT))
