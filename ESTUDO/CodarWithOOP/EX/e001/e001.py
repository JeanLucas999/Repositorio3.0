# CLASSE
class Gafanhoto:
    def __init__(self): #METODO CONSTRUTOR
        # ATRIBUTOS DE INSTANCIA
        self.nome  = ''
        self.idade = 0
    # METODOS DE INSTANCIA
    def aniversario(self):
        self.idade = self.idade + 1
        #self.idade += 1

    def mensagem(self):
        return f'{self.nome} EH GAFANHOTO E TEM {self.idade} ANOS'

# OBJ
g1 = Gafanhoto() #() chama o metodo construtor
g1.nome = 'JEAN'
g1.idade = 18
g1.aniversario()

print (g1.mensagem())
        