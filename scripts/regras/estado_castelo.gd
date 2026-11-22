class_name EstadoCastelo
extends EstadoSalas
## O castelo: salas, chaves e portas (a regra geral está em EstadoSalas).

const SALAS: Array[String] = ["cozinha", "musica", "biblioteca", "quarto"]
const CHAVE_DA_SALA := {"cozinha": "azul", "musica": "vermelha"}
## porta -> cor da chave que abre ("caixas" = abre quando o corredor termina)
const PORTAS := {"biblioteca": "azul", "caixas": "vermelha", "quarto": "caixas"}


func _init() -> void:
	super(SALAS, CHAVE_DA_SALA, PORTAS)
