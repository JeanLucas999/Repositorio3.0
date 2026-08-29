from aluno import Aluno
from rich import inspect

def main():
    jean = Aluno ('Jean', 2008, 'LAP')
    jean.add_curso('LAP')
    jean.curso = 'LAP'
    jean.idade = 25
    jean.nascimento = 2005
    inspect(jean, private=True, methods=True)

if __name__ == '__main__':
    main()
