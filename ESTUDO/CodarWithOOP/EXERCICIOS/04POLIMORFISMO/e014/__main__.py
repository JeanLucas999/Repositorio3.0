from classes import *

def main():
    c1 = Carteira(100)
    c2 = Carteira(100)

    if (c1 == c2):
        print ('Valor igual')
    else:
        print ('Valor diferente')
        
    c1 += 50
    print (c1)

if __name__ == '__main__':
    main()