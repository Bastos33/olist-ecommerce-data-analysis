# Olist E-commerce Data Analysis

Projeto de Engenharia e Análise de Dados desenvolvido a partir da base pública do Olist.

O objetivo foi transformar arquivos CSV transacionais em um ambiente analítico composto por pipeline ETL, modelagem dimensional em SQL Server e dashboards no Power BI, permitindo analisar receita, logística, vendedores, produtos e satisfação dos clientes.

## Arquitetura

```text
CSVs Olist
    │
    ▼
Python ETL
    │
    ▼
SQL Server (Staging)
    │
    ▼
Modelagem Dimensional
    │
    ▼
Views Analíticas
    │
    ▼
Power BI
```

O pipeline executa a ingestão dos arquivos, valida os dados, realiza transformações em SQL Server e disponibiliza uma camada analítica para consumo no Power BI.

## Estrutura do Repositório

```text
olist-ecommerce-data-analysis/
├── README.md
├── pipeline_olist.py
├── scripts/
│   ├── Olistranformacao_modelagem.sql
│   ├── views.sql
│   └── validacao.sql
├── dashboard/
│   └── olist_dashboard.pbix
└── docs/
    └── documentacao_tecnica.pdf
```

### Componentes

* **pipeline_olist.py**: ingestão, validações, auditoria e controle de execução.
* **Olistranformacao_modelagem.sql**: staging, transformações e modelagem dimensional.
* **views.sql**: criação das views analíticas.
* **validacao.sql**: consultas de validação e integridade dos dados.
* **olist_dashboard.pbix**: dashboard desenvolvido em Power BI.
* **documentacao_tecnica.pdf**: documentação detalhada do projeto.

## Tecnologias

* Python (pandas, SQLAlchemy)
* SQL Server (T-SQL)
* Power BI (DAX)
* Star Schema
* SQL Server Agent / Auditoria de carga
* Logging e Lock File

## Modelo Dimensional

### Dimensões

* dim_customer
* dim_product
* dim_seller
* dim_geolocation
* dim_date

### Tabelas Fato

* fact_sales
* fact_payment

A modelagem foi estruturada em esquema estrela para simplificar consultas analíticas e melhorar a performance dos dashboards.

## Qualidade e Governança

Durante a carga são executadas validações de:

* colunas obrigatórias;
* tipos de dados;
* registros duplicados;
* integridade da carga;
* auditoria por arquivo processado.

Registros inválidos são separados para análise posterior e todas as execuções são registradas em log.

## Views Analíticas

### vw_KPI_Entregas

Consolida indicadores operacionais relacionados à logística:

* total de pedidos;
* entregas no prazo;
* entregas atrasadas;
* percentual de entregas no prazo;
* percentual de atraso;
* nota média de avaliação;
* atraso médio em dias.

Essa view foi utilizada para acompanhar a eficiência logística e comparar períodos de crescimento da receita.

### vw_reviews_negativos

Desenvolvida para investigar a relação entre atraso logístico e satisfação do cliente.

A análise mostrou que pedidos entregues após a data prometida apresentam queda significativa na nota média de avaliação, reforçando o impacto da logística sobre a experiência do consumidor.

## Principais Resultados

| Indicador                        | Valor            |
| -------------------------------- | ---------------- |
| Receita                          | R$ 14.031.821,27 |
| Pedidos Entregues                | 96.478           |
| Ticket Médio                     | R$ 145,44        |
| Entregas no Prazo                | 91,89%           |
| Atraso Médio                     | 0,72 dias        |
| Nota Média Geral                 | 4,16             |
| Nota Média em Entregas Atrasadas | 2,27             |

## Receita e Contexto Econômico

Entre novembro de 2017 e agosto de 2018 foi observado um crescimento expressivo da receita.

Para entender se esse aumento gerou impacto operacional, a view **vw_KPI_Entregas** foi utilizada para monitorar os indicadores logísticos do período. Os resultados apontaram 67.089 pedidos entregues, 90,13% de entregas dentro do prazo e atraso médio de 8 dias entre os pedidos atrasados.

O período coincide com a redução da taxa Selic e com uma política monetária expansionista voltada à recuperação da atividade econômica após a recessão de 2015–2016. Sob a perspectiva macroeconômica, a queda dos juros tende a estimular crédito e consumo, comportamento compatível com o crescimento observado no marketplace.

Ao mesmo tempo, observou-se uma pequena deterioração dos indicadores logísticos, sugerindo que o aumento do volume de vendas exerceu pressão adicional sobre a operação.

## Dashboard

O dashboard foi desenvolvido para análise de:

* Receita e crescimento;
* Produtos e categorias;
* Performance de vendedores;
* Distribuição geográfica;
* Logística de entregas;
* Avaliações dos clientes.

## Autor

**Carla Bastos**

Projeto desenvolvido como parte do portfólio de Engenharia e Análise de Dados, abrangendo ETL, modelagem dimensional, SQL Server, Power BI e análise de indicadores de negócio.
