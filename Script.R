library(MASS)
library(ggplot2)
library(mclust)
library(psych)
library(corrplot)
library(dplyr)
library(parameters)
library(gpairs)
library(kohonen)
library(cluster)
library(reshape2)
library(GGally)


# Importar dataset
dataset <- read.csv("Preco_casas.csv", header = TRUE)

# Remover variável ID
dataset <- dataset[,-1]

# Remover linhas com Preço igual a 0 ou nrWC ausente
dataset <- dataset %>%
  filter(preco != 0 & nrWC != 0)

# Filtrar as linhas onde Ano_renovacao é válido (maior ou igual ao Ano_construcao)
dataset <- dataset %>%
  filter(Ano_renovacao == 0 | Ano_renovacao >= Ano_construcao)

# Remover os três outliers mais significativos (preços muito altos e muito baixos)
dataset <- dataset[-c(3745, 3744, 3741), ]

# 6 primeiros registos do dataset
head(dataset)

# Variáveis INPUT (ativas)
input <- dataset[, c("nrQuartos", "nrWC", "Sala_estar_m2", "piso_m2", "condicao", "lote_m2", "vista", "Ano_renovacao", "nrAndares")]

# Variáveis PROFILE (passivas)
profile <- dataset[, c("Ano_construcao", "preco")]

# Verificar adequação para PCA
KMO(input)

# Matriz de correlação
correlation <- cor(input)
par(oma = c(2, 2, 2, 2)) # espaço em volta para texto
corrplot.mixed(correlation, 
               order = "hclust", # ordenar variáveis
               tl.pos = "lt", # texto à esquerda + topo
               upper = "ellipse")

# Escalar as variáveis input
input_scaled <- scale(input)

# PCA
pca <- principal(input_scaled, nfactors = 9, rotate = "none") 
round(pca$values, 3)

# Screeplot - Identificar o cotovelo
plot(pca$values, type = "b", main = "Scree plot",
     xlab = "Number of PC", ylab = "Eigenvalue")  

# Loadings das variáveis
pca$loadings




# Selecionar os scores dos 4 primeiros componentes principais
pca_scores <- as.data.frame(pca$scores[, 1:4])

# Testar diferentes números de clusters (2 a 10 neste caso)
silhouette_scores <- vector("numeric", length = 9)
for (k in 2:10) {
  km <- kmeans(pca_scores, centers = k, nstart = 25)
  silhouette_scores[k - 1] <- mean(silhouette(km$cluster, dist(pca_scores))[, 3])
}

# Plot do Silhouette Score
plot(2:10, silhouette_scores, type = "b", pch = 19,
     xlab = "Número de Clusters", ylab = "Silhouette Score",
     main = "Silhouette Clustering para Número Ideal de Clusters")

# Escolher o número ideal de clusters com base no gráfico
num_clusters <- which.max(silhouette_scores) + 1
print(paste("Número ideal de clusters:", num_clusters))

# Aplicar K-means com o número ideal de clusters
final_kmeans <- kmeans(pca_scores, centers = num_clusters, nstart = 25)
dataset$cluster <- final_kmeans$cluster

# Visualizar resultados
table(dataset$cluster)

# Estatísticas descritivas por cluster
cluster_summary <- dataset %>%
  group_by(cluster) %>%
  summarise(
    preco_medio = mean(preco, na.rm = TRUE),
    preco_sd = sd(preco, na.rm = TRUE),
    ano_construcao_medio = mean(Ano_construcao, na.rm = TRUE),
    ano_construcao_sd = sd(Ano_construcao, na.rm = TRUE),
    .groups = "drop"
  )

print(cluster_summary)




# Adicionar labels de cluster ao dataset
pca_scores$cluster <- factor(dataset$cluster)

# Grafico de dispersão dos dois primeiros componentes principais
# Para o plot de PC3 e PC4, Mudar as variáveis x e y dentro de aes para PC3 e PC4
ggplot(pca_scores, aes(x = PC1, y = PC2, color = cluster)) +
  geom_point(alpha = 0.6, size = 2) +
  labs(title = "Clusters in PCA Space",
       x = "Comodidades Interiores",
       y = "Qualidade para viver") +
  theme_minimal() +
  scale_color_brewer(palette = "Set1")



# Gráfico boxplot adicional opcional. Não foi usado no relatório
ggplot(dataset, aes(x = factor(cluster), y = preco, fill = factor(cluster))) +
  geom_boxplot() +
  labs(title = "Boxplot of Prices by Cluster",
       x = "Cluster",
       y = "Price") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set2")


# Gráfico pairplot adicional opcional. Não foi usado no relatório
ggpairs(pca_scores, aes(color = cluster)) +
  labs(title = "Pairplot dos Componentes Principais com Clusters")



########################################################

#### Daqui para baixo foram apenas códigos de teste ####
#### Não usados para a versão final do relatório    ####

########################################################

# Aplicar GMM aos scores do PCA
gmm_model <- Mclust(pca_scores[, 1:4])  # Consideramos os 4 primeiros componentes principais
summary(gmm_model)

# Obter clusters
pca_scores$gmm_cluster <- as.factor(gmm_model$classification)

# Visualizar clusters
ggplot(pca_scores, aes(x = PC1, y = PC2, color = gmm_cluster)) +
  geom_point(alpha = 0.6, size = 2) +
  labs(title = "Clusters (GMM) no Espaço PCA",
       x = "Principal Component 1",
       y = "Principal Component 2") +
  theme_minimal() +
  scale_color_brewer(palette = "Set2")





# Clustering Hierárquico
dist_matrix <- dist(pca_scores[, 1:4])  # Matriz de distâncias
hclust_model <- hclust(dist_matrix, method = "ward.D2")

# Dendrograma
plot(hclust_model, labels = FALSE, main = "Dendrograma do Clustering Hierárquico")

# Cortar a árvore em 5 clusters
hc_clusters <- cutree(hclust_model, k = 5)
pca_scores$hc_cluster <- as.factor(hc_clusters)

# Visualizar clusters
ggplot(pca_scores, aes(x = PC1, y = PC2, color = hc_cluster)) +
  geom_point(alpha = 0.6, size = 2) +
  labs(title = "Clusters (Hierárquico) no Espaço PCA",
       x = "Principal Component 1",
       y = "Principal Component 2") +
  theme_minimal() +
  scale_color_brewer(palette = "Dark2")



# Comparar a correspondência entre métodos
table(pca_scores$gmm_cluster, pca_scores$hc_cluster)

# Comparar Silhouette Scores
silhouette_gmm <- silhouette(as.numeric(pca_scores$gmm_cluster), dist_matrix)
silhouette_hc <- silhouette(as.numeric(pca_scores$hc_cluster), dist_matrix)

mean(silhouette_gmm[, 3])  # Silhouette médio para GMM
mean(silhouette_hc[, 3])   # Silhouette médio para Hierárquico

