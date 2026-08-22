class Conta:
    def __init__(self, nome, saldo = 0, id = 0):
        self.nome = nome
        self.saldo = saldo
        self.id = id

    def saque(self, valor):
        if valor<self.saldo:
            if valor<0:
                valor *= -1
            self.saldo -= valor
        else:
            print ('Saldo insuficiente')
            
    def depositar(self, valor):
        if valor<0:
            valor *= -1
        self.saldo += valor

    def __str__(self):
        return f'Estado da conta: {self.__dict__}'