class Numero:

    def __init__(self, valor:int|float = 0):
        self.valor = valor

    def dobrar(self):
        self.valor *= 2

    def __str__(self):
        return f'Numero {self.valor}'

    
class Texto:

    def __init__(self, string:str = ''):
        self.string = string

    def dobrar(self):
        self.string += self.string

    def __str__(self):
        return f'Texto {self.string}'
class Lista:

    def __init__(self, lista:list = []):
        self.lista = lista

    def dobrar(self):
        self.lista = self.lista + self.lista

    def __str__(self):
        return f'itens {self.lista}'
        
class Papel:

    def __init__(self):
        self.dobrado = False

    def dobrar(self):
        self.dobrado = True

    def __str__(self):
        return f'Papel dobrado {self.dobrado}'
    
class Casa:

    def __init__(self):
        pass

    def __str__(self):
        return f'Casa engracada'


#DUCK

def tenteDobra(objeto):
    try:
        objeto.dobrar()
    except:
        print (f'Nao da para dobrar {objeto.__class__.__name__}')