extends RefCounted

const WIDTH = 13032.0
const PORTAL_X = WIDTH - 66.0
const PORTAL_Y = 506.0
const REGIONS = [
	{"name":"Reino Verdejante","start":0.0,"end":2172.0},
	{"name":"Travessia de Raízes","start":2172.0,"end":4344.0},
	{"name":"Descida da Rede","start":4344.0,"end":6516.0},
	{"name":"Galerias de Seiva","start":6516.0,"end":8688.0},
	{"name":"Copas Antigas","start":8688.0,"end":10860.0},
	{"name":"Vestíbulo do Ninho","start":10860.0,"end":WIDTH}
]
const LOTUSES = [Vector2(1490,506),Vector2(5310,506),Vector2(8470,506),Vector2(10580,450)]
const ENEMIES = [
	# Ordem histórica preservada: testes e saves anteriores mantêm seus índices.
	[570,490,"scout"],[880,444,"scout"],[1770,506,"scout"],[2500,506,"scout"],
	[2910,450,"spitter"],[3410,420,"scout"],[4000,490,"spitter"],[4700,506,"scout"],
	[5900,506,"spitter"],[3100,282,"fly"],[5200,278,"fly"],
	[6600,506,"scout"],[7200,650,"scout"],[7690,650,"spitter"],
	[8880,506,"scout"],[9370,450,"spitter"],[9750,278,"fly"],[10020,578,"scout"],
	[11030,450,"scout"],[11500,610,"spitter"],[12620,506,"scout"]
]
# Pontos de decolagem, em ordem de percurso.25ticks segurando pulo a60Hz.
# Os quatro saltos antigos à direita e todos os pisos antigos permanecem.
const MAIN_JUMPS = {
	"right":[630.0,990.0,2650.0,3040.0,7820.0,8100.0,9030.0,10080.0,10360.0,11750.0,12050.0,12330.0],
	"left":[12540.0,11450.0,11170.0,9870.0,9540.0,9230.0,7080.0,6800.0,4400.0,3702.0,3270.0,1450.0,1180.0]
}
# Cada lista inclui os apoios oeste/leste. Percorrê-la ao contrário testa a
# segunda entrada do laço, sem teleporte entre memória e saída/retorno.
const NEW_ROUTE_LOOPS = [
	{"id":"sap_gallery","memory":"sap","points":[Vector2(6580,506),Vector2(6710,430),Vector2(6890,354),Vector2(7110,278),Vector2(7470,278),Vector2(7580,278),Vector2(8020,354),Vector2(8190,430),Vector2(8430,506)]},
	{"id":"old_canopy","memory":"rings","points":[Vector2(8740,506),Vector2(8890,430),Vector2(9050,354),Vector2(9250,278),Vector2(9500,220),Vector2(9750,278),Vector2(9900,354),Vector2(10070,430),Vector2(10240,506)]},
	{"id":"nest_vestibule","memory":"threshold","points":[Vector2(10900,450),Vector2(11020,374),Vector2(11190,298),Vector2(11410,222),Vector2(11570,222),Vector2(11680,298),Vector2(11850,222),Vector2(12120,298),Vector2(12300,374),Vector2(12440,430),Vector2(12620,506)]}
]
const MEMORIES = [
	{"id": "roots", "pos": Vector2(820, 444), "text": "SEIVA FOSSILIZADA\nAs raízes desceram além de onde a luz alcança. Não procuravam água. Procuravam mais terra."},
	{"id": "border", "pos": Vector2(1900, 506), "text": "REGISTRO DE FRONTEIRA\nEles não nos seguiram até a superfície. Ficaram lá embaixo, protegendo o que já era deles."},
	{"id": "canopy", "pos": Vector2(960, 262), "text": "SOBRE AS COPAS\nA trilha dos sentinelas contorna as raízes. Todos os caminhos voltam à floresta."},
	{"id": "bridge", "pos": Vector2(2700, 360), "text": "A PONTE VIVA\nPor cima, o vento. Por baixo, a seiva. A Rede reconhece os passos em ambos os caminhos."},
	{"id": "echo", "pos": Vector2(5500, 278), "text": "O HOSPEDEIRO\nA formiga ainda caminha. Mas os fios dourados em suas costas escolhem a direção."},
	{"id":"sap","pos":Vector2(7470,278),"text":"GALERIAS DE SEIVA\nAs raízes guardaram a água no fundo. Acima delas, a antiga passagem ainda liga as duas margens."},
	{"id":"rings","pos":Vector2(9500,220),"text":"ANÉIS DAS COPAS\nCada camada cresceu em torno de uma ausência. A floresta lembra o espaço que os antigos deixaram."},
	{"id":"threshold","pos":Vector2(11680,298),"text":"ANTES DO NINHO\nQuem chegou por baixo ouviu a Rede primeiro. Quem voltou por cima aprendeu a distinguir suas vozes."}
]

static func ground() -> Array[Rect2]:
	return [Rect2(-100,490,800,250), Rect2(700,444,340,300), Rect2(1140,466,250,300), Rect2(1390,506,1322,300), Rect2(2712,450,380,350), Rect2(3212,420,430,380), Rect2(3642,490,702,310), Rect2(4344,506,2172,300),
		# Galerias: a bacia é solo baixo; raízes superiores não fecham o teto.
		Rect2(6516,506,224,340),Rect2(6740,578,280,300),Rect2(7020,650,860,250),Rect2(7880,578,280,300),Rect2(8160,506,528,340),
		# Copas: salto de120px, terraços e uma segunda depressão curta.
		Rect2(8688,506,382,340),Rect2(9190,450,290,360),Rect2(9480,506,330,340),Rect2(9810,578,330,300),Rect2(10140,506,280,340),Rect2(10420,450,440,360),
		# Vestíbulo: escadaria até610, volta ao alto e vão antes do portal506.
		Rect2(10860,450,260,360),Rect2(11120,530,280,340),Rect2(11400,610,400,280),Rect2(11800,530,300,340),Rect2(12100,450,280,360),Rect2(12500,506,532,340)]

static func branches() -> Array[Rect2]:
	# Rotas de ida e volta: degraus dos dois lados, sem portas de sentido único.
	return [Rect2(420,414,160,20), Rect2(560,338,160,20), Rect2(690,262,550,20), Rect2(1210,338,170,20), Rect2(1350,414,180,20), Rect2(2412,430,180,20), Rect2(2632,360,180,20), Rect2(2780,282,750,20), Rect2(3430,360,190,20), Rect2(3650,430,180,20), Rect2(4500,430,190,20), Rect2(4710,354,190,20), Rect2(4900,278,840,20), Rect2(5600,354,190,20), Rect2(5810,430,190,20),
		Rect2(6620,430,220,20),Rect2(6790,354,220,20),Rect2(6960,278,540,20),Rect2(7480,278,480,20),Rect2(7910,354,220,20),Rect2(8080,430,230,20),
		Rect2(8780,430,220,20),Rect2(8940,354,220,20),Rect2(9120,278,710,20),Rect2(9380,220,240,20),Rect2(9780,354,230,20),Rect2(9950,430,230,20),
		Rect2(10920,374,230,20),Rect2(11090,298,220,20),Rect2(11260,222,350,20),Rect2(11730,222,330,20),Rect2(11460,298,470,20),Rect2(12010,298,230,20),Rect2(12180,374,240,20),Rect2(12320,430,240,20)]
