# CLASSE
class Gafanhoto:
    """ 
    OLA MUNDO, MANUAL DISSO AI
    """
    def __init__(self, n = '', i = 0): #METODO CONSTRUTOR
        # ATRIBUTOS DE INSTANCIA
        self.nome  = n
        self.idade = i

    # METODOS DE INSTANCIA
    def aniversario(self):
        self.idade = self.idade + 1
        #self.idade += 1

    def mensagem(self):
        return f'{self.nome} EH GAFANHOTO E TEM {self.idade} ANOS'

    def __str__(self): # Dunder Method
        return "OI"

    def __getstate__(self):
        return 'OK'
# OBJ
g1 = Gafanhoto('Jean', 18) #() chama o metodo construtor

g1.aniversario()
print (g1.__doc__)
#print (g1.mensagem())
print (g1)
print(g1.__dict__) # Attribute
print(g1.__getstate__()) # Method
print(g1.__class__)