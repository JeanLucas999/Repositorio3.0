from abc import ABC, abstractmethod


class Funcionario(ABC):
    def __init__(self, nome:str = '', salario:int|float = 0):
        self.nome = nome
        self.__salario = 0
        self.salario = salario

    @property

    def salario(self):
        return self.__salario

    @salario.setter

    def salario(self, valor):
        try:
            if valor>self.__salario:
                self.__salario = valor
            else:
                raise ValueError

        except:
            print ('NAO E POSSIVEL DIMINUIR O SALARIO DE UM FUNCIONARIO')

    def __str__(self):
        return (f'{self.nome} eh {type(self).__name__}, recebe {self.salario} e seu bonus eh de {self.calcular_bonus()}')

    @abstractmethod

    def calcular_bonus(self):
        pass

class Gerente(Funcionario):
    def __init__(self, nome, salario):
        super().__init__(nome, salario)
        self.nome = nome

    def calcular_bonus(self):
        return self.salario*0.20


class Designer(Funcionario):
    def __init__(self, nome, salario):
        super().__init__(nome, salario)
        self.nome = nome

    def calcular_bonus(self):
        return self.salario*0.10


class Desenvolvedor(Funcionario):
    def __init__(self, nome, salario):
        super().__init__(nome, salario)
        self.nome = nome

    def calcular_bonus(self):
        return self.salario*0.10