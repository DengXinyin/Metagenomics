"""统一 Python/matplotlib 可视化样式配置。

字体通过 METAGE_PLOT_FONT 环境变量选择，默认 Times New Roman，
也可设置为 Arial。中文字符由 matplotlib 的后备字体处理。
"""

import os
from pathlib import Path


METAGE_PLOT_FONT = os.environ.get("METAGE_PLOT_FONT", "Times New Roman")
FONT_DIRS = (
    Path("/usr/share/fonts/msttcore"),
    Path("/usr/local/share/fonts"),
)


def register_matplotlib_fonts():
    """Register mounted fonts without relying on a stale matplotlib cache."""
    from matplotlib import font_manager

    for font_dir in FONT_DIRS:
        if not font_dir.is_dir():
            continue
        for pattern in ("*.ttf", "*.ttc", "*.otf"):
            for font_file in font_dir.glob(pattern):
                try:
                    font_manager.fontManager.addfont(str(font_file))
                except (OSError, RuntimeError):
                    continue


def apply_matplotlib_style(plt):
    """Apply the shared font and typography defaults to pyplot."""
    register_matplotlib_fonts()
    plt.rcParams.update({
        "font.family": METAGE_PLOT_FONT,
        "font.sans-serif": [METAGE_PLOT_FONT, "Arial", "DejaVu Sans"],
        "axes.titlesize": 22,
        "axes.labelsize": 18,
        "xtick.labelsize": 16,
        "ytick.labelsize": 16,
        "legend.fontsize": 18,
        "legend.title_fontsize": 20,
        "axes.unicode_minus": False,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    })
