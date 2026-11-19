class Carteira:
    def __init__(self, valor:int|float = 0):
        self.__saldo = valor
        pass

    def __str__(self):
        return f'Voce tem {self.__saldo}'
    
    @property
    def saldo(self):
        return self.__saldo

    saldo.setter
    def saldo(self, valor):
        raise PermissionError

    def __eq__(self, outro):
        if self.__saldo == outro.__saldo:
            return True
        else:
            return False

    def __iadd__(self, valor: int|float):
        self.__saldo = self.__saldo + valor

    def __isub__(self, valor: int|float):
        self.__saldo = self.__saldo - valor