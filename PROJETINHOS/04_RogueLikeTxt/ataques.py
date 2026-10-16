#Ordem para o dicionario de cada ataque:
#TIPO
#NOME, DESCRICAO, MULTIPLICADOR DE DANO, CHANCE DE ACERTO, TAXA, DANO CRITICO, TIPO, EFEITO, CHANCEEFEITO, LISTA COM FRASES DE ATAQUE NORMAL, LISTA COM FRASES DE DANO CRITICO, LISTA DE ERROS
    #{'nome': 'Investida', 'dano': 1, 'chance': 95, 'taxa': 1, 'critico': 1, 'tipo': 'basico', 
     
    #'acerto': 
    #[

    #],

    #'critou':
    #[
    #    
    #],

    #'erro':
    #[

    #]
    #}



#O ERRO REFERE SE AO MESMO INDICE DO ACERTO
#Girar dado para escolher qual tentativa, tipo comeu doritos 0 x nao conseguiu abrir o pacote 0
#Efeitos tem duracao por turnos e dano porcento
listaEfeitos = {
    'veneno':
    {'nome': 'Veneno', 'duracao': 5, 'dano': 10}
}


listaAtaques =  {
    'investida':
    {'nome': 'Investida', 'desc': 'Investe contra o inimigo causando 1x seu ataque', 'dano': 1, 'chance': 95, 'taxa': 10, 'critico': 1.5, 'tipo': 'basico', 'efeito': 'sem',

    'acerto': 
    [
        'investiu contra o oponente dando uma cabeçada',
        'deu uma ombrada no oponente'
    ],

    'critou':
    [
        'investiu dando uma puta cabeçada no oponente que até deixou ele tonto',
        'investiu dando uma ombrada que jogou o oponente para longe'
    ],

    'erro':
    [
        'tentou investir, tropeçou e caiu no chão apenas perdendo aura',
        'foi dar uma ombrada no oponente, ele desviou e fez um sinal de "Não" com a cabeça'
    ]
    },

    'tapa':
    {'nome': 'Tapa', 'desc': 'Dá um tapa no inimigo causando 1.2x seu ataque', 'dano': 1.2, 'chance': 80, 'taxa': 10, 'critico': 1.5, 'tipo': 'humanoide', 'efeito': 'sem',
    
    'acerto': 
    [
        'deu um tapa na cara do oponente',
        'deu um tapa na bunda do oponente'
    ],

    'critou':
    [
        'deu um TAPÃO na cara do oponente que até deixou ele tonto',
        'deu um baita dum tapa na bunda do oponente'
    ],

    'erro':
    [
        'foi dar um tapa na cara do oponente, o mesmo riu, quem usaria um tapa em uma luta?',
        'tentou dar um tapa na bunda do oponente, você realmente achou que funcionaria.'
    ]
    },

    'envenenamento':
    {'nome': 'Envenenamento', 'desc': 'Envenena seu inimigo tirando 10% de vida por turno', 'dano': 0, 'chance': 60, 'taxa': 0, 'critico': 0, 'tipo': 'venenoso', 'efeito': listaEfeitos['veneno'], 'chanceEfeito': 100,
    
    'acerto': 
    [
        'jogou uma chuva de veneno no inimigo',
        'deixou o inimigo fortemente envenenado'
    ],

    'erro':
    [
        'jogou uma chuva de veneno, NO CHÃO',
        'deixou o inimigo extremamente normal'
    ]
    }
}

#Ordem para as curas:
#NOME, DESCRICAO, %VIDA, CHANCE DE ACERTO, FRASES ACERTO, ERRO

listaCuras = [
    {'nome': 'Cura Simples', 'desc': 'Cura 20% e tem 95% de SUCESSO', 'vida': 20, 'chance': 95, 
    'acerto': 
    [
        'curou 100% tomando uma xicara de café bem quentinho, queimou a lingua e perdeu 80% dos 100%',
        'comeu um pacotão de doritos, ganhou 20% de cura e 10 anos a menos de expectativa de vida', 
        'tentou meditar, escorregou, por sorte caiu de cara em uma poça deixada pela poção de cura que caiu de seu bolso, curou 20%',
    ],
    'erro':
    [
        'queimou a boca no primeiro gole de café, achando que o café nunca mudaria, não tentou novamente, 0% de vida recuperada',
        'foi comer um pacote de doritos, viu que tinha bolor e jogou fora(que nojo!), nada aconteceu',
        'meditou, mas pelo visto isso não cura nossos verdadeiros problemas, nada aconteceu.',
    ],
    },

    {'nome': 'Cura Media', 'desc': 'Cura 65% e tem 50% de SUCESSO', 'vida': 65, 'chance': 50, 
    'acerto': 
    [
        'dormiu por 5 horas, como o adversario era muito generoso, acabou por não atrapalhar, curou 65% de vida',
        'carregou seu ki e recuperou 65% de vida', 
        'pesquisou metodos de como conquistar FÊMEAS, deu tudo errado, bebeu cachaça e recuperou 65% de vida',
    ],
    'erro':
    [
        'tentou dormir, o adversario obviamente não deixou, 0% de vida recuperada',
        'tentou carregar seu ki, INACREDITAVELMENTE, ele não estava em Dragon Ball, nada aconteceu',
        'pesquisou metodos de como conquistar FÊMEAS, percebeu que o problema estava nele, desistiu.',
    ],
    },
    ]

#Ordem para as defesas:
#NOME, DESCRICAO, CHANCE DE ACERTO, FRASES ACERTO, ERRO

listaDefesas = [

]


