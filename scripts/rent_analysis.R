source("global.R")

result_data_folder <- "data/analysis_results"

districts <- c("i", "v", "vii", "viii", "ix", "xi", "xii", "xiii")
scraping_date <- "2019-11-16"

columns_to_keep <- c(
    "Kerület", "Kerület rész", "Ingatlan címe", "URL",
    "Bérleti díj", "Kaució", "Rezsiköltség", "Közös költség", "Minimum bérlési idő",
    "Épület típusa", "Méret", "Szobák száma", "Berendezés", "Emelet",
    "Erkélyek száma", "Lift", "Kilátás", "Fűtés", "Ház jellege",
    "Parkolási lehetőség", "Épület szintjeiSzintek száma", "Ingatlan állapota",
    "Építés éve", "Kisállat jöhet", "Kocsibeálló", "Tájolás", "Belmagasság"
)

listings <- map(districts, ~{
    fread(glue(
        "data/district_{.x}_listings_details_as_of_{scraping_date}_clean.csv"
    )) %>%
        .[, columns_to_keep, with = FALSE] %>%
        .[, `Kerület` := .x] %>%
        .[, `:=`(`Méret (m2)` = as.numeric(gsub(" m2", "", `Méret`)), `Méret` = NULL)]
}) %>% rbindlist()

median_costs <- listings %>%
    .[, .(
            `Hirdetések száma`      = .N,
            `Átlagos Bérleti díj`   = median(`Bérleti díj`,   na.rm = TRUE),
            `Átlagos Közös költség` = median(`Közös költség`, na.rm = TRUE),
            `Átlagos Rezsiköltség`  = median(`Rezsiköltség`,  na.rm = TRUE),
            `Átlagos Kaució`        = median(`Kaució`,        na.rm = TRUE),
            `Átlagos Méret (m2)`    = median(`Méret (m2)`,    na.rm = TRUE)
        ), by = `Kerület`] %>%
    .[, `Átlagos Bérleti díj / m2` := `Átlagos Bérleti díj` / `Átlagos Méret (m2)`]

fwrite(median_costs, file.path(result_data_folder, "median_costs.csv"))
