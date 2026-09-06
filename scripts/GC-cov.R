# 绘制GC-cov图
args <- commandArgs(trailingOnly = TRUE)
table_dir <- args[1]
res_dir <- args[2]

# table_dir <- 'D:/宏基因组更新/blobology'
# res_dir <- 'D:/宏基因组更新/Result'

suppressPackageStartupMessages({
  library(ggplot2)
  library(reshape2)
  library(dplyr)
  library(openxlsx)
  library(plotly)
  library(htmlwidgets)
})

data <- read.table(file.path(table_dir, 'all.binned.blobplot.txt'), quote = '',
                   header = TRUE, sep = '\t', check.names = FALSE)
data$bin <- sapply(strsplit(data$bin, '[.]fa'), function(x) x[1])
resdir <- file.path(res_dir, 'binning', '2.Bin_Plot')
if (!dir.exists(resdir)) dir.create(resdir, recursive = TRUE)
write.xlsx(data, file.path(resdir, 'GC-cov.xlsx'))

# 绘制GC-cov散点图
yanse <- c('#178224','#D51506','#B300B5','#0133C1','#B6BF2D',
          '#2DBFB9','#EE520A','#E90A6D','#F09013','#5FD80A',
          "#A65628","#984EA3","#F781BF","#FFFF33","#377EB8",
          "#D3D93E","#C0717C","#CBD588","#D7C1B1","#673770",
          "#3F4921","#38333E","#689030","#AD6F3B","#D9B3A6",
          "#008B8B","#8B008B","#FF8C00","#8B0000","#FFD700",
          "#00FF00","#00FFFF","#FF00FF","#FF0000","#0000FF",
          "#006400","#FF1493","#FF4500","#FF6347","#FF69B4",
          "#8B658B","#8B4513","#FFD39B","#FFA07A","#FFA500",
          "#CDC9C9","#CD9B9B","#CD6889","#CD3333","#CD0000",
          "#AEEEEE","#8B8B00","#8DB6CD","#8B864E","#8B795E",
          "#9AC0CD","#8B5A2B","#8B4789","#7208BE","#6B0E06",
          "#FFE4C4","#6FDAB9","#1FC1C1","#FFB6C1","#FFAEB9")
p <- ggplot(data, aes(x = gc, y = coverage, color=bin)) + 
  geom_point(size=0.7) + 
  theme_bw(base_family = '宋体',base_size = 12,base_line_size =0.3)+
  theme(panel.grid = element_blank(),   #去网格
        #axis.line = element_line(linetype=1, color = 'black'), #加x,y轴
        #plot.title = element_text(hjust = 0.5, size = 12), #调整标题位置
        axis.text = element_text(color = 'black'),
        legend.title = element_blank(),
  )+
  labs(x = 'GC content', y = 'Read coverage') +
  scale_color_manual(values = yanse)

ggp <- ggplotly(p)
ggsave(file.path(resdir, 'GC-cov.pdf'), p, 
       width = 7, height = 6, device = cairo_pdf)
saveWidget(ggp,file = file.path(resdir, 'GC-cov.html'), selfcontained = T)





