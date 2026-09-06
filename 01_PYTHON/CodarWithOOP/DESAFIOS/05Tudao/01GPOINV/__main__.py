from item import *
from funcoes import *
from time import sleep


def menuInicial():
    #Parar de chamar varios menus e trocar por um WHILE TRUE
    rodando = True
    while rodando:
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

                    resposta = 0

                if resposta == 2:
                    #REMOVER ITEM
                    mostrarLista()
                    linha()
                    remove = int(input(f'{blue}Digite o item que deseja remover[0 para retornar]:{fecharcor} '))

                    try:

                        if remove > 0 and remove <= len(objetos):
                            del(objetos[remove-1])
                            print (objetos)

                        elif remove == 0:
                            print('Voltando para o menu...')
                            sleep(0.5)
                        else:
                            raise ValueError
                        
                    except:
                        print (f'O numero deve estar entre 0 e {len(objetos)}')
                    resposta = 0

                if resposta == 3:
                    #CONSULTAR
                    recon = ''

                    mostrarLista()
                    while recon.upper() != 'S' and recon.upper() != 'N':
                        recon = str(input(f'{green}Quer voltar pro menu inicial [S/N]?{fecharcor} '))
                    if recon.upper() == 'N':
                        break


                    resposta = 0

                if resposta == 4:
                    #PESQUISAR
                    resposta = 0

                if resposta == 5:
                    #RESOLVER ISSO
                    print('O QUE DESEJA FILTRAR?')
                    filtrores = int(input('\n1- Frutas\n2- Armas\n3- Acessorios\nDigite o numero:'))
                    try:
                        print('CHEGUEI')
                        print (filtrores)
                        if 0 < filtrores <= 3:
                            print ('if1')
                            if filtrores == 1:
                                filtrar('fruta')
                            if filtrores == 2:
                                filtrar('arma')
                            if filtrores == 3:
                                filtrar('acc')
                    except:
                        print ('ERRO!!!')
                    resposta = 0

                if resposta == 6:
                    print (f'{yellow}Você escolheu sair!{fecharcor}')
                    rodando = False

            else:
                raise ValueError
        except:
            print('ERRO!!!')

def mostrarLista():
    try:
        if filtro == 'sem':

            if len(objetos)>0:
                print (f'{green}SEM FILTRO!!!{fecharcor}')
                linha()
                for i, c in enumerate(objetos, start=1):
                    print(f'{red}{i}{fecharcor}- {c.nome}, {c.__class__.__name__}')
            else:
                raise LookupError
            
        if filtro == 'fruta':

            if len(frutas)>0:
                print (f'{green}FILTRANDO FRUTAS!!!{fecharcor}')
                linha()
                for i, c in enumerate(frutas, start=1):
                    print(f'{red}{i}{fecharcor}- {c.nome}, {c.tipo}')
            else:
                raise LookupError

        if filtro == 'acc':

            if len(acc)>0:
                print (f'{green}FILTRANDO ACESSORIOS!!!{fecharcor}')
                linha()
                for i, c in enumerate(acc, start=1):
                    print(f'{red}{i}{fecharcor}- {c.nome}, {c.espaco}')
            else:
                raise LookupError

        if filtro == 'arma':

            if len(armas)>0:
                print (f'{green}FILTRANDO ARMAS!!!{fecharcor}')
                linha()
                for i, c in enumerate(armas, start=1):
                    print(f'{red}{i}{fecharcor}- {c.nome}, {c.tipo}')
            else:
                raise LookupError

    except:
        print(f'{red}Ainda não existem itens desse filtro no inventario{fecharcor}')
        sleep(0.5)


def filtrar(tipo):
    global filtro, frutas, armas, acc
    if tipo.upper() == 'FRUTA':
        frutas = list(filter(filtrarfruta, objetos))
        filtro = 'fruta'
    if tipo.upper() == 'ARMA':
        armas = list(filter(filtrararma, objetos))
        filtro = 'arma'
    if tipo.upper() == 'ACC':
        acc = list(filter(filtraracc, objetos))
        filtro = 'acc'


def filtrarfruta(item):
    if item.__class__.__name__ == 'Fruta':
        return True
    else:
        return False

def filtrararma(item):
    if item.__class__.__name__ == 'Arma':
        return True
    else:
        return False

def filtraracc(item):
    if item.__class__.__name__ == 'Acessorio':
        return True
    else:
        return False


nome = ''

objetos = []
frutas = []
armas = []
acc = []

filtro = 'sem'

def main():
    menuInicial()


if __name__=='__main__':
    main()