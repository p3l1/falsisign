#!/usr/bin/env python
import tkinter as tk

CANVAS_WIDTH=210
CANVAS_HEIGHT=297
TARGET_WIDTH=2480
TARGET_HEIGHT=3508

root = tk.Tk()

def click(event):
    x_in_pixels = int(event.x/CANVAS_WIDTH*TARGET_WIDTH)
    y_in_pixels = int(event.y/CANVAS_HEIGHT*TARGET_HEIGHT)
    print(f"-x {x_in_pixels} -y {y_in_pixels}")
    root.destroy()

canvas = tk.Canvas(root, bg="gray", height=297, width=210)
canvas.pack()
canvas.bind("<Button-1>", click)
root.mainloop()
