re = int
print ('---------------------------------------')
nu1 = int(input('DIGITE O PRIMEIRO NUMERO: '))
nu2 = int(input('DIGITE O SEGUNDO NUMERO: '))

while re != 5:
    print ('---------------------------------------')
    re = int(input('''O que quer fazer com esses numeros?
    [ 1 ] somar
    [ 2 ] multiplicar
    [ 3 ] maior
    [ 4 ] trocar
    [ 5 ] sair
    '''))

    if re == 1:
        nu3 = nu1+nu2
        print (f'A soma de {nu1} e {nu2} eh {nu3}')
    elif re == 2:
        nu3 = nu1*nu2
        print (f'A multiplicacao entre {nu1} e {nu2} eh {nu3}')
    elif re == 3:
        if nu1>nu2:
            print (f'{nu1} eh maior que {nu2}')
        elif nu2>nu1:
            print (f'{nu2} eh maior que {nu1}')
        else:
            print ('Ambos tem o mesmo valor')
    elif re == 4:
        print ('---------------------------------------')
        nu1 = int(input('DIGITE O PRIMEIRO NUMERO: '))
        nu2 = int(input('DIGITE O SEGUNDO NUMERO: '))
        print ('---------------------------------------')
    elif re == 5:
        print ('VOCE QUIS SAIR')
