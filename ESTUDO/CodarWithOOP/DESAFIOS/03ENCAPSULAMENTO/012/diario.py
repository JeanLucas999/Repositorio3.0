class Diario:
    def __init__(self, criarsenha = 'Jean'):
        self.__senha = criarsenha
        self.__segredos = []
        pass

    def escrever(self, txt):
        self.__segredos.append(txt)

    def ler(self, senha = 'PermissionError'):
        try:
            if self.__senha == senha:
                print (self.__segredos)
            else:
                raise ValueError
        except:
            print('SENHA INVALIDA.')
