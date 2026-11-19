#def area():
    #print('  CONTROLE DE TERRENO  ')
    #print ('-'*len('  CONTROLE DE TERRENO  '))
    #l = int(input('LARGURA(M): '))
    #a = int(input('ALTURA(M): '))
    #print (f'A area do terreno {l}x{a} eh de: {l*a} ')


#area()

def area(n1, n2):
    a = n1 * n2
    print (f'A area de {n1}x{n2} eh {a}')

print('  CONTROLE DE TERRENO  ')
print ('-'*len('  CONTROLE DE TERRENO  '))
l = float(input('LARGURA(M): '))
a = float(input('ALTURA(M): '))
area (l, a)