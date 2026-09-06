library(vegan)
library(dplyr)
library(tibble)
library(ggsignif)
library(purrr)
library(plotly)
library(htmlwidgets)
args <- commandArgs(trailingOnly = TRUE)
data_dir <- args[1]
taxdir <- args[2]
res_dir <- args[3]
# library(showtext)
# font_add('myfont','/usr/share/fonts/dejavu/simsun.ttc')
# showtext_auto()
# setwd('/home/xpzhang/workshop/project/20260115-zxp-SNCQ04272507250')

# 读入相当于otu表

sample = read.table(file.path(data_dir, 'sample-metadata.tsv'), sep = '\t',
                    header = T, check.names = F)
k = ncol(sample) -1
# 读入相当于tax表
for (k in 1:k){
    gro_num <- paste0('group', k)
    genecountfile <- paste(taxdir,gro_num,"4-GeneAbundance/gene_count.csv",sep="/")
    # otu <- read.table('gene_count.csv', header = T, row.names = 1, sep = ',')
    otu <- read.csv(genecountfile, header = T, row.names = 1,check.names = F)
    otu$genes <- rownames(otu)
    taxfile <- paste0(taxdir,gro_num,"/5-TaxAnnotation/1.Tables/gene.taxonomy.csv")
    # tax <- read.table(paste0('Result/group',k,'/5-TaxAnnotation/1.Tables/gene.taxonomy.csv'), header = T, row.names = 1, sep = ',')
    tax <- read.csv(taxfile, header = T, row.names = 1,check.names = F)


    tax$genes <- rownames(tax)

    tax_otu_raw <- merge(tax, otu, by = 'genes')
    tax_otu_raw <- tax_otu_raw[ , 8:ncol(tax_otu_raw)]

    tax_otu_raw <- tax_otu_raw %>% group_by(species) %>% summarise_all(sum) %>% as.data.frame() %>%
      column_to_rownames('species')
    tax_otu_raw <- t(tax_otu_raw)
    samplesfile <- paste0(data_dir,"/sample-metadata.tsv")
    samples <- read.table(samplesfile, header = T, sep = '\t')
    samples <- samples %>% mutate(across(everything(), as.character))
    samples <- samples[samples[, paste0('group', k)] != '',c('sample.id',paste0('group',k))]

    for (j in c("All","Archaea","bacteria","Fungi","Virus")){
        print(j)
        specicestaxfile <- paste0(taxdir,gro_num,'/5-TaxAnnotation/1.Tables/Samples/',j,'/',j,'.taxonomy.csv')
        # print(dim(tax_otu_raw) )
        sp <- read.csv(specicestaxfile, header = T,check.names = F)
        # colnames(tax_otu_raw)
        # rownames(tax_otu_raw)
        print("#########################")
        # print(samples$`sample.id`)
        # print(colnames(tax_otu_raw) )
        # print(sp$species)
        print("#########################")
        col_list <- colnames(tax_otu_raw) %in% sp$species
        tax_otu <- tax_otu_raw[samples$`sample.id`,colnames(tax_otu_raw) %in% sp$species]
        print(ncol(tax_otu))
        Chao1  <- estimateR(tax_otu)[2, ]
        ACE  <- estimateR(tax_otu)[4, ]

        resdir <- paste(res_dir, gro_num,'5-TaxAnnotation', '7.alpha_diversity_analysis', j, sep = '/')
        if (!file.exists(resdir)){dir.create(resdir, recursive = T)}
        #Shannon 指数,通常使用2、e作为底数
        #以e作为底数表示方法
        Shannon <- diversity(tax_otu, index = 'shannon', base = exp(1))
        Gini_simpson  <- diversity(tax_otu, index = 'simpson')

        diver_index <- data.frame(Chao1, ACE, Shannon, Gini_simpson)

        xlsx::write.xlsx(diver_index, paste0(resdir,'/diversity_index.xlsx'))
        # 计算差异
        diver_index$sample = rownames(diver_index)
        diver_index$group = samples[,gro_num]
        diver_index[is.na(diver_index)] <- 0
        calculate_p_value <- function(data1, data2) {
            if (var(data1, na.rm = TRUE) * var(data2, na.rm = TRUE) > 0){
                if (shapiro.test(data1)$p.value > 0.05 && shapiro.test(data2)$p.value > 0.05){
                    testtry <- try(t.test(data1,data2),silent=TRUE)
                    if (class(testtry) == "try-error") {
                        p_value <- "NA"
                    }else{
                        t_test_result <- t.test(data1,data2)
                        p_value <- t_test_result$p.value
                        p_value <- round(p_value,6)
                    }
                }else{
                    testtry <- try(wilcox.test(data1,data2),silent=TRUE)
                        if (class(testtry) == "try-error") {
                            p_value <- "NA"
                            }else{
                              t_test_result <- wilcox.test(data1,data2)
                              p_value <- t_test_result$p.value
                              p_value <- round(p_value,6)
                            }
                    }
            }else{
                testtry <- try(wilcox.test(data1,data2),silent=TRUE)
                if (class(testtry) == "try-error") {
                    p_value <- "NA"
                }else{
                      t_test_result <- wilcox.test(data1,data2)
                      p_value <- t_test_result$p.value
                      p_value <- round(p_value,6)
                    }
                }
        return(p_value)
        }

# 多组间的差异
        for (i in 1:4){
            # i=3
          index <- colnames(diver_index)[i]
          ANOVA <- aov(diver_index[, i]~group,data = diver_index)
          summary(ANOVA)
          p <- summary(ANOVA)[[1]][['Pr(>F)']][1]
          p <- round(p, 4)
          groups <- unique(diver_index$group)
          group_pairs <- combn(groups, 2, simplify = FALSE)
          p_value_results <- map_df(group_pairs, ~ {
              data1 <- diver_index %>% filter(group == .x[1]) %>% pull(i)
              data2 <- diver_index %>% filter(group == .x[2]) %>% pull(i)
              tibble(
                  group1 = .x[1],
                  group2 = .x[2],
                  p_value = calculate_p_value(data1,data2)
              )
          })
          print(p_value_results)
          if (nrow(p_value_results) > 0) {
                comparisons <- map2(p_value_results$group1, p_value_results$group2, ~ c(.x, .y))
                annotations <- ifelse(p_value_results$p_value < 0.001, "***",
                                    ifelse(p_value_results$p_value < 0.01, "**",
                                            ifelse(p_value_results$p_value < 0.05, "*",
                                                    sprintf("p=%.3f", p_value_results$p_value))))
                # annotations <- sprintf("p=%.3f", p_value_results$p_value)
                y_positions <- max(diver_index[,i]) * (1 + 0.1 * seq_along(comparisons))
                } else {
                comparisons <- list()
                annotations <- character()
                y_positions <- numeric()
                }
          library(ggplot2)
          diver_p <- ggplot(diver_index, aes(x = group, y = diver_index[, i], color=group)) +
            geom_boxplot() +
            geom_point()+
            {
                    if (length(comparisons) > 0) {
                    geom_signif(
                        comparisons = comparisons,
                        annotations = annotations,
                        y_position = y_positions,
                        tip_length = 0.01,
                        color = 'black'
                    )
                    }
                }+
            theme_bw(base_family = '宋体', base_size = 12)+
            theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
                  axis.text.x = element_text(angle = 45, hjust = 1),
                  axis.title.x = element_blank(),
                  title = element_text(size = 9))+
            ggtitle(paste('ANOVA: p=', p))+
            labs(y = index)
            ggp1 <- ggplotly(diver_p)
            saveWidget(ggp1,file = paste(resdir,'/',index, '.html', sep = ''), selfcontained = T)

          ggsave(paste(resdir,'/',index, '.pdf', sep = ''), diver_p, width = 6, height = 4, device = cairo_pdf)
        }
        }
}
