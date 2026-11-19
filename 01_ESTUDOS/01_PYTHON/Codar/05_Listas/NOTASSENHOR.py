gurizada = []
notudos = []
re = ''
med = []

vermelho = '\033[1;31m'
verde = '\033[1;32m'

while re != 'N' and re != 'n':
    gurizada.append((str(input('DIGITE O NOME DO ALUNO: '))).upper())
    gurizada.append(float(input('AGORA SUA PRIMEIRA NOTA: ')))
    gurizada.append(float(input('AGORA SUA SEGUNDA NOTA: ')))
#gurizada.append([nome, nota1, nota 2])

    media = (gurizada[1]+gurizada[2])/2
    gurizada.append(media)

    notudos.append(gurizada[:])
    gurizada.clear()

    re = input('QUER CONTINUAR? [S/N]: ')
    print ('-'*35)
    print ('')

while True:
    print (f'{'NO.':<2} {'NOME':<15} MEDIA')
    print ('-'*25)

    for p, c in enumerate(notudos):

        if c[3]>=6:
            cor = verde
        else:
            cor = vermelho

        print(f'{p+1:<3} {c[0]:<15} {cor}{c[3]}\033[m')
    print ('-'*25)

    re2 = int(input('NO. DO ALUNO PARA MOSTRAR SUAS NOTAS (999 para sair):  '))
    if re2 == 999:
        break
    elif re2<len(notudos)+1 and re2 != 0:
        print (f'AS NOTAS DE {notudos[re2-1][0]} FORAM: {notudos[re2-1][1]} E {notudos[re2-1][2]}')
    else:
        print ('ALUNO NAO CADASTRADO')
    print ('-'*25)