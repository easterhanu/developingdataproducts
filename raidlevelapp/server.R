# RAID Level Comparator - Server Logic
# Shiny App for Coursera Building Data Products Course
# Hannu Kivimaki 2016-06-18
#

library(shiny)

# Disable scientific notation when printing large numbers.
#options(scipen=999)

# Empty data frame with RAID level columns.
levelsDf <- data.frame(Feature = character(),
                       RAID0 = character(), RAID5 = character(),
                       RAID6 = character(), RAID10 = character(),
                       stringsAsFactors = F)

# Total read + write operations to drives for one read on RAID 0/5/6/10.
opsPerRead <- c("1+0", "1+0", "1+0", "1+0")

# Total read + write operations to drives for one write on RAID 0/5/6/10.
opsPerWrite <- c("0+1", "2+2", "3+3", "0+2")

# Returns RAID group's drive setup (data + parity) for RAID 0/5/6/10.
# Example:
#  getDriveSetup(8)
#    -> "8D", "7D+1P", "6D+2P", "4D+4D"
#
getDriveSetup <- function(driveCount) {
    r0 <- paste0(driveCount, "D")
    r5 <- paste0(driveCount - 1, "D+1P")
    r6 <- paste0(driveCount - 2, "D+2P")
    r10 <- paste0(driveCount / 2, "D+", driveCount / 2, "D")
    c(r0, r5, r6, r10)
}

# Returns RAID group'ss usable capacity for RAID 0/5/6/10.
# Example:
#   getUsableCapacity(8, 1000, "TiB")
#     -> 7.28, 6.37, 5.46, 3.64
#
# Notice: driveSize is expected to be in GB.
#
getUsableCapacity <- function(driveCount, driveSize, capacityUnit) {
    r0 <- driveCount * driveSize
    r5 <- (driveCount - 1) * driveSize
    r6 <- (driveCount - 2) * driveSize
    r10 <- (driveCount / 2) * driveSize
    cap <- c(r0, r5, r6, r10)
    if (capacityUnit == "TB") {
        round(cap / 1000, 2)
    } else {
        round(cap * 1000^3 / 1024^4, 2)
    }
}

# Returns RAID group's usable capacity percentage for RAID 0/5/6/10.
# Example:
#   getUsablePct(8)
#     -> 100, 87.5, 75, 50
#
getUsablePct <- function(driveCount) {
    r5 <- (driveCount - 1) / driveCount * 100
    r6 <- (driveCount - 2) / driveCount * 100
    round(c(100, r5, r6, 50), 2)
}

# Returns RAID group's total read IOPS performance for RAID 0/5/6/10.
# Example:
#  getReadIops(8, 100)
#    -> 800, 800, 800, 800
#
getReadIops <- function(driveCount, driveIops) {
    # Read performance is the same, no penalties.
    rall <- driveCount * driveIops
    c(rall, rall, rall, rall)
}

# Returns RAID group's total write IOPS performance for RAID 0/5/6/10.
# Example:
#  getWriteIops(8, 100)
#    -> 800, 200, 133, 400
#
getWriteIops <- function(driveCount, driveIops) {
    r0 <- driveCount * driveIops
    r5 <- floor(r0 / 4) # read data + parity, write data + parity
    r6 <- floor(r0 / 6) # read data + two parities, write data + two parities
    r10 <- floor(r0 / 2) # write to both submirrors
    c(r0, r5, r6, r10)
}

# Returns the number of concurrent faulty drives the RAID group tolerates.
# Example:
#  getFaultTolerance(8)
#    -> "0", "1", "2", "1-4"
#
getFaultTolerance <- function(driveCount) {
    # RAID0 has no fault tolerance
    # RAID5 tolerates one failed drive (one parity)
    # RAID6 tolerates two failed drives (two parities)
    # RAID10 always tolerates one failed drive, but may tolerate even
    #        losing half of the drives
    r10 <- driveCount / 2
    c("0", "1", "2", paste0("1-", r10))
}

# Returns the price per usable capacity unit for RAID 0/5/6/10.
# Example:
#  getCapacityPrice(8, 80, getUsableCapacity(8, 1000, "TiB"))
#    -> 43.99, 50.27, 58.66, 87.91
#
getCapacityPrice <- function(driveCount, drivePrice, usableCap) {
    totalPrice <- driveCount * drivePrice
    round(totalPrice / usableCap, 2)
}

# Returns the price per 100 write IOPS for RAID 0/5/6/10.
# Example:
#  getWriteIopsPrice(8, 80, getWriteIops(8, 100))
#    -> 80.00, 320.00, 481.20, 160.00
#
getWriteIopsPrice <- function(driveCount, drivePrice, writeIops) {
    totalPrice <- driveCount * drivePrice
    round(totalPrice / (writeIops / 100), 2)
}


shinyServer(function(input, output) {
    df <- reactive({
        # Add column headers.
        tmp <- levelsDf

        # Add drive setup row
        tmp[1, ] <- c("Drive Setup (Data + Parity)",
                      getDriveSetup(input$drivecount))

        # Add usable capacity (bytes) row.
        usableCap <- getUsableCapacity(input$drivecount,
                                       as.numeric(input$drivesize),
                                       input$capacityunit)
        tmp[2, ] <- c(paste("Usable Capacity", input$capacityunit),
                      sprintf("%.2f", usableCap))

        # Add usable capacity (percentage) row.
        tmp[3, ] <- c("Usable Capacity %",
                      sprintf("%.2f", getUsablePct(input$drivecount)))

        # Add R+W operations per single RAID read row.
        tmp[4, ] <- c("R+W Ops Per RAID Read", opsPerRead)

        # Add read IOPS row.
        readIops <- getReadIops(input$drivecount, as.numeric(input$driveiops))
        tmp[5, ] <- c("Read IOPS Performance",
                      format(readIops, trim = T, scientific = F, big.mark = " "))

        # Add R+W operations per single RAID write row.
        tmp[6, ] <- c("R+W Ops Per RAID Write", opsPerWrite)

        # Add write IOPS row.
        writeIops <- getWriteIops(input$drivecount, as.numeric(input$driveiops))
        tmp[7, ] <- c("Write IOPS Performance",
                      format(writeIops, trim = T, scientific = F, big.mark = " "))

        # Add fault tolerance row.
        tmp[8, ] <- c("Fault Tolerance (Drives)",
                      getFaultTolerance(input$drivecount))

        # Add usable capacity price row.
        tmp[9, ] <- c(paste("Price", input$currency, "/ Usable", input$capacityunit),
                      sprintf("%.2f", getCapacityPrice(input$drivecount,
                                                       input$driveprice,
                                                       usableCap)))

        # Add write IOPS price row.
        tmp[10, ] <- c(paste("Price", input$currency, "/ 100 Write IOPS"),
                       sprintf("%.2f", getWriteIopsPrice(input$drivecount,
                                                         input$driveprice,
                                                         writeIops)))
        tmp
    })
    output$raidTable <- renderDataTable({df()},
        options <- list(paging = F, ordering = F, searching = F, info = F))

    output$driveImages <- renderText({
        sapply(1:(input$drivecount / 2),
               function(i){ paste(img(src = "hddpair_blue.png"))} )
    })
})
