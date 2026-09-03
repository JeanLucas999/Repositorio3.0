from abc import abstractmethod, ABC
from funcoes import *

class Item(ABC):
    #FAZER UM SETTER DA RARIDADE, FICA MELHOR DEMAIS
    def __init__(self, nome:str = ''):
        self.nome = nome
        self.raridade = None
        self.rarity()

    def rarity(self):
        print (f'Selecione a RARIDADE de "{self.nome}"')
        linha()
        print (f'1- {comum}\n2- {incomum}\n3- {rara}\n4- {epica}\n5- {lendaria}')
        self.resposta = int(input('SELECIONE: '))
        try:
            if isinstance(self.resposta, int):
                #TROCAR ISSO POR UMA LISTA COM AS OPCOES E UM FOR LISTANDO TODAS ELAS, SE RESPOSTA = 1 ENTAO LISTA[0]
                #POSSO USAR ISSO EM AMBOS COM A MESMA LISTA, APENAS PRECISO DE UM METODO PRA ELA AQ
                if 0 < self.resposta <= 5:

                    if self.resposta == 1:
                        self.raridade = comum
                    if self.resposta == 2:
                        self.raridade = incomum
                    if self.resposta == 3:
                        self.raridade = rara
                    if self.resposta == 4:
                        self.raridade = epica
                    if self.resposta == 5:
                        self.raridade = lendaria

                else:
                    raise ValueError
            else:
                raise TypeError

        except ValueError:
            print(f'{red}O valor precisa estar entre 1 e 5!!!{fecharcor}')
            linha()
            self.rarity()

        except TypeError:
            print(f'{red}O valor precisa ser um numero!!!{fecharcor}')
            linha()
            self.rarity
        finally:
            linha()

    @abstractmethod
    def informacoes(self):
        pass


class Acessorio(Item):
    def __init__(self, nome:str = ''):
        super().__init__(nome)
        self.espaco = ''
        self.space()

    #FAZER UMA FUNCAO PARA AUTOESCOLHER TIPO DE ITEM, POR EXEMPLO CAPA DO BB, TEM ***CAPA*** ENTAO COM CERTEZA FICA NAS COSTAS
    #SE NAO TIVER NADA ESPECIFICO SO ASSIM CHAMA A FUNCAO PARA ESCOLHER ONDE FICARA

    def space(self):
        print('Que espaco esse item ocupa?')
        linha()
        print('1- COSTAS\n2- OMBRO\n3- PESCOÇO\n4- ARMADURA\n5- CAPACETE')
        linha()
        self.resposta = int(input('NUMERO: '))
        linha()

        try:
            if isinstance(self.resposta, int):
                #TROCAR ISSO POR UMA LISTA COM AS OPCOES E UM FOR LISTANDO TODAS ELAS, SE RESPOSTA = 1 ENTAO LISTA[0]
                #POSSO USAR ISSO EM AMBOS COM A MESMA LISTA, APENAS PRECISO DE UM METODO PRA ELA AQ
                if 0 < self.resposta <= 5:

                    if self.resposta == 1:
                        self.espaco = 'Costas'
                    if self.resposta == 2:
                        self.espaco = 'Ombro'
                    if self.resposta == 3:
                        self.espaco = 'Pescoço'
                    if self.resposta == 4:
                        self.espaco = 'Armadura'
                    else:
                        self.espaco = 'Capacete'

                else:
                    raise ValueError
            else:
                raise TypeError

        except ValueError:
            print(f'{red}O valor precisa estar entre 1 e 5!!!{fecharcor}')
            linha()
            self.space()

        except TypeError:
            print(f'{red}O valor precisa ser um numero!!!{fecharcor}')
            linha()
            self.space()

    def informacoes(self):
        return f'Nome do acessorio: {self.nome}\nRaridade: {self.raridade}\nEspaço: {self.espaco}'


class Arma(Item):
    def __init__(self, nome:str = ''):
        super().__init__(nome)


class Fruta(Item):
    def __init__(self, nome:str = ''):
        super().__init__(nome)

    
oi = Acessorio('Capa do BB')
print (oi.informacoes())
