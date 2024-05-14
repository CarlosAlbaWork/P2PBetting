[
{
"GameID": 20927
"DateTime": "2024-05-11T15:30:00",
"AwayTeam": "OKC",
"HomeTeam": "DAL",
},
{
"GameID": 20936,
"DateTime": "2024-05-11T20:30:00",
"AwayTeam": "BOS",
"HomeTeam": "CLE",
}
]

Tengo un JSON como el siguiente que contiene distintos partidos de la NBA con su fecha, equipo local y suplente. Está contenido en un objeto del tipo "bytes" en solidity. Como puedo convertir ese objeto "bytes" en un objeto que pueda iterar para poder obtener los atributos de cada Partido? Mi intención es guardar cada partido en un struct Partido que contenga el Id, fecha , equipo local y equipo visitante.
