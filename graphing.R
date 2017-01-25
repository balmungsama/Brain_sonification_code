if (!require("ggplot2")) {install.packages("ggplot2")}
if (!require("reshape2")) {install.packages("reshape2")}
library('ggplot2')
library('reshape2')

file_dir <- getwd()
# print(paste('file_dir:', file_dir))

file_list <- list.files(path = file_dir, pattern = '*.txt', no.. = TRUE)

run_count <- NULL
for(file in list.files(path = file_dir, pattern = '*.txt', no.. = TRUE) ) {
  tmp_run <- strsplit(file, split = '_')[[1]][length(strsplit(file, split = '_')[[1]])]
  run_count <- c(run_count, as.numeric(strsplit(x = tmp_run, split = '.txt')[[1]][1]) )
}

# print(paste('max run_count = ', max(run_count)))
run_count <- max(run_count)

for(run in 1:run_count) {
  file_list <- list.files(path = file_dir, pattern = paste0('*_', run, '.txt'), no.. = TRUE)
  run_tab <- data.frame(row.names = 1:max(dim(read.table(file_list[1]))) )
  
  # browser()
  for(file in 1:length(file_list) ) {
    roi_name <- strsplit(file_list[file], split = '_')[[1]][3]
    run_tab <- cbind(run_tab, read.table(file = file_list[file], header = F)[,1] )
    colnames(run_tab)[file] <- roi_name
  }
  
  run_tab$x_vals <- 1:dim(run_tab)[1]
  data.melt <- melt(data = run_tab, id.vars = 'x_vals')
  colnames(data.melt)[2] <- 'ROI'
  
  for(timept in 1:dim(run_tab)[1]){
    t_plot <- ggplot(data = data.melt, aes(x = x_vals, y = value, color = ROI) ) + 
      geom_line(size = 0.5, alpha = 0.7) +
      theme_minimal() +
      xlab('time (TRs)') +
      ylab('z-score') +
      geom_vline(xintercept = timept, colour = "blue") +
      annotate("rect", xmin = timept, 
               xmax = dim(run_tab)[1], 
               ymin = min(run_tab[, -which(colnames(run_tab) == 'x_vals')]), 
               ymax = max(run_tab[, -which(colnames(run_tab) == 'x_vals')]),
               fill = 'white',
               alpha = .6) +
      ggtitle(paste('RUN', run))
    
    # print(t_plot)
    
    suppressWarnings(dir.create('figures'))
    suppressWarnings(dir.create('figures/videos'))
    ggsave(filename = paste0('figures/ROI_tcourse_', run, '_', timept, '.jpg'), plot = t_plot, width = 6.92*1.5, height = 5.3)
  }
}