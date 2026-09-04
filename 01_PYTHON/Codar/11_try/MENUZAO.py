from PACOTAO import menu
from time import sleep

erros = 0
vermelho = '\33[31m'
verde = '\33[32m'
azul = '\33[34m'
fechar = '\33[m'

pessoas = []
pessoa = {}
parou = False

menu.main()
while True:
    try:
        re = int(input(f'{azul}Sua opcao: {fechar}'))
        if re>3:
            raise ValueError('OPCAO INEXISTENTE')
        erros = 0

    except (TypeError, ValueError):
        print (f'{vermelho}ERRO!!! Digite um NUMERO VALIDO{fechar}')
        erros += 1
        if erros == 2:
            erros = 0
            menu.main()

    else:
        if re == 1:
            menu.opcao1()

            try:
                with open('dados.txt', 'r') as arq:
                    print(f'{arq.read()}')
                    menu.linha()
            except:
                print (f'{vermelho} AINDA NAO HA PESSOAS CADASTRADAS!!!{fechar}')
                menu.linha()
            sleep(0.5)
            menu.main()

        if re == 2:
            menu.opcao2()

            pessoa['NOME'] = input(f'{verde}DIGITE O NOME DA PESSOA: {fechar}')
            if pessoa['NOME'] == '':
                pessoa['NOME'] = 'NOME NAO ESPECIFICADO'
            pessoa['IDADE'] = menu.pessoaidade()

            menu.escreve(pessoa)    

            menu.main()

        if re == 3:
            menu.linha()
            print(f'{"SAINDO DO PROGRAMA...":^40}')
            menu.linha()
            break