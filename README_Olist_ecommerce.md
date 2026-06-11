# Olist E-commerce Data Analysis

Projeto de Análise de Dados desenvolvido a partir da base pública do Olist.

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
└── documentação_técnica/
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

* Python (pandas, SQLAlchemy, numpy)
* SQL Server (T-SQL)
* Power BI (DAX)
* Star Schema/Snowflake
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

A modelagem foi estruturada em esquema estrela para simplificar consultas analíticas e melhorar a performance dos dashboards e a escolha por duas fatos deve-se a granularidades diferentes.

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

Para entender se esse aumento gerou impacto operacional, a view **vw_KPI_Entregas** foi utilizada para monitorar os indicadores logísticos do período. O crescimento de receita ocasionou uma deterioração do nível de serviço de entrega. Esse resultado indica a necessidade de diversificação de transportadoras e de monitoramento em tempo real das entregas como medidas preventivas ao aumento de atrasos.

O período coincide com a redução da taxa Selic e com uma política monetária expansionista. Sob a perspectiva macroeconômica, a queda dos juros tende a estimular crédito e consumo, comportamento compatível com o crescimento observado no marketplace.

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
