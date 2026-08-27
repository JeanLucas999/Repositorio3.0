import tkinter as tk
AzulClaro = '#C3EBEE'
AzulMedio = "#77A8AC"
AzulEscuro = "#090E2B"

class EscolherPalavra:
    def __init__(self):
        self.visibilidade = False
        self.frame = tk.Frame(menu, bg=AzulClaro)

    def colocarBotao(self):
        self.botaoPalavra = tk.Entry(self.frame, width=50, justify='center', font=fonte, show='*', fg=AzulEscuro)
        self.botaoPalavra.place(x=75, y=200)

        self.titulo = tk.Label(self.frame, text='SELECIONE A PALAVRA', width=23, justify='center', font=fonte, bg=AzulMedio, fg=AzulEscuro)
        self.titulo.place(x=217, y=90)

        self.visivel = tk.Button(self.frame, width=15, justify='center', font=fontePequena, text='VER PALAVRA', bg=AzulMedio, fg=AzulEscuro, command= lambda: self.verSenha())
        self.visivel.place(x=300, y=250)

        self.confirmar = tk.Button(self.frame, width=15, justify='center', font=fonte, text='CONFIRMAR', bg=AzulMedio, fg=AzulEscuro, command= lambda: self.confirmarPalavra())
        self.confirmar.place(x=264, y=300)

        self.fechar = tk.Button(menu, width=3, justify='center', font=fontePequena, text='X', bg=AzulEscuro, fg=AzulClaro, command= lambda: menu.destroy())
        self.fechar.place(x=650, y=20)

        self.frame.place(x=0, y=0, width=700, height=500)


    def verSenha(self):
        print ('DEBUG')
        print (self.visibilidade)
        if self.visibilidade == False:
            self.botaoPalavra.config(show='')
            self.visibilidade = True
        else:
            self.botaoPalavra.config(show='*')
            self.visibilidade = False

    def confirmarPalavra(self):
        global jogo
        print ('getTxt')
        palavraget = (((self.botaoPalavra.get()).strip()).upper())
        print (palavraget)
        self.frame.destroy()
        jogo = Jogo(palavraget)
        jogo.textoTela()
        self.fechar.lift()

class Jogo:
    def __init__(self, palavra):
        print (f'Oi jogo, {palavra}')
        self.vidas = 6
        self.palavra = palavra
        self.frame = tk.Frame(menu, bg=AzulClaro)

    def textoTela(self):
        self.textovidas = tk.Label(self.frame, text=f'{self.vidas}/6 VIDAS', font=fonte, width=10, relief='groove', bg=AzulEscuro, fg=AzulClaro)
        self.textovidas.place(x=30, y=20)


        self.frame.place(x=0, y=0, width=700, height=500)


    def fimdeJogo(self):
        if self.vidas == 0:
            pass
        else:
            pass
        pass
        #botao fechar + destroy menu

    def atualizar(self):
        #palavra ou vida
        pass

fonte= ('Segoe UI', 16)
fontePequena= ('Segoe UI', 10)


menu = tk.Tk()
menu.title('Jogo da forca')
menu.geometry('700x500')

EscolhaPalavra = EscolherPalavra()
EscolhaPalavra.colocarBotao()

menu.mainloop()
