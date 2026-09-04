from abc import abstractmethod, ABC
from funcoes import *

class Item(ABC):
    def __init__(self, nome:str = ''):
        self.nome = nome
        self.raridade = None
        self.listararidade = [comum, incomum, rara, epica, lendaria]
        self.rarity()

    def rarity(self):
        print (f'Selecione a RARIDADE de "{self.nome}"')
        linha()
        print (f'1- {comum}\n2- {incomum}\n3- {rara}\n4- {epica}\n5- {lendaria}')
        self.resposta = int(input('SELECIONE: '))
        try:
            if isinstance(self.resposta, int):
                if 0 < self.resposta <= 5:
                    self.opcoesrar(self.listararidade, self.resposta)

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

    def opcoesrar(self, lista, pedido):
        self.raridade = lista[pedido-1]


    @abstractmethod
    def informacoes(self):
        pass


class Acessorio(Item):
    def __init__(self, nome:str = ''):
        super().__init__(nome)
        self.espaco = ''
        self.listaespaco = ['COSTAS', 'OMBRO', 'PESCOÇO', 'ARMADURA', 'CAPACETE']
        self.space()

    def space(self):
        print('Que espaco esse item ocupa?')
        linha()
        print('1- COSTAS\n2- OMBRO\n3- PESCOÇO\n4- ARMADURA\n5- CAPACETE')
        linha()
        self.resposta = int(input('NUMERO: '))
        linha()

        try:
            if isinstance(self.resposta, int):
                if 0 < self.resposta <= 5:
                    self.opcoes(self.listaespaco, self.resposta)

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
        return f'{green}Nome do acessorio{fecharcor}: {self.nome}\n{red}Raridade{fecharcor}: {self.raridade}\n{yellow}Tipo{fecharcor}: {self.espaco}'

    def opcoes(self, lista, pedido):
        self.espaco = lista[pedido-1]


class Arma(Item):
    def __init__(self, nome:str = ''):
        super().__init__(nome)
        self.listatipo = ['Espada', 'Arma', 'Arma de Força']
        self.tipo = ''
        self.type()

    def type(self):
        print ('Qual o tipo da arma?')
        linha()
        print ('1- Espada\n2- Arma\n3- Arma de força')
        linha()
        self.resposta = int(input('DIGITE O NUMERO: '))
        linha()

        try:
            if isinstance(self.resposta, int):
                if 0 < self.resposta <= 3:
                    self.opcoes(self.listatipo, self.resposta)

                else:
                    raise ValueError
            else:
                raise TypeError

        except ValueError:
            print(f'{red}O valor precisa estar entre 1 e 3!!!{fecharcor}')
            linha()
            self.space()

        except TypeError:
            print(f'{red}O valor precisa ser um numero!!!{fecharcor}')
            linha()
            self.space()

        
    def opcoes(self, lista, pedido):
        self.tipo = lista[pedido-1]

    def informacoes(self):
        return f'{green}Nome da arma{fecharcor}: {self.nome}\n{red}Raridade{fecharcor}: {self.raridade}\n{yellow}Tipo{fecharcor}: {self.tipo}'

class Fruta(Item):
    def __init__(self, nome:str = ''):
        super().__init__(nome)
        self.tipo = ''
        self.listatipo = ['Logia', 'Paramecia', 'Zoan']
        self.type()

    def type(self):
        print ('Qual o tipo da arma?')
        linha()
        print ('1- Logia\n2- Paramecia\n3- Zoan')
        linha()
        self.resposta = int(input('DIGITE O NUMERO: '))
        linha()

        try:
            if isinstance(self.resposta, int):
                if 0 < self.resposta <= 3:
                    self.opcoes(self.listatipo, self.resposta)

                else:
                    raise ValueError
            else:
                raise TypeError

        except ValueError:
            print(f'{red}O valor precisa estar entre 1 e 3!!!{fecharcor}')
            linha()
            self.space()

        except TypeError:
            print(f'{red}O valor precisa ser um numero!!!{fecharcor}')
            linha()
            self.space()

        
    def opcoes(self, lista, pedido):
        self.tipo = lista[pedido-1]

    def informacoes(self):
        return f'{green}Nome da fruta{fecharcor}: {self.nome}\n{red}Raridade{fecharcor}: {self.raridade}\n{yellow}Tipo{fecharcor}: {self.tipo}'
