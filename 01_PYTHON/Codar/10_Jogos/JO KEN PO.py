from random import choice
from time import sleep

pia = 0
pvc = 0
lista = ('TESOURA', 'PEDRA', 'PAPEL')
continuar = True
while continuar:
    print ('Vamos jogar JO KEN PO')
    print ('''[ 1 ] PARA TESOURA
[ 2 ] PARA PEDRA
[ 3 ] PARA PAPEL''')

    re = int(input('JOGUE SUA MAO: '))
    if re == 1:
        vc = ('TESOURA')
    elif re == 2:
        vc = ('PEDRA')
    elif re == 3:
        vc = ('PAPEL')
    else:
        print ('VOCE NAO ESCOLHEU NADA, A IA ESCOLHERA POR VOCE')
        vc = choice(lista)
    print ('Voce escolheu')
    print (vc)
    print ('')

    ia = choice(lista)
    print ('A escolha da IA foi...')
    sleep(1)
    print (ia)

    print ('')
    sleep(1)
    if vc == ('TESOURA') and ia == ('PAPEL'):
        print ('VOCE VENCEU!!!')
        pvc += 1
    elif vc == ('PAPEL') and ia == ('PEDRA'):
        print ('VOCE VENCEU!!!')
        pvc += 1
    elif vc == ('PEDRA') and ia == ('TESOURA'):
        print ('VOCE VENCEU!!!')
        pvc += 1
    elif vc == ia:
        print ('Merda de empate')
    else:
        print ('PERDEU BURRAOKKKKKKKKK')
        pia += 1
    
    sleep(1)
    print ('')
    print (f'PONTOS DO JOGADOR: {pvc}')
    print (f'PONTOS DA MAQUINA: {pia}')

    sleep(1)
    print ('')
    print ('Quer continuar? [S/N]')
    dnv = input('')
    if dnv.upper() != 'S':
        continuar = False