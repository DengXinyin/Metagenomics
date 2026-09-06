# -*- coding: utf-8 -*
import fitz
import os


def pdf2png(pic):
    try:
        pdfDoc = fitz.open(pic)
        zoom_x = 4
        zoom_y = 4
        mat = fitz.Matrix(zoom_x, zoom_y)
        pix = pdfDoc[0].get_pixmap(matrix=mat)
        png = pic.split('.pdf')[0] + '.png'
        pix.save(png)
    except fitz.fitz.EmptyFileError:
        print('无法打开' + pic)
        os.remove(pic)


def changefile(path):
    g = os.walk(path)
    for path, dir_list, file_list in g:
        for file_name in file_list:
            file = os.path.join(path, file_name)
            if file.endswith("pdf"):
                print(file)
                pdf2png(file)
            if file.endswith("png"):
                continue


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description="pdf2png")
    parser.add_argument("-resDir", required=True, type=str, help="resDir path")
    args = parser.parse_args()
    resDir = os.path.abspath(args.resDir)
    changefile(resDir)
