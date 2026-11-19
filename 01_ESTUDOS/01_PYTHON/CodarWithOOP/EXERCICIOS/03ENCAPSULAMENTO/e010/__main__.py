from avaliacao2 import Avaliacao
from rich import print, inspect

def main():
    av1 = Avaliacao('Pedro', 'Mat')
    av1.mudarnota = 3.5
    inspect (av1, private=True)
    print (av1.mudarnota)
    pass

if __name__ == '__main__':
    main()