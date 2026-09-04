from random import randint

def somapar(lis):
    '''
    SOMA TUDO LEGAL BONITO
    
    
    
    
    '''
    sp = 0
    for c in lis:
        if c % 2 == 0:
            sp += c
    print (f'A SOMA DOS PARES VALE {sp}')

def sorteio():
    for c in range (5):
        numeros.append(randint(0,10))

numeros = []

sorteio()

print (numeros)

somapar(numeros)

help(somapar)
