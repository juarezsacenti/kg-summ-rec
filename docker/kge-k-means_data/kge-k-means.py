#from https://docs.ampligraph.org/en/1.3.2/examples.html#clustering-and-2d-projections

#Embedding training
import argparse
import sys
import math
import numpy as np
import pandas as pd
import requests

from ampligraph.datasets import load_from_ntriples
from ampligraph.latent_features import ComplEx
from ampligraph.latent_features import HolE
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

# Plot figures
import matplotlib as mpl
import matplotlib.pyplot as plt
mpl.rc('axes', labelsize=14)
mpl.rc('xtick', labelsize=12)
mpl.rc('ytick', labelsize=12)


def kge_k_means(data_home, folder, triples_file, items_file, mode, kge_name, epochs, batch_size, learning_rate, rates, view, relations, kg_map_file, verbose):
    # Load triples:
    triples = load_from_ntriples(folder, triples_file, data_home)
    # Load items:
    items = np.array([f'<{x}>' for x in pd.read_csv(items_file, sep='\t', header=None, names=["id", "name", "url"]).url.unique().tolist()])

    # Print Stats:
    if verbose:
        print(f'[kge-k-means] #Triples: {len(triples)}')
        #print(triples[0:10])
        print(f'[kge-k-means] #Items: {len(items)}')
        #print(items[0:10])

    # Select mode:
    if mode == 'singleview':
        singleview(triples, items, kge_name, epochs, batch_size, learning_rate, rates, kg_map_file, verbose)
    elif mode == 'multiview':
        multiview(triples, items, kge_name, epochs, batch_size, learning_rate, rates, relations, kg_map_file, verbose)
    elif mode == 'splitview':
        splitview(triples, items, kge_name, epochs, batch_size, learning_rate, rates, view, kg_map_file, verbose)
    else:
        sys.exit('Given mode is not valid.')


def splitview(triples, items, kge_name, epochs, batch_size, learning_rate, rates, view, kg_map_file, verbose):
    # Select all entities, except items
    triples_df = pd.DataFrame(triples, columns=['s', 'p', 'o'])
    subjects = triples_df.s.unique()
    objects = triples_df.o.unique()
    nodes = np.unique(np.concatenate((subjects, objects)))
    entities = np.setdiff1d(nodes,items)

    if verbose:
        print(f'[kge-k-means] #Nodes: {len(nodes)}')
        #print(nodes[0:10])
        print(f'[kge-k-means] #Entities: {len(entities)}')
        #print(entities[0:10])

    # Train KGE model
    model = kge(triples, kge_name, epochs, batch_size, learning_rate, verbose)

    # Group entities into n-clusters where n in rates
    for rate in rates:
        clusters = clustering(entities, model, rate, verbose)
        # clusters to DF
        cluster_df = pd.DataFrame({'entities': entities,
                                f'cluster{rate}': f'cluster{rate}' + pd.Series(clusters).astype(str)})
        if verbose:
            print(cluster_df[f'cluster{rate}'].value_counts())
            print(cluster_df[f'cluster{rate}'].value_counts().value_counts())
        # DF to file
        cluster_df.to_csv(f'./temp/cluster{rate}-{view}.tsv', sep='\t', header=False, index=False)
        plot_2d_genres(model, rate_df, ratio=rate, kg_map_file=kg_map_file)


def singleview(triples, items, kge_name, epochs, batch_size, learning_rate, rates, kg_map_file, verbose):
    # Select all entities, except items
    triples_df = pd.DataFrame(triples, columns=['s', 'p', 'o'])
    subjects = triples_df.s.unique()
    for i in subjects:
        if type(i) != str:
            print('subjects ', i, type(i))
    objects = triples_df.o.unique()
    for i in objects:
        if type(i) != str:
            print('objects ', i, type(i))
    concatenated = np.concatenate((subjects, objects))
    for i in concatenated:
        if type(i) != str:
            print('concat ', i, type(i))

    print("Concat: " + str(concatenated))
    nodes = np.unique(concatenated)
    print("NODES: " + str(nodes))
    #nodes = np.unique(np.concatenate((subjects, objects)))
    entities = np.setdiff1d(nodes,items)
    print("Entities: " + str(entities))

    if verbose:
        print(f'[kge-k-means] #Nodes: {len(nodes)}')
        #print(nodes[0:10])
        print(f'[kge-k-means] #Entities: {len(entities)}')
        #print(entities[0:10])

    # Train KGE model
    model = kge(triples, kge_name, epochs, batch_size, learning_rate, verbose)

    # Group entities into n-clusters where n in rates
    for rate in rates:
        clusters = clustering(entities, model, rate, verbose)
        # clusters to DF
        cluster_df = pd.DataFrame({'entities': entities,
                                f'cluster{rate}': f'cluster{rate}' + pd.Series(clusters).astype(str)})
        if verbose:
            print(cluster_df[f'cluster{rate}'].value_counts())
            print(cluster_df[f'cluster{rate}'].value_counts().value_counts())
        # DF to file
        cluster_df.to_csv(f'./temp/cluster{rate}.tsv', sep='\t', header=False, index=False)
        plot_2d_genres(model, cluster_df, ratio=rate, kg_map_file=kg_map_file)


def multiview(triples, items, kge_name, epochs, batch_size, learning_rate, rates, relations,kg_map_file, verbose):
    # Select all entities, except items
    triples_df = pd.DataFrame(triples, columns=['s', 'p', 'o'])
    relations = relations.split(',')

    # Train KGE model
    model = kge(triples, kge_name, epochs, batch_size, learning_rate, verbose)

    # Group entities into n-clusters where n in rates
    for rate in rates:
        rate_df = pd.DataFrame(columns=['relation', 'entities', f'cluster{rate}'])
        # Considering triples of each relation as a view
        for r in relations:
            view = triples_df.loc[triples_df['p'] == r]
            subjects = view.s.unique()
            objects = view.o.unique()
            nodes = np.unique(np.concatenate((subjects, objects)))
            entities = np.setdiff1d(nodes,items)

            if verbose:
                print(f'[kge-k-means] Relation: {r}')
                print(f'[kge-k-means] #Nodes: {len(nodes)}')
                #print(nodes[0:10])
                print(f'[kge-k-means] #Entities: {len(entities)}')
                #print(entities[0:10])

            # Group entities into n-clusters
            clusters = clustering(entities, model, rate, verbose)
            # to DF, then to File
            cluster_df = pd.DataFrame({'entities': entities,
                                    f'cluster{rate}': f'cluster{rate}' + pd.Series(clusters).astype(str)})
            cluster_df['relation'] = r

            if verbose:
                print(cluster_df[f'cluster{rate}'].value_counts())
                print(cluster_df[f'cluster{rate}'].value_counts().value_counts())

            rate_df = pd.concat([rate_df, cluster_df])

        rate_df.to_csv(f'./temp/cluster{rate}.tsv', sep='\t', header=False, index=False)
        plot_2d_genres(model, rate_df, ratio=rate, kg_map_file=kg_map_file)


def kge(triples, kge_name, epochs, batch_size, learning_rate, verbose):
    kge_name = parsed_args.kge
    # Train test split
    t_size = math.ceil(len(triples)*0.2)
    X_train, X_test = train_test_split_no_unseen(triples, test_size=t_size)

    # Select kge_name
    if kge_name == 'complex':
        # ComplEx model
        model = ComplEx(batches_count=batch_size,
                        epochs=epochs,
                        k=100,
                        eta=20,
                        optimizer='adam',
                        optimizer_params={'lr':learning_rate},
                        loss='multiclass_nll',
                        regularizer='LP',
                        regularizer_params={'p':3, 'lambda':1e-5},
                        seed=0,
                        verbose=verbose)
    elif kge_name == 'hole':
        # HolE model
        model = HolE(batches_count=batch_size,
                        epochs=epochs,
                        k=100,
                        eta=20,
                        optimizer='adam',
                        optimizer_params={'lr':learning_rate},
                        loss='multiclass_nll',
                        regularizer='LP',
                        regularizer_params={'p':3, 'lambda':1e-5},
                        seed=0,
                        verbose=verbose)
    else:
        sys.exit('Given kge_name is not valid.')

    model.fit(X_train)

    #Embedding evaluation
    if verbose:
        filter_triples = np.concatenate((X_train, X_test))
        ranks = evaluate_performance(X_test,
                                     model=model,
                                     filter_triples=filter_triples,
                                     use_default_protocol=True,
                                     verbose=True)

        mrr = mrr_score(ranks)
        print("MRR: %.2f" % (mrr))
        mr = mr_score(ranks)
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
def clustering(entities, model, rate, verbose):
    # Cluster embeddings (on the original space)
    n_entities = len(entities)
    if verbose:
        print('Considering ' + str(n_entities) + ' entities from triple file...')

    n_clusters = math.ceil(n_entities*rate/100)
    if verbose:
        print('Clustering with n_clusters = '+str(n_clusters))

    clustering_algorithm = KMeans(n_clusters=n_clusters, n_init=10, max_iter=300, random_state=0)
    clusters = find_clusters(entities, model, clustering_algorithm, mode='entity')
    return clusters


def plot_2d_genres(model, cluster_df, ratio, kg_map_file):
    kg_map = {}
    genres = set()
    with open(kg_map_file) as fin:
    	for line in fin:
            (entity_name, entity_uri) = line.rstrip('\n').split('\t')
            if 'genre' in entity_uri:
                kg_map[entity_uri] = entity_name
                genres.add(entity_uri)
    genres = sorted(genres)

    # Zip genres and their corresponding embeddings
    genres_embeddings = dict(zip(genres, model.get_embeddings(genres)))
    genres_embeddings_array = np.array([i for i in genres_embeddings.values()])

    # Project embeddings into 2D space via PCA
    embeddings_2d = PCA(n_components=2).fit_transform(genres_embeddings_array)

    genre_clusters_df = cluster_df.set_index('entities').loc[genres].reset_index(inplace=False)
    genres_df = pd.DataFrame({"genre_uri": list(genres),
                        "x_projection": embeddings_2d[:, 0],
                        "y_projection": embeddings_2d[:, 1],
                        "cluster": "cluster" + genre_clusters_df[f'cluster{ratio}'].astype(str)})

    # Plot 2D embeddings about genres with labels
    plt.figure(figsize=(12, 12))
    plt.title("Genres by ".format('cluster').capitalize())
    ax = sns.scatterplot(data=genres_df,
                         x="x_projection", y="y_projection", hue='cluster')
    texts = []
    for i, point in genres_df.iterrows():
        texts.append(plt.text(point['x_projection']+0.02,
                              point['y_projection']+0.01,
                              str(kg_map[str(point["genre_uri"])[1:-1]])))
    adjust_text(texts)

    # Saving figure
    path = f'./temp/cluster{ratio}.png'
    print("Saving figure in", path)
    plt.tight_layout()
    plt.savefig(path, format='png', dpi=300)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='''Using Ampligraph KGE models with K-means to cluster and then summarize KGs''')

    parser.add_argument('--datahome', type=str, dest='datahome', default='/data')
    parser.add_argument('--folder', type=str, dest='folder', default='temp')
    parser.add_argument('--triples', type=str, dest='triples', default='kg-ig.nt')
    parser.add_argument('--items', type=str, dest='items', default='/data/temp/i2kg_map.tsv')
    parser.add_argument('--mode', type=str, dest='mode', default='singleview')
    parser.add_argument('--kge', type=str, dest='kge', default='complex')
    parser.add_argument('--epochs', type=int, dest='epochs', default=300)
    parser.add_argument('--batch_size', type=int, dest='batch_size', default=100)
    parser.add_argument('--learning_rate', type=str, dest='learning_rate', default='0.0005')
    parser.add_argument('--rates', type=str, dest='rates', default='25,50,75')
    parser.add_argument('--view', type=str, dest='view', default='0')
    parser.add_argument('--relations', type=str, dest='relations', default='<http://ml1m-sun/actor>,<http://ml1m-sun/director>,<http://ml1m-sun/genre>')
    parser.add_argument('--kgmap', type=str, dest='kgmap', default='/data/temp/kg_map.dat')
    parser.add_argument('--verbose', dest='verbose', default=False, action='store_true')

    parsed_args = parser.parse_args()

    data_home = parsed_args.datahome
    folder = parsed_args.folder
    triples_file = parsed_args.triples
    items_file = parsed_args.items
    mode = parsed_args.mode
    kge_name = parsed_args.kge
    epochs = parsed_args.epochs
    batch_size = parsed_args.batch_size
    try:
        learning_rate = float(parsed_args.learning_rate)
    except ValueError:
        raise argparse.ArgumentTypeError("%r not a floating-point literal" % (learning_rate,))

    rates = [ int(rate) for rate in parsed_args.rates.split(',') ]
    view = parsed_args.view
    relations = parsed_args.relations
    kg_map_file = parsed_args.kgmap
    verbose = parsed_args.verbose

    kge_k_means(data_home, folder, triples_file, items_file, mode, kge_name, epochs, batch_size, learning_rate, rates, view, relations, kg_map_file, verbose)
