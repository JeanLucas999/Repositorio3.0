vermelho = '\33[31m'
verde = '\33[32m'
azul = '\33[34m'
fechar = '\33[m'

def linha():
    print ('-'*40)

def pessoaidade():
    guy = {}
    while True:
        try:
           guy['IDADE'] =  int(input(f'{verde}DIGITE A IDADE: {fechar}'))
        except:
            print ('ERRO!!!, DIGITE UMA IDADE VALIDA')
        else:
            return guy['IDADE']
            

def main():
    linha()
    print (f'{"MENU PRINCIPAL":^40}')
    linha()

    print (f'{vermelho}1{fechar} - {verde}Ver pessoas cadastradas{fechar}')
    print (f'{vermelho}2{fechar} - {verde}Cadastrar novas pessoas{fechar}')
    print (f'{vermelho}3{fechar} - {verde}Sair do sistema {fechar}')
    linha()

def opcao1():
    linha()
    print (f'{"OPCAO 1":^40}')
    linha()

def opcao2():
    linha()
    print (f'{"OPCAO 2":^40}')
    linha()

def escreve(guri):
    with open('dados.txt', 'a') as arq:
        arq.write(f'{guri["NOME"]:<30} {guri["IDADE"]:>3} ANOS \n')