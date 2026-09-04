from abc import ABC, abstractmethod

class Funcionario(ABC):
    def __init__(self, nome = '', salBruto = 0):
        self.nome = nome
        self.salBruto = salBruto
        self.sal = 0
        self.min = 1612
        self.inss = 7.5

    def analise(self):
        return f'isso equivale a {self.sal/self.min:.1f} salarios minimos'
    @abstractmethod
    def calc_sal(self):
        pass

class Mensal(Funcionario):
    def __init__(self, nome, salBruto):
        super().__init__(nome, salBruto)
    def calc_sal(self):
        self.sal = self.salBruto*0.935
        return self.sal
    
class Horista(Funcionario):
    def __init__(self, nome, valHora=0, horasSem=0):
        super().__init__(nome)
        self.valHora = valHora
        self.horas = horasSem
    def calc_sal(self):
        self.salBruto = self.valHora*self.horas*4
        self.sal = self.salBruto*0.935
        return self.sal

name = 'Jean'
pessoa = Horista(name, 12, 20)
print (f'O salario liquido de {name} eh de R${pessoa.calc_sal():.2f}, {pessoa.analise()}')