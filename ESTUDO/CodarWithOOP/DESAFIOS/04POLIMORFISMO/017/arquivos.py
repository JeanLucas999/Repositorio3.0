from abc import ABC, abstractmethod

class Arquivo:
    def __init__(self, nome:str = '', tamanho:int|float = 0):
        self.nome = nome
        self._extensao = ''
        self.tamanho = tamanho/1000
        self.nomeCompleto = ''

    def abrir(self):
        print ('Abriu o arquivo')

    def completo(self):
        self.nomeCompleto = f'"{self.nome}.{self._extensao}"({self.tamanho:.1f}MB)'


        

class PDF(Arquivo):
    def __init__(self, nome, tamanho):
        super().__init__(nome, tamanho)
        self._extensao = 'pdf'
        self.completo()

    def abrir(self):
        print (f'abrindo o {__class__.__name__} de nome {self.nomeCompleto} no Adobe Reader')

class DOC(Arquivo):
    def __init__(self, nome, tamanho):
        super().__init__(nome, tamanho)
        self._extensao = 'docx'
        self.completo()

    def abrir(self):
        print (f'abrindo o {__class__.__name__} de nome {self.nomeCompleto} no Word')


def abrir(objeto):
    objeto.abrir()