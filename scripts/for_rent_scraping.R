source("global.R")

districts <- c("xiii")
date <- Sys.Date()

all_listings_details <- map(districts, ~{
    message(glue("Parsing district {.x}"))
    ad_urls <- getAdUrlsForDistrict(
        site_url = "https://www.alberlet.hu",
        district = .x,
        sleep_time = 2
    )

    district_listings_details <- getDetailsFromAdUrls(
        ad_urls = ad_urls,
        sleep_time = 1
    )

    fwrite(
        district_listings_details,
        glue("data/district_{.x}_listings_details_as_of_{date}_raw.csv")
    )

    district_listings_details[, `:=`(
        `Bérleti díj`   = cleanMoneyColumn(`Bérleti díj`),
        `Kaució`        = cleanMoneyColumn(`Kaució`),
        `Rezsiköltség`  = cleanMoneyColumn(`Rezsiköltség`),
        `Közös költség` = cleanMoneyColumn(`Közös költség`)
    )]

    fwrite(
        district_listings_details,
        glue("data/district_{.x}_listings_details_as_of_{date}_clean.csv")
    )

    district_listings_details
})
