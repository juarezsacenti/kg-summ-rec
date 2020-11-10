#from https://docs.ampligraph.org/en/1.3.2/examples.html#clustering-and-2d-projections

#Embedding training
import math
import numpy as np
import pandas as pd
import requests

from ampligraph.datasets import load_from_ntriples
from ampligraph.latent_features import ComplEx
from ampligraph.evaluation import evaluate_performance
from ampligraph.evaluation import mr_score, mrr_score, hits_at_n_score
from ampligraph.evaluation import train_test_split_no_unseen

from sklearn.decomposition import PCA
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
import seaborn as sns
from adjustText import adjust_text
from incf.countryutils import transformations
from ampligraph.discovery import find_clusters
from math import ceil

def kge(X):
    # Train test split
    t_size = math.ceil(len(X)*0.2)
    X_train, X_test = train_test_split_no_unseen(X, test_size=t_size)

    # ComplEx model
    model = ComplEx(batches_count=50,
                    epochs=300,
                    k=100,
                    eta=20,
                    optimizer='adam',
                    optimizer_params={'lr':1e-4},
                    loss='multiclass_nll',
                    regularizer='LP',
                    regularizer_params={'p':3, 'lambda':1e-5},
                    seed=0,
                    verbose=True)

    model.fit(X_train)

    #Embedding evaluation
    filter_triples = np.concatenate((X_train, X_test))
    ranks = evaluate_performance(X_test,
                                 model=model,
                                 filter_triples=filter_triples,
                                 use_default_protocol=True,
                                 verbose=True)

    mr = mr_score(ranks)
    mrr = mrr_score(ranks)

    print("MRR: %.2f" % (mrr))
    print("MR: %.2f" % (mr))

    hits_10 = hits_at_n_score(ranks, n=10)
    print("Hits@10: %.2f" % (hits_10))
    hits_3 = hits_at_n_score(ranks, n=3)
    print("Hits@3: %.2f" % (hits_3))
    hits_1 = hits_at_n_score(ranks, n=1)
    print("Hits@1: %.2f" % (hits_1))

    print('''
- Ampligraph example -
MRR: 0.25
MR: 4927.33
Hits@10: 0.35
Hits@3: 0.28
Hits@1: 0.19
    ''')

    return model


# Clustering
def clustering(entities, model):
    # Cluster embeddings (on the original space)
    n_entities = len(entities)
    print('Considering ' + str(n_entities) + ' entities from triple file...')

    # 25%
    n_clusters = math.ceil(n_entities*0.25)
    print('Clustering with n_clusters = '+str(n_clusters))
    clustering_algorithm = KMeans(n_clusters=n_clusters, n_init=10, max_iter=300, random_state=0)
    cluster25 = find_clusters(entities, model, clustering_algorithm, mode='entity')
    # DF to File
    cluster_df = pd.DataFrame({"entities": entities,
                            "cluster25": "cluster25" + pd.Series(cluster25).astype(str)})
    print(cluster_df['cluster25'].value_counts())
    print(cluster_df['cluster25'].value_counts().value_counts())
    cluster_df.to_csv('./temp/cluster25.tsv', sep='\t', header=False, index=False)

    # 50%
    n_clusters = math.ceil(n_entities*0.5)
    print('Clustering with n_clusters = '+str(n_clusters))
    clustering_algorithm = KMeans(n_clusters=n_clusters, n_init=10, max_iter=300, random_state=0)
    cluster50 = find_clusters(entities, model, clustering_algorithm, mode='entity')
    # DF to File
    cluster_df = pd.DataFrame({"entities": entities,
                            "cluster50": "cluster50" + pd.Series(cluster50).astype(str)})
    print(cluster_df['cluster50'].value_counts())
    print(cluster_df['cluster50'].value_counts().value_counts())
    cluster_df.to_csv('./temp/cluster50.tsv', sep='\t', header=False, index=False)

    # 75%
    n_clusters = math.ceil(n_entities*0.75)
    print('Clustering with n_clusters = '+str(n_clusters))
    clustering_algorithm = KMeans(n_clusters=n_clusters, n_init=10, max_iter=300, random_state=0)
    cluster75 = find_clusters(entities, model, clustering_algorithm, mode='entity')
    # DF to File
    cluster_df = pd.DataFrame({"entities": entities,
                            "cluster75": "cluster75" + pd.Series(cluster75).astype(str)})
    print(cluster_df['cluster75'].value_counts())
    print(cluster_df['cluster75'].value_counts().value_counts())
    cluster_df.to_csv('./temp/cluster75.tsv', sep='\t', header=False, index=False)



if __name__ == '__main__':

    #parser = argparse.ArgumentParser(description='''Using Ampligraph KGE models with K-means to cluster and then summarize KGs''')

    #parser.add_argument('--KGE', type=bool, dest='run_kge', default=False)
    #parser.add_argument('--clustering', type=bool, dest='run_clustering', default=False)

    #parsed_args = parser.parse_args()

    #run_kge = parsed_args.run_kge
    #run_clustering = parsed_args.run_clustering

    # Load triples:
    X = load_from_ntriples('temp', 'kg.nt', data_home='/data')
    triples_df = pd.DataFrame(X, columns=['s', 'p', 'o'])
    items = np.array([f'<{x}>' for x in pd.read_csv('/data/temp/i2kg_map.tsv', sep='\t', header=None, names=["id", "name", "url"]).url.unique().tolist()])
    print(f'[kg-summ-rs] #Items: {len(items)}')
    #print(items[0:10])
    subjects = triples_df.s.unique()
    objects = triples_df.o.unique()
    nodes = np.unique(np.concatenate((subjects, objects)))
    print(f'[kg-summ-rs] #Nodes: {len(nodes)}')
    #print(nodes[0:10])
    entities = np.setdiff1d(nodes,items)
    print(f'[kg-summ-rs] #Entities: {len(entities)}')
    #print(entities[0:10])
    #if run_kge:
    model = kge(X) 

    #if run_clustering:
    clustering(entities, model)

