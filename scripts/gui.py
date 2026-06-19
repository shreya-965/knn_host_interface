import tkinter as tk

from uart import UARTInterface

uart = UARTInterface("fgpa-com")      # Change to the FPGA COM port

root = tk.Tk()
root.title("KNN Host Utility")


def run_dataset():

    uart.run_default_dataset()

    print("Run command sent")

    while True:

        value = uart.read_byte()

        if value is None:
            break

        print("Prediction :", value)


button = tk.Button(
    root,
    text="Run Default Dataset",
    command=run_dataset,
    width=30,
    height=2
)

button.pack(padx=20, pady=20)

root.mainloop()