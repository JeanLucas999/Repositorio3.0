from triang import Retangulo
from rich import inspect

def main():
    b = Retangulo(5, 6)
    b.altura = 10
    b.base = 12
    print (b.medidas)
    inspect(b, private=True)
    
if __name__=='__main__':
    main()