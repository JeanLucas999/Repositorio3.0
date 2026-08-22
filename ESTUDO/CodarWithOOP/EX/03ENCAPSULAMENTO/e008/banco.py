class Conta:
    def __init__(self, nome, saldo = 0, id = 0):
        self.nome = nome
        self.__saldo = saldo
        self.id = id

    def saque(self, valor):
        if valor<self.__saldo:
            valor = abs(valor)
            self.__saldo -= valor
        else:
            print ('Saldo insuficiente')
            
    def depositar(self, valor):
        valor = abs(valor)
        self.__saldo += valor

    def __str__(self):
        return f'Estado da conta: {self.__dict__}'