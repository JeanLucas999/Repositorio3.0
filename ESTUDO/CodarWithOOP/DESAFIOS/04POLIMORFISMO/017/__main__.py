from arquivos import *
from rich import inspect

def main():
    a = PDF('Jean', 1000)
    inspect(a, methods=True, private=True)
    abrir(a)
    pass

if __name__ == '__main__':
    main()