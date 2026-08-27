import tkinter as tk
class Palavra:
    def __init__(self):
        self.visibilidade = False
        self.frame = tk.Frame(menu)

    def colocarBotao(self):
        self.botaoPalavra = tk.Entry(self.frame, width=45, justify='center', font=fonte, show='*')
        self.botaoPalavra.place(x=75, y=125)

        self.titulo = tk.Label(self.frame, text='SELECIONE A PALAVRA', width=45, justify='center', font=fonte)
        self.titulo.place(x=75, y=80)

        self.visivel = tk.Button(self.frame, width=12, justify='center', font=fontepequena, text='VER PALAVRA', command= lambda: self.verSenha())
        self.visivel.place(x=290, y=175)

        self.confirmar = tk.Button(self.frame, width=12, justify='center', font=fonte, text='CONFIRMAR', command= lambda: self.confirmarPalavra())
        self.confirmar.place(x=268, y=225)

        self.frame.place(x=0, y=0, width=700, height=350)


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
        global palavraget
        print ('getTxt')
        palavraget = self.botaoPalavra.get()
        self.frame.destroy()

class Jogo:
    def __init__(self):
        self.vidas = 6

    def fimdeJogo(self):
        pass

    def atualizar(self):
        pass

fonte= ('Segoe UI', 16)
fontepequena= ('Segoe UI', 10)


menu = tk.Tk()
menu.title('Jogo da forca')
menu.geometry('700x350')


palavra = Palavra()
palavra.colocarBotao()
    
menu.mainloop()
