#Ordem para o dicionario de cada ataque:
#NOME, MULTIPLICADOR DE DANO, CHANCE DE ACERTO, TAXA, DANO CRITICO, TIPO, LISTA COM FRASES DE ATAQUE NORMAL, LISTA COM FRASES DE DANO CRITICO, LISTA DE ERROS
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

listaAtaques = [
    {'nome': 'Investida', 'dano': 1, 'chance': 95, 'taxa': 10, 'critico': 1.5, 'tipo': 'basico', 
     
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
    }

]

listaEfeitos = []

#Ordem para as curas:
#NOME, DESCRICAO, %VIDA, CHANCE DE ACERTO, FRASES ACERTO, ERRO

listaCuras = [
    {'nome': 'Cura Simples', 'desc': 'Cura 15% e tem 95% de SUCESSO', 'vida': 15, 'chance': 95, 
    'acerto': 
    [
        'curou 100% tomando uma xicara de café bem quentinho, queimou a lingua e perdeu 85% dos 100%',
        'comeu um pacotão de doritos, ganhou 15% de cura e 10 anos a menos de expectativa de vida', 
        'tentou meditar, escorregou, por sorte caiu de cara em uma poça deixada pela poção de cura que caiu de seu bolso, curou 15%',
    ],
    'erro':
    [
        'queimou a boca no primeiro gole de café, achando que o café nunca mudaria, não tentou novamente, 0% de vida recuperada',
        'foi comer um pacote de doritos, viu que tinha bolor e jogou fora(que nojo!), nada aconteceu',
        'meditou, mas pelo visto isso não cura nossos verdadeiros problemas, nada aconteceu.',
    ],
    },

    {'nome': 'Cura Media', 'desc': 'Cura 50% e tem 50% de SUCESSO', 'vida': 50, 'chance': 50, 
    'acerto': 
    [
        'dormiu por 5 horas, como o adversario era muito generoso, acabou por não atrapalhar, curou 50% de vida',
        'carregou seu ki e recuperou 50% de vida', 
        'pesquisou metodos de como conquistar FÊMEAS, deu tudo errado, bebeu cachaça e recuperou 50% de vida',
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


