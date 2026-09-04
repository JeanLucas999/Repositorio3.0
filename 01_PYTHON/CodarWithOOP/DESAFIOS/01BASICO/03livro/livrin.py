class Livro:
    def __init__(self, nome = '', paginas = 0):
        self.nome = nome
        self.paginas = paginas 
        self.actual = 1
    def pularpaginas(self, jump = 0):
        for c in range (1, jump+1):
            if self.actual<=self.paginas:
                print (f'Pag{self.actual}-->', end='')
            if self.actual == self.paginas:
                print('Livro finalizado!')
            self.actual += 1

livro = Livro('Tres patinhos', 20)
livro.pularpaginas(59)
livro.pularpaginas(5)