from abc import ABC, abstractmethod

class Animal(ABC):
    def __init__(self, nome:str = ''):
        self.nome = nome

    @abstractmethod

    def emitirSom(self):
        #print(f'{self.nome} e {self.__class__.__name__} e esta fazendo barulho')
        pass

class Pato(Animal):
    def emitirSom(self):
        print (f'{self.nome} fez QUACK')

class Cachorro(Animal):
    def emitirSom(self):
        print (f'{self.nome} disse AU AU AU')

class Spitz(Cachorro):
    pass

class Pitbull(Cachorro):
    def emitirSom(self):
        print (f'{self.nome} fez WHOOOOOF WHOOOOF')
class Galinha(Animal):
    def emitirSom(self):
        print(f'{self.nome} fez POPOPOOOOOOOOOOOOOOOO')

class Gato(Animal):
    def emitirSom(self):
        print (f'{self.nome} acabou de dizer MIAU')
