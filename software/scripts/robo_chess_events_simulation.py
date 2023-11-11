from tkinter import *
import serial
import math
import json
import time

arduino = serial.Serial(port='/dev/ttyACM0', baudrate=9600, timeout=0)

root = Tk()
canvas = Canvas(root, width = 800, height = 800)
canvas.pack()

letters = ['x','8','7','6','5','4','3','2','1']

# Outputs board on terminal
def print_board(board):
  for i in range(0,8):
    print(board[i])
  print("\n\n")

# Creates board graphics
def get_board():

  for i in range(40,720,80):
    canvas.create_line(40,i,680,i,fill = "black")

  for i in range(40,720,80):
    canvas.create_line(i,40,i,680,fill = "black")

  canvas.create_line(17,17,17,703,fill = "black")
  canvas.create_line(17,17,703,17,fill = "black")
  canvas.create_line(17,703,703,703,fill = "black")
  canvas.create_line(703,17,703,703,fill = "black")

  for i in range(40,522,160):
    for j in range(120,602,160):
      canvas.create_rectangle(i,j,i+80,j+80,fill = "#5DAADA")

  for i in range(120,602,160):
    for j in range(40,522,160):
      canvas.create_rectangle(i,j,i+80,j+80,fill = "#5DAADA")

  for i in range(1,9):
    txt = Label(root,text = chr(96 + i),width = 1, height = 1)
    txt.place(x=80*i - 6,y=18)
    txt2 = Label(root,text = chr(96 + i),width = 1, height = 1)
    txt2.place(x=80*i - 6,y=681)
    txt3 = Label(root,text = letters[i])
    txt3.place(x=22,y=80*i - 9)
    txt4 = Label(root,text = letters[i])
    txt4.place(x=683,y=80*i - 9)

# Toggles the pick up position to 0 (Empty)
def pick_up(event):
  j = math.floor((event.x-40)/80)
  i = math.floor((event.y-40)/80)
  print(f"Pick up ({i}, {j})")
  arduino.write(bytes(json.dumps({"version": 1, "type": "event", "direction": "up", "square": i * 2**4 + j}) + "\n", 'utf-8'))


# Toggles the put down position to 1 (Full)
def put_down(event):
  j = math.floor((event.x-40)/80)
  i = math.floor((event.y-40)/80)
  print(f"Put down ({i}, {j})")
  arduino.write(bytes(json.dumps({"version": 1, "type": "event", "direction": "down", "square": i * 2**4 + j}) + "\n", 'utf-8'))

def submit_move():
  print("Submit")
  arduino.write(bytes(json.dumps({"version": 1, "type": "event", "direction": "up", "square": 256}) + "\n", 'utf-8'))
  time.sleep(.5)
  print(arduino.readline())

def read_arduino_serial():
  while (char := arduino.read()):
    print(char.decode("utf-8"), end="")
  root.after(100, read_arduino_serial)


get_board()
canvas.bind("<Button-1>", pick_up)
canvas.bind("<Button-2>", put_down)
clk = Button(root, text="clock", command = submit_move)
clk.pack()
root.after(100, read_arduino_serial)
root.mainloop()