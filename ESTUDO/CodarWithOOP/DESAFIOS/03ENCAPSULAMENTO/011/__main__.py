from termostato import Termostato
from rich import inspect

def main():
    Oi = Termostato()
    Oi.mudartemp = 3
    print (Oi.mudatemp)
    inspect (Oi, private=True, methods=True)

if __name__=='__main__':
    main()