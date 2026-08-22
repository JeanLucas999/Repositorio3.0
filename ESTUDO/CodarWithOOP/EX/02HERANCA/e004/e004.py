class Pessoa:
    def __init__(self, nome = '', idade = 0):
        self.nome = nome
        self. idade = idade
    def aniversario(self):
        self.idade += self.idade


class Aluno(Pessoa):
    def __init__(self, nome, idade, curso, turma):
        super().__init__(nome, idade)
        self.curso = curso
        self.turma = turma

    def matricula(self):
        pass

class Professor(Pessoa):
    def __init__(self, nome, idade, especialidade, nivel):
        super().__init__(nome, idade)
        self.especialidade = especialidade
        self.nivel = nivel

    def aula(self):
        pass


class Funcionario(Pessoa):
    def __init__(self, nome, idade, cargo, setor):
        super().__init__(nome, idade)
        self.cargo = cargo
        self.setor = setor

    def ponto(self):
        pass

a1 = Aluno('Jose', 0, 'Informatica', '01')
print(a1.__dict__)