##### obtain z-transformed mean ROI time course

args=commandArgs(trailingOnly = T)
# print(args)

ROI_FILE <- args[which(args == '-p')  + 1]
TR_SKIP  <- args[which(args == '-tr') + 1]

ROI_t_file <- read.table(ROI_FILE, header = F, col.names = F)
ROI_t_file <- ROI_t_file[ - ( 1:as.numeric(TR_SKIP) ), 1]
ROI_t_file <- scale(ROI_t_file, center = T, scale = T)

write.table(x = ROI_t_file, file = ROI_FILE, row.names = F, col.names = F)