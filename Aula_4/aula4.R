# 0. Instalando os pacotes (apenas uma vez)
 install.packages(c("DBI", "duckdb"))
# 1. Carregando pacotes.
library(duckdb)
library(DBI)
# 2. Especificando onde serão armazenadas as consultas.
# Isso prepara o "motor" do duckdb para receber comandos
con <- dbConnect(duckdb::duckdb(),dbdir = ":memory:")
# as consultas serão salvas na memória
  # e depois apagadas ao finalizar
  #dbdir = "sim_obitos.duckdb" # cria uma arquivo p/ armazenar
  # os resultados da consulta
)
# 3. Definindo o caminho para o arquivo gigante
# para não precisarmos escrever em toda consulta
caminho <- "C:/Users/thiag/OneDrive/Documentos/Estatística/Mineração de Dados/GitHub/Minera-o/Aula_4/DO24OPEN.csv"

# Criando a consulta SQL
# SELECT COUNT(*): "Selecione a contagem de todas as linhas"
# FROM '%s' será substituído pelo caminho do arquivo
consult <- sprintf("SELECT COUNT(*) AS total FROM '%s'", caminho)
# Enviando a consulta e pegando o resultado.
# O duckdb vai ler o arquivo (sem carregá-lo) e retornar
# apenas o resultado.
total_linhas <- dbGetQuery(con, consult)
total_linhas
total

# Montar a consulta SQL
consult <- sprintf("SELECT CODMUNOCOR, COUNT(*) AS total_obitos
FROM '%s'
GROUP BY CODMUNOCOR
ORDER BY total_obitos DESC",
                   caminho)
# Enviar a consulta e pegar o resultado
obitos_por_municipio <- dbGetQuery(con, consult)
# Ver as primeiras 4 linhas do resultado
head(obitos_por_municipio, n = 4L)

# Criar a consulta SQL
# CODMUNOCOR: Codigo do município onde ocorreu o óbito.
# CAUSABAS: 'V01' a 'V99' são os códigos da CID-10 para
# acidentes de transporte.
consult <- sprintf("SELECT CODMUNOCOR,
COUNT(CAUSABAS) AS obitos_acidentes
FROM '%s'
WHERE CAUSABAS BETWEEN 'V01' AND 'V99'
GROUP BY CODMUNOCOR
ORDER BY obitos_acidentes DESC",
                   caminho)
obitos_acidentes_mun <- dbGetQuery(con, consult)
head(obitos_acidentes_mun, n = 4L) # primeiras 4 linhas

install.packages("janitor")
library(janitor)
library(tidyverse)
tab_cod_ibge <- readxl::read_excel("C:/Users/thiag/OneDrive/Documentos/Estatística/Mineração de Dados/GitHub/Minera-o/Aula_4/RELATORIO_DTB_BRASIL_2024_MUNICIPIOS.xls",
skip = 6, 
col_names = TRUE
) |>
# Limpar nomes das colunas
janitor::clean_names()

tab_cod_ibge <- tab_cod_ibge |>
  # Cria código de 6 dígitos removendo o dígito verificador
  mutate(codigo_6digitos = str_sub(codigo_municipio_completo,
                                   1, -2)) |>
  # Converte para numérico
  mutate(codigo_6digitos = as.numeric(codigo_6digitos)) |>
  # Seleciona e renomeia colunas finais
  select(codigo = codigo_6digitos,
         municipio = nome_municipio,
         UF = nome_uf)

# juntando o número de acidentes e os nomes dos municípios
obitos_acidentes_nome_municipios <- tab_cod_ibge |>
  left_join(obitos_acidentes_mun,
            by = c("codigo" = "CODMUNOCOR")) |>
  arrange(desc(obitos_acidentes)) # ordem decrescente
head(obitos_acidentes_nome_municipios)
