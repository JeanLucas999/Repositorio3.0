from item import *
from funcoes import *
from time import sleep


def menuInicial():
    linha()
    print(f'{green}            Menu             {fecharcor}')
    linha()
    print (f'{red}O que deseja fazer?{fecharcor}')
    print (f'{purple}1- Adicionar item\n2- Remover item\n3- Consultar itens\n4- Pesquisar itens?\n5- Filtrar\n6- Sair{fecharcor}')
    resposta = int(input(f'{yellow}Numero: {fecharcor}'))
    linha()

    try:
        if 0 < resposta <= 6:
            #SE FOR ADICIONAR ITEM
            if resposta == 1:

                nome = str(input(f'{green}Digite o nome do item: {fecharcor}'))

                print (f'{red}O que é {nome}?{fecharcor}')
                print (f'{purple}1- Fruta\n2- Arma\n3- Acessorio{fecharcor}')
                addres = int(input(f'{yellow}Numero: {fecharcor}'))
                linha()

                #TIPO DE ITEM
                try:

                    if addres == 1:
                        obj = Fruta(nome)
                        objetos.append(obj)
                        print (obj.informacoes())

                    elif addres == 2:
                        obj = Arma(nome)
                        objetos.append(obj)
                        print (obj.informacoes())

                    elif addres == 3:
                        obj = Acessorio(nome)
                        objetos.append(obj)
                        print (obj.informacoes())

                    else:
                        raise ValueError

                    print (f'\n{green}Item adicionado!!!{fecharcor}')
                except:
                    print(f'\n{red}ERRO!!!{fecharcor}')
                finally:
                    sleep(0.5)
                    menuInicial()

            if resposta == 2:
                #REMOVER ITEM
                mostrarLista()
                linha()
                rem = int(input(f'{blue}Digite o item que deseja remover[0 para retornar]:{fecharcor} '))

                try:

                    if rem > 0 and rem <= len(objetos):
                        del(objetos[rem-1])
                        print (objetos)

                    elif rem == 0:
                        print('Voltando para o menu...')
                        sleep(0.5)
                        menuInicial
                    else:
                        raise ValueError
                    
                except:
                    print (f'O numero deve estar entre 0 e {len(objetos)}')
                pass

            if resposta == 3:
                #CONSULTAR
                pass

            if resposta == 4:
                #PESQUISAR
                pass

            if resposta == 5:
                #FILTRAR
                pass

            if resposta == 6:
                print (f'{yellow}Você escolheu sair!{fecharcor}')
        else:
            raise ValueError
    except:
        print('ERRO!!!')
    #FUNCAO SOLTA

def mostrarLista():
    try:
        if len(objetos)>0:
            for i, c in enumerate(objetos, start=1):
                print(f'{red}{i}{fecharcor}- {c.nome}, {c.__class__.__name__}')
        else:
            raise LookupError
    except:
        print(f'{red}Ainda não existem itens no inventario{fecharcor}')
        sleep(0.5)
        menuInicial()

quantidade = 0
nome = ''
objetos = []

def main():
    menuInicial()


if __name__=='__main__':
    main()