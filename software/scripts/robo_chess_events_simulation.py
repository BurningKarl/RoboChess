from tkinter import *
import serial
import math
import json
import time

arduino = serial.Serial(port='/dev/ttyACM0', baudrate=9600, timeout=.1)

root = Tk()
canvas = Canvas(root, width = 800, height = 800)
canvas.pack()

board = [[0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0]]

letters = ['x','8','7','6','5','4','3','2','1']

move_sequence = []

def board_init(board):
  board = [[1,1,1,1,1,1,1,1],
         [1,1,1,1,1,1,1,1],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [0,0,0,0,0,0,0,0],
         [1,1,1,1,1,1,1,1],
         [1,1,1,1,1,1,1,1]]
  return board

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
  print("Pick up")
  global board
  global move_sequence
  j = math.floor((event.x-40)/80)
  i = math.floor((event.y-40)/80)
  arduino.write(bytes(json.dumps({"version": 1, "type": "event", "direction": "up", "square": i * 2**4 + j}) + "\n", 'utf-8'))
  board[i][j] = 0
  move_sequence.append([i,j,0])
  print_board(board)


# Toggles the put down position to 1 (Full)
def put_down(event):
  print("Put down")
  global board
  global move_sequence
  j = math.floor((event.x-40)/80)
  i = math.floor((event.y-40)/80)
  arduino.write(bytes(json.dumps({"version": 1, "type": "event", "direction": "down", "square": i * 2**4 + j}) + "\n", 'utf-8'))
  board[i][j] = 1
  move_sequence.append([i,j,1])
  print_board(board)

def submit_move():
  global move_sequence
  up = 0
  down = 0
  for i in move_sequence:
    if i[2] == 1:
      down += 1
    else:
      up += 1

  if up - down == 1:
    print("Take")
  elif up - down == 0:
    print("Move")
  else:
    print("Invalid")
  move_sequence = []

  arduino.write(bytes(json.dumps({"version": 1, "type": "event", "direction": "up", "square": 256}) + "\n", 'utf-8'))
  time.sleep(.5)
  print(arduino.readline())



get_board()
board = board_init(board)
canvas.bind("<Button-1>", pick_up)
canvas.bind("<Button-2>", put_down)
clk = Button(root, text="clock", command = submit_move)
clk.pack()
root.mainloop()