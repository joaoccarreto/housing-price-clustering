# Housing Price Clustering

Identifying distinct segments in the real estate market through dimensionality reduction and unsupervised learning, using a housing dataset with over 3,700 properties.

## Overview

The goal is to uncover natural groupings among properties based on their physical characteristics — without using the price as an input — and then profile each cluster against price and construction year to assess their economic meaning.

## Dataset

| Variable | Type | Description |
|----------|------|-------------|
| `nrQuartos` | Active | Number of bedrooms |
| `nrWC` | Active | Number of bathrooms |
| `Sala_estar_m2` | Active | Living room area (m²) |
| `piso_m2` | Active | Floor area (m²) |
| `condicao` | Active | Property condition score |
| `lote_m2` | Active | Lot size (m²) |
| `vista` | Active | View quality score |
| `Ano_renovacao` | Active | Year of last renovation (0 if never) |
| `nrAndares` | Active | Number of floors |
| `preco` | Profile | Sale price — used only to profile clusters |
| `Ano_construcao` | Profile | Year of construction — used only to profile clusters |

**Data cleaning applied:**
- Removed properties with price = 0 or missing bathrooms
- Removed invalid renovation years (renovation before construction)
- Removed 3 extreme price outliers

## Methodology

### 1. PCA — Dimensionality Reduction
- KMO test to assess factorability
- Correlation matrix (hierarchical ordering)
- Scree plot to identify the elbow
- **4 principal components** retained (balancing explained variance and interpretability)

### 2. K-Means Clustering
- Applied to PCA scores (4 components)
- Number of clusters determined by **silhouette score maximisation** over k = 2–10
- 25 random starts per k to avoid local optima

### 3. Cluster Profiling
- Distribution of observations per cluster
- Mean and standard deviation of **price** and **construction year** per cluster
- PCA scatter plots (PC1 vs PC2, PC3 vs PC4) coloured by cluster assignment

### 4. Alternative Methods (exploratory)
| Method | Notes |
|--------|-------|
| GMM (Mclust) | Probabilistic assignment; model selection via BIC |
| Hierarchical clustering | Ward's D2 linkage; dendrogram cut at k = 5 |
| Silhouette comparison | Used to benchmark all three approaches |

K-Means on PCA scores was selected as the final model based on interpretability and silhouette performance.

## Files

```
├── Script.R                  # Full analysis
└── Preco_casas.csv           # Dataset
```

## Stack

![R](https://img.shields.io/badge/R-276DC3?style=flat-square&logo=r&logoColor=white)

**Libraries:** `MASS`, `ggplot2`, `mclust`, `psych`, `corrplot`, `dplyr`, `parameters`, `kohonen`, `cluster`, `reshape2`, `GGally`
