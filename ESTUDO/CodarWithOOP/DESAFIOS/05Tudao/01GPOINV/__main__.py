from item import *
from funcoes import *

def menuInicial():
    linha()
    print(f'{green}            Menu             {fecharcor}')
    linha()
    print (f'{red}O que deseja fazer?{fecharcor}')
    print (f'{purple}1- Adicionar item\n2- Remover item\n3- Consultar itens\n4- Pesquisar itens?\n5- Filtrar{fecharcor}')
    resposta = int(input(f'{yellow}Numero: {fecharcor}'))
    linha()

    try:
        if 0 < resposta <= 5:
            if resposta == 1:
                nome = str(input(f'{green}Digite o nome do item: {fecharcor}'))

                print (f'{red}O que é {nome}?{fecharcor}')
                print (f'{purple}1- Fruta\n2- Arma\n3- Acessorio{fecharcor}')
                addres = int(input(f'{yellow}Numero: {fecharcor}'))
                linha()
        else:
            raise ValueError
    except:
        print('ERRO!!!')

        try:
            if addres == 1:
                obj = Fruta({nome})
                print (obj.informacoes())
            if addres == 2:
                obj = Arma()
                print (obj.informacoes())
            if addres == 3:
                obj = Acessorio()
                print (obj.informacoes())
            else:
                raise ValueError
        except:
            print('ERRO!!!')


quantidade = 0
nome = ''
objetos = []
def main():
    menuInicial()

if __name__=='__main__':
    main()