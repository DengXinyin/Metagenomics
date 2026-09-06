# 绘制bins丰度热图
args <- commandArgs(trailingOnly = TRUE)
table_dir <- args[1]
res_dir <- args[2]

# table_dir <- 'D:/宏基因组更新/quant_bins'
# res_dir <- 'D:/宏基因组更新/Result'

suppressPackageStartupMessages({
  library(pheatmap)
  library(dplyr)
  library(openxlsx)
  library(d3heatmap)
  library(plotly)
  library(htmlwidgets)
  library(heatmaply)
})

data <- read.table(file.path(table_dir, 'bin_abundance_table.tab'), quote = '',
                   header = TRUE, sep = '\t', check.names = FALSE, row.names = 1)
colnames(data) <- sapply(strsplit(colnames(data), '_clean|_dehost'), function(x) x[1])
resdir <- file.path(res_dir, 'binning', '3.Bin_Abundance')
if (!dir.exists(resdir)) dir.create(resdir, recursive = TRUE)
write.xlsx(data, file.path(resdir, 'Bin_Abundance.xlsx'), rowNames = TRUE)

# 绘制bins丰度热图
color <- colorRampPalette(c("blue", "white", "red"))(n = 50)
samp_nums <- ncol(data)
if (samp_nums > 35){fontsize = 400/samp_nums}else{fontsize = 12}
p <- pheatmap(data,scale = 'row',
         cluster_rows = T, cluster_cols = T,
         #annotation_col = group,
         color = color,
         border_color = 'transparent',
         fontsize = fontsize,
)
ggp <-  heatmaply(data,scale = 'row',show_grid  = F,
                  Rowv=T, Colv=T, dendrogram = 'both',
                  col=color, 
                  showticklabels = c(T,F),
                  angle_col = 45,labRowSize =0.5,labColSize =0.5,
                  famliy="宋体")
cairo_pdf(file.path(resdir,'Bin_Abundance.pdf'),family = '宋体',width = 9,height = 8)
base::print(p)
dev.off()

saveWidget(ggp,file = file.path(resdir,'Bin_Abundance.html'), selfcontained = T)






