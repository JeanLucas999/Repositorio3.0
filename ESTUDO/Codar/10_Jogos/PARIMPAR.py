from random import randint, choice
from time import sleep

jogada = 1
pi = ('par', 'impar')
vc = 0
ia = 0
re = 'a'

while True:
    if jogada%2 != 0:
        while re not in ('PAR', 'IMPAR'):
            re = (input('Par ou Impar? ')).strip().upper()
            sleep(2)
        print (f'VOCE ESCOLHEU {re}')
        print ('-'*30)
        
    else:
        print ('AGORA EH A VEZ DA IA:')
        sleep(3)
        print ('IA PENSANDO...')
        sleep(2)
        re = choice(pi).upper()
        print (f'IA ESCOLHEU {re}')
        print ('-'*30)
    vcj = int(input('DIGITE SEU NUMERO: '))
    print (f'VOCE ESCOLHEU {vcj}')
    print ('-'*30)

    iaj = int(randint(0, 10))
    print('IA PENSANDO...')
    sleep(2)
    print (f'A IA ESCOLHEU O NUMERO {iaj}')
    print ('-'*30)

    soma = iaj+vcj
    sleep(1)
    if soma%2 == 0:
        print (f'{soma} eh par')
        resultado = 'PAR'
    else:
        print (f'{soma} eh impar')
        resultado = 'IMPAR'
    
    sleep(1)
    if re == resultado:
        if jogada%2 != 0:
            vc += 1
            print ('VOCE VENCEU')
        else:
            ia += 1
            print ('VOCE PERDEU')
    else:
        if jogada % 2 != 0:
            ia += 1
            print('VOCE PERDEU')
        else:
            vc += 1
            print('VOCE VENCEU')
    re = 'a'
    jogada += 1

    if (ia>vc):
        sleep(1)
        print ('-'*30)
        print ('VOCE ESTA SENDO AMASSADO PELA IA')
        print (f'COM {ia-vc} PONTO DE DIFERENCA')
        print (f'{vc} para VOCE e {ia} para a IA')
        print ('-'*30)
    elif (vc>ia):
        sleep(1)
        print ('-'*30)
        print ('VOCE ESTA GANHANDO DA IA')
        print (f'COM {vc-ia} PONTO DE DIFERENCA')
        print (f'{vc} para VOCE e {ia} para a IA')
        print ('-'*30)
    else:
        sleep(1)
        print ('-'*30)
        print ('TUDO IGUAL NO PLACAR')
        print (f'{vc} para VOCE e {ia} para a IA')
        print ('-'*30)

    sleep(2)
    cont = (input('QUER CONTINUAR? [S/N]: ')).upper()
    if cont != 'S':
        break

sleep(2)
print ('-'*30)
print ('FIM DE JOGO')
if ia>vc:
    print ('PERDEU PRA IA KKKKKKKKKKKKK')
elif ia==vc:
    print ('EMPATE.')
else:
    print ('FEZ O MINIMO KKKKKKKKKKKKK')
print ('-'*30)