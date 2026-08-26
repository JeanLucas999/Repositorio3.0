import tkinter as tk
class Palavra:
    def __init__(self):
        self.botaoPalavra = tk.Entry(menu, width=45, justify='center', font=fonte, show='*')
        self.visibilidade = False

    def colocarBotao(self):
        self.botaoPalavra.place(x=75, y=125)
        self.visivel = tk.Button(menu, width=12, justify='center', font=fonteversenha, text='VER PALAVRA', command= lambda: self.verSenha())
        self.confirmar = tk.Button(menu, width=12, justify='center', font=fonte, text='CONFIRMAR', command= lambda: self.confirmarPalavra())
        self.confirmar.place(x=268, y=225)
        self.visivel.place(x=290, y=175)

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
        print ('getTxt')
        palavraget = self.botaoPalavra.get()
        print (palavraget)

fonte= ('Segoe UI', 16)
fonteversenha= ('Segoe UI', 10)


menu = tk.Tk()
menu.title('Jogo da forca')
menu.geometry('700x350')

titulo = tk.Label(menu, text='SELECIONE A PALAVRA', width=45, justify='center', font=fonte)
titulo.place(x=75, y=80)

palavra = Palavra()
palavra.colocarBotao()
    
menu.mainloop()