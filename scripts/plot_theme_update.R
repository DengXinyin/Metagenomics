# 统一宏基因组可视化主题配置
#
# 字体可通过环境变量切换：
#   METAGE_PLOT_FONT="Times New Roman"  （默认）
#   METAGE_PLOT_FONT="Arial"
#
# 在绘图脚本中使用：
#   source("plot_theme_update.R")
#   p <- p + metage_theme()

metage_plot_font <- Sys.getenv("METAGE_PLOT_FONT", "Times New Roman")

metage_theme <- function(base_size = 16,
                         axis_text_size = 16,
                         axis_title_size = 18,
                         legend_text_size = 18,
                         legend_title_size = 18,
                         title_size = 20,
                         style = c("bw", "classic")) {
    style <- match.arg(style)
    base_theme <- if (style == "classic") {
        ggplot2::theme_classic(base_family = metage_plot_font,
                               base_size = base_size)
    } else {
        ggplot2::theme_bw(base_family = metage_plot_font,
                          base_size = base_size)
    }

    base_theme + ggplot2::theme(
        text = ggplot2::element_text(family = metage_plot_font,
                                     size = base_size),
        axis.text = ggplot2::element_text(size = axis_text_size),
        axis.title = ggplot2::element_text(size = axis_title_size),
        legend.text = ggplot2::element_text(size = legend_text_size),
        legend.title = ggplot2::element_text(size = legend_title_size),
        plot.title = ggplot2::element_text(size = title_size,
                                           hjust = 0.5),
        plot.subtitle = ggplot2::element_text(hjust = 0.5)
    )
}
