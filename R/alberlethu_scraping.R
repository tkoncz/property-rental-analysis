cleanMoneyColumn <- function(x) {
    gsub("Árfigyelés", "", x) %>%
        gsub("/ hó", "", .) %>%
        gsub("HUF", "", .) %>%
        gsub("Nincs|Bérleti díj tartalmazza", "0", .) %>%
        gsub(" ", "", .) %>%
        as.numeric()
}

getDetailsFromAdUrls <- function(ad_urls, sleep_time = 2) {
    purrr::imap(ad_urls, ~{
        message(glue::glue("Scraping ad #{.y} out of {length(ad_urls)}"))

        url_scraping_result <- safelyScrapeAdInfoFromURL(ad_url = .x)
        if(!is.null(url_scraping_result[["error"]])) {
            message(glue::glue(
                "Couldn't parse url: <<{.x}>>. Error: <<{url_scraping_result[['error']]}>>"
            ))
            ad_info <- data.table::data.table(URL = .x)
        } else {
            ad_info <- url_scraping_result[["result"]]
        }

        Sys.sleep(time = sleep_time)

        ad_info
    }) %>% data.table::rbindlist(fill = TRUE)
}

scrapeAdInfoFromURL <- function(ad_url) {
    page_html <- xml2::read_html(ad_url)

    complete_table_rows <- page_html %>%
        rvest::html_nodes(xpath = "//div[@class='profile__info profile-info']//tr[count(child::td)=2]")

    table_row_values <- purrr::map(complete_table_rows, ~{
        browser
        .x %>%
            rvest::html_nodes("td") %>%
            .[[2]] %>%
            rvest::html_text() %>%
            trimws(which = c("both"))
    })

    table_key_values <- purrr::map_chr(complete_table_rows, ~{
        .x %>%
            rvest::html_nodes("td") %>%
            .[[1]] %>%
            rvest::html_text() %>%
            trimws(which = c("both"))
    })

    ad_info <- as.data.table(table_row_values) %>%
        setnames(table_key_values)

    ad_description <- page_html %>%
        rvest::html_nodes(xpath = "//div[@class='profile__text']") %>%
        rvest::html_text()

    ad_info[, `Leírás` := ad_description]
    ad_info[, URL := ad_url]
    setcolorder(ad_info, "URL")

    ad_info
}

safelyScrapeAdInfoFromURL <- purrr::safely(scrapeAdInfoFromURL)

getAdUrlsForDistrict <- function(site_url, district, sleep_time = 2) {
    starting_page_partial_url <- glue::glue(
        "/kiado_alberlet/page:1/ingatlan-tipus:lakas/kerulet:{district}/megye:budapest"
    )

    page_num <- 1
    partial_page_url <- starting_page_partial_url
    page_htmls <- list()
    while(!rlang::is_empty(partial_page_url)) {
        message(glue::glue("Parsing ads from page #{page_num}"))
        page_contents <- scrapeMainPage(site_url, partial_page_url)
        partial_page_url <- page_contents[["next_page_partial_url"]]
        page_htmls[[page_num]] <- page_contents[["html"]]
        page_num <- page_num + 1
        Sys.sleep(time = sleep_time)
    }

    ad_urls <- purrr::map(page_htmls, ~{
        getAdUrlsFromHtml(.x)
    }) %>% unlist()
    message(glue::glue("Found {length(ad_urls)} ads in {page_num - 1} pages"))

    ad_urls
}

scrapeMainPage <- function(site_url, partial_page_url) {
    page_url <- paste0(site_url, partial_page_url)
    page_html <- xml2::read_html(page_url)
    next_page_href <- getNextPagePartialHrefFromHTML(page_html)

    list(html = page_html, next_page_partial_url = next_page_href)
}

getAdUrlsFromHtml <- function(page_html) {
    page_html %>%
        rvest::html_nodes(xpath = "//div[@class='advert__image-container']/a") %>%
        rvest::html_attr("href") %>%
        unique()
}

getNextPagePartialHrefFromHTML <- function(page_html) {
    page_html %>%
        rvest::html_nodes(xpath = "//li[@class='last paging-next']/span/a[@class='next']") %>%
        rvest::html_attr("href")
}
