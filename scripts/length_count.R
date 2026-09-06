args <- commandArgs(trailingOnly = TRUE)
table_dir <- args[1]
data_dir <- args[2]
res_dir <- args[3]

# table_dir <- 'D:/宏基因组更新/length'
# data_dir <- 'D:/宏基因组更新/data'
# res_dir <- 'D:/宏基因组更新'

library(dplyr)
library(openxlsx)
library(ggplot2)
library(reshape2)
library(plotly)
library(htmlwidgets)

yanse <- c("#FF7F00","#984EA3","#4DAF4A","#E41A1C","#377EB8",
          '#00F5FF',"#FFFF33","#DA5724","#74D944","#F781BF",
          "#CE50CA","#D3D93E","#C0717C","#CBD588",
          "#D7C1B1","#5F7FC7","#673770",  "#3F4921","#CD9BCD",
          "#38333E","#689030","#AD6F3B",  '#76EEC6')
sample = read.table(file.path(data_dir, 'sample-metadata.tsv'), sep = '\t',
                    colClasses = 'character', header = T, check.names = F)

for (i in 2: ncol(sample)){
  sap_gro = na.omit(sample[sample[, i] != '', c(1,i)])
  samps = sap_gro$`sample-id`
  group_id = paste0('group', i-1)
  gro_dir <- paste0(res_dir, '/', group_id, '/2-Assembly/')
  sta_ls = list()
  for (prefix in samps){
    sam_dir = paste0(res_dir, '/', group_id, '/2-Assembly/', prefix, '/')
    if (!file.exists(sam_dir)){dir.create(sam_dir, recursive = T)}

    file_name = paste0(prefix, '_length.txt')
    l_dat = read.table(file.path(table_dir, file_name), 
                       sep = '\t',quote = '',header = F)
    colnames(l_dat) = c('id', 'len')
    l_dat$Length <- cut(l_dat$len, 
                        breaks = c(500, 1000, 1500, 2000, 2500, 3000, 5000, 10000, 20000, 30000, Inf),
                        labels = c('500~1000', '1000~1500', '1500~2000', '2000~2500',
                                   '2500~3000', '3000~5000', '5000~10000', '10000~20000',
                                   '20000~30000', '>30000'),
                        right = F)
    sta_dat <- data.frame(table(l_dat$Length))
    colnames(sta_dat) <- c('Length', prefix)
    write.table(sta_dat, file=file.path(sam_dir, file_name), 
                sep = '\t', quote = F, row.names = F)
    dat_len <- sta_dat[, 1, drop=F]
    sta_ls[[prefix]] <- sta_dat[, 2]
  }
  
  sta_df <- as.data.frame(do.call(cbind, sta_ls))
  sta_df <- cbind(dat_len, sta_df)
  write.xlsx(sta_df, file = file.path(gro_dir, 'contigs_length.xlsx'))
  
  plot_df <- melt(sta_df, id.vars = 'Length')
  plot_df$variable <- factor(plot_df$variable, levels = unique(sap_gro$`sample-id`))
  p <- ggplot(data = plot_df, aes(x=variable, y=value, group=Length, fill=Length))+
    geom_bar(stat="identity",width=0.5,position='stack')+
    theme_bw(base_family = '宋体',base_size = 12,base_line_size =0.3)+
    theme(#panel.border = element_blank(),  #去外框
          panel.grid = element_blank(),   #去网格
          #axis.line = element_line(linetype=1, color = 'black'), #加x,y轴
          plot.title = element_text(hjust = 0.5, size = 12), #调整标题位置
          axis.text.x  = element_text(color = 'black', angle = 90, vjust = 0.5),
          axis.text.y  = element_text(color = 'black'),
          axis.title.x = element_blank(),
          legend.title = element_blank(),
    )+
    labs(y = 'Count')+
    scale_fill_manual(values = yanse)
  
  ggp <- ggplotly(p)
  saveWidget(ggp,file = paste0(gro_dir, 'contig_length.html'), selfcontained = T)
  k_samples <- length(unique(plot_df$variable))
  ggsave(paste0(gro_dir, 'contig_length.pdf'), p, 
         width = 9+(k_samples/20), height = 6+(k_samples/40), device = cairo_pdf)
    
}


