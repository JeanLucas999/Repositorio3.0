nu1 = int(input('Digite um numero para fazer as conversoes: '))
erro = False

print('''Escolha a conversao que voce quer fazer
[ 1 ] para binario
[ 2 ] para octal
[ 3 ] para hexadecimal''')

while erro == False:
    re = int(input('Sua escolha: '))

    if re == 1:
        print(f'{nu1} em binario eh {bin(nu1)[2:]}')
        erro = True

    elif re == 2:
        print(f'{nu1} em octal eh {oct(nu1)[2:]}')
        erro = True

    elif re == 3:
        print(f'{nu1} em hexadecimal eh {hex(nu1)[2:]}')
        erro = True

    else:
        print("ERRO!!!, digite uma opcao valida")