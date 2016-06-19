# RAID Level Comparator - User Interface
# Shiny App for Coursera Building Data Products Course
# Hannu Kivimaki 2016-06-19
#

library(shiny)

driveSizeList <- c("60 GB" = 60, "120 GB" = 120, "240 GB" = 240,
                   "300 GB" = 300, "480 GB" = 480, "600 GB" = 600,
                   "1 TB" = 1000, "2 TB" = 2000, "3 TB" = 3000,
                   "4 TB" = 4000, "5 TB" = 5000, "6 TB" = 6000,
                   "8 TB" = 8000)

currencyList <- c("EUR", "USD", "GBP")

driveIopsList <- c("75 IOPS - 5400 rpm HDD" = 75,
                   "100 IOPS - 7200 rpm HDD" = 100,
                   "150 IOPS - 10000 rpm HDD" = 150,
                   "200 IOPS - 15000 rpm HDD" = 200,
                   "50 000 IOPS - SSD" = 50000,
                   "75 000 IOPS - SSD" = 75000,
                   "100 000 IOPS - SSD" = 100000,
                   "125 000 IOPS - SSD" = 125000,
                   "150 000 IOPS - SSD" = 150000)

capacityUnitList <- c("TB", "TiB")


shinyUI(fluidPage(theme = "bootstrap_superhero.css",

  titlePanel(img(src = "raid_level_supalogo.png"),
             windowTitle = "RAID Level Comparator"),

  sidebarLayout(
                sidebarPanel(
                    selectInput("drivesize", "Drive Size:",
                                driveSizeList, selected = 2000),
                    selectInput("driveiops", "Drive I/O Performance:",
                                driveIopsList, selected = 100),
                    numericInput("driveprice", "Drive Price:",
                                 80, 20, 1000, 10),
                    radioButtons("currency", "Currency:",
                                 currencyList, "EUR", inline = T),
                    sliderInput("drivecount", "Number of Drives:",
                                4, 16, 8, 2),
                    radioButtons("capacityunit", "Output Capacity Unit:",
                                 capacityUnitList, "TB", inline = T),
                    HTML("<p>TB = terabyte = 1000<sup>4</sup> bytes",
                         "(used by drive manufacturers)</p>"),
                    HTML("<p>TiB = tebibyte = 1024<sup>4</sup> bytes",
                         "(used by OS and file systems)</p>")
                ),
                mainPanel(
                    HTML("How to use the RAID Level Comparator:"),
                    helpText("Fill in hard drive (HDD) or solid state drive (SSD)",
                             "information to the form on left. The table below",
                             "shows possible drive setups with different RAID",
                             "levels, given the number of drives you have.",
                             "Let the Comparator help you choose a sensible",
                             "RAID level depending on your capacity, performance,",
                             "fault tolerance and cost requirements!"),
                    dataTableOutput("raidTable"),
                    uiOutput("driveImages"),
                    HTML("<br/><p class='help-block'>See the Wikipedia articles on",
                         "<a href='https://en.wikipedia.org/wiki/RAID'>RAID</a> and",
                         "<a href='https://en.wikipedia.org/wiki/IOPS'>IOPS</a>",
                         " for background information and the",
                         "<a href='http://easterhanu.github.io/raidlevelcomparator.html'>",
                         "presentation slides</a> for a sales pitch!</p>")
                )
  )

))
