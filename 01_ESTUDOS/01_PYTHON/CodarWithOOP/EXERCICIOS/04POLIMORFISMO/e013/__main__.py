from classes import *

def main():
    x = Analisador()
    x.analisar(3)
    x.analisar('Python')
    x.analisar(8.5)
    x.analisar((8, 5, 2))
    x.analisar(len(8, 5, 2))
    pass


if __name__ == '__main__':
    main()