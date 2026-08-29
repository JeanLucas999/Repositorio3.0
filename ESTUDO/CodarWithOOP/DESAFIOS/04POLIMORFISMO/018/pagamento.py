# REFAZ FDS
from abc import ABC, abstractmethod
class Pagamento(ABC):
    def __init__(self):
        self.__valor = None
        self.fvalor = None

    @property
    def pagarset(self):
        return  self.__valor

    @pagarset.setter
    def pagarset(self, valor):
        try:
            if valor>=0:
                self.__valor = valor
                self.fvalor = f'R${self.__valor:.2f}'
            else:
                raise ValueError
        except:
            print ('ERRO!!!')

    @abstractmethod
    def pagar(self):
        pass

class Pix(Pagamento):
    def __init__(self):
        super().__init__()

    def pagar(self, valor):
        self.pagarset = valor
        print(f'VOCE PAGOU {self.fvalor} COM {__class__.__name__}')


class Boleto(Pagamento):
    def __init__(self):
        super().__init__()

    def pagar(self, valor):
        self.pagarset = valor
        print(f'VOCE PAGOU {self.fvalor} COM {__class__.__name__}')

def pagamento(classe:str = Pix, valor:int|float = 0):
    try:
        if classe.upper() == 'PIX' or classe.upper() == 'BOLETO':
            if classe.upper() == 'PIX':
                objeto = Pix()
            else:
                objeto = Boleto()
        objeto.pagar(valor)
    except:
        print ('NAO E POSSIVEL PAGAR')

a = Pix()

pagamento('Pix', 2000)