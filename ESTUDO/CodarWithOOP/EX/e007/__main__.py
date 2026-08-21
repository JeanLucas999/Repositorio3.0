from classesE007 import Aluno, Professor, Funcionario, Pessoa
from rich import print, inspect

def main():
    a1 = Aluno('Jose', 0, 'Informatica', '01')
    print(a1.__dict__)

    x = Aluno('Jean', 45, 'Oi', 'OI')
    x.aniversario()
    inspect(x, methods=True)

if __name__ == '__main__':
    main()