# Final Project: Quiz Application with Microservices
# Date: 1-June-2022
# Authors: 
#
#          Sebastian Morales Martin         A01376228
#          Eduardo Roberto Müller Romero    A01745219

require 'json'
require 'sinatra'
require 'faraday'

#declaramos algunas variables que vamos a usar por todo el codigo.
# la variable indice es ver el indice de nuestro arreglo de preguntas
indice = 0
# la variable de puntuacion la vamos a usar para saber cuantas preguntas tuvo bien el usuario
puntuacion = 0
numero_preguntas = 0 # numero de preguntas que selecciono el usuario antes de hacer el quiz
# array para almacenar las preguntas
preguntas = []
# array para almacenar todos los usuarios que hay en nestra tabla de Dynamo
usuarios = []

get '/' do
    erb :index
end

