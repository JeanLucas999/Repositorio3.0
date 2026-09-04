from abc import ABC, abstractmethod


class BebidaQuente(ABC):
    def __init__(self):
        pass
    def preparar(self):
        print (f'1-{self.ferver()}')
        print (f'2-{self.misturar()}')
        print (f'3-{self.servir()}')

    def ferver(self):
        return 'Fervendo a agua a 100 graus...'

    @abstractmethod
    def misturar(self):
        pass

    def servir(self):
        pass

class Cha(BebidaQuente):
    def __init__(self):
        pass
    
    def misturar(self):
        return 'Colocando as ervas na agua...'

    def servir(self):
        return 'Colocando na xicara de cha...'


class Cafe(BebidaQuente):
    def __init__(self):
        pass

    def misturar(self):
        return 'Colocando po na agua...'

    def servir(self):
        return 'Colocando na xicara de cafe'

class CafeComLeite(BebidaQuente):
    def __init__(self):
        pass

    def misturar(self):
        return 'Colocando o cafe no leite'

    def servir(self):
        return 'Servindo o cafe com leite'


b1 = Cha()

b1.preparar()