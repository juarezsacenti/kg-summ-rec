import argparse
import os
import pandas as pd
import numpy as np


def split_for_sun_mo(kg_euig, output_path, verbose):
    # Select all entities, except items
    triples_df = pd.DataFrame(kg_euig, columns=['s', 'p', 'o', 'dot'])

    p_actor='<http://ml1m-sun/actor>'
    p_director='<http://ml1m-sun/director>'
    p_genre='<http://ml1m-sun/genre>'
    p_rates='<http://ml1m-sun/rates>'
    p_type='<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>'
    p_subclassof='<http://www.w3.org/2000/01/rdf-schema#subClassOf>'
    o_actor='<http://dbpedia.org/ontology/Actor>'
    o_director='<http://dbpedia.org/page/Film_Director>'

    df_actors = triples_df.loc[triples_df['p'] == p_actor]
    df_actor_type = triples_df.loc[triples_df['o'] == o_actor]
    df_users = triples_df.loc[triples_df['p'] == p_rates]
    actor_view = pd.concat([df_actors, df_actor_type, df_users])
    output_file = os.path.join(output_path, f'kg-euig-0.nt')
    save_as_ntriples(actor_view, output_file)

    df_directors = triples_df.loc[triples_df['p'] == p_director]
    df_director_type = triples_df.loc[triples_df['o'] == o_director]
    director_view = pd.concat([df_directors, df_director_type, df_users])
    output_file = os.path.join(output_path, f'kg-euig-1.nt')
    save_as_ntriples(director_view, output_file)

    df_genres = triples_df.loc[triples_df['p'] == p_genre]
    df_genre_type = triples_df.loc[triples_df['p'] == p_type]
    df_genre_type = df_genre_type.merge(df_actor_type, indicator='i', how='outer').query('i == "left_only"').drop('i', 1)
    df_genre_type = df_genre_type.merge(df_director_type, indicator='i', how='outer').query('i == "left_only"').drop('i', 1)
    df_genre_subclassof = triples_df.loc[triples_df['p'] == p_subclassof]
    genre_view = pd.concat([df_genres, df_genre_type, df_genre_subclassof, df_users])
    output_file = os.path.join(output_path, f'kg-euig-2.nt')
    save_as_ntriples(genre_view, output_file)


def split_by_relation(kg_ig, output_path, verbose):
    # Select all entities, except items
    triples_df = pd.DataFrame(kg_ig, columns=['s', 'p', 'o', 'dot'])
    relations = triples_df.p.unique()
    relations.sort()

    for i in range(0, len(relations)):
        r = relations[i]
        kg_ig_view_df = triples_df.loc[triples_df['p'] == r]

        if verbose:
            print(f'[kg-summ-rec] split_views: by relation {r}')
            print(f'[kg-summ-rec] split_views: #Triples: {len(kg_ig_view_df)}')

            subjects = kg_ig_view_df.s.unique()
            objects = kg_ig_view_df.o.unique()
            nodes = np.unique(np.concatenate((subjects, objects)))
            print(f'[kg-summ-rec] split_views: #Nodes: {len(nodes)}')
            #print(nodes[0:10])

            #items = np.array([f'<{x}>' for x in pd.read_csv(items_file, sep='\t', header=None, names=["id", "name", "url"]).url.unique().tolist()])
            #entities = np.setdiff1d(nodes,items)
            #print(f'[kge-k-means] #Entities: {len(entities)}')
            #print(entities[0:10])

        output_file = os.path.join(output_path, f'kg-ig-{i}.nt')
        save_as_ntriples(kg_ig_view_df, output_file)


def save_as_ntriples(kg_ig_view_df, output_file):
    kg_ig_view_df.to_csv(output_file, sep=' ', header=False, index=False)


def load_from_ntriples(file_in):
    kg = pd.read_csv(file_in, sep=' ', header=None, names= ['s','p','o','dot'])
    print('KG LEN: '+str(len(kg)) )
    return kg

def split_views(data_home, folder, input_file, mode, output_path, verbose):
    kg_file = os.path.join(data_home, folder, input_file)
    kg = load_from_ntriples(kg_file)

    try:
        if mode == 'relation':
            split_by_relation(kg, output_path, verbose)
        elif mode == 'sun_mo':
            split_for_sun_mo(kg, output_path, verbose)
        else:
            raise ValueError
    except ValueError:
        print(f'Split mode {mode} is invalid.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='''Split KG item-graph into KG item-graph views''')

    parser.add_argument('--datahome', type=str, dest='datahome', default='../docker/gemsec_data')
    parser.add_argument('--folder', type=str, dest='folder', default='temp')
    parser.add_argument('--input', type=str, dest='input_file', default='kg-ig.nt')
    parser.add_argument('--mode', type=str, dest='mode', default='relation')
    parser.add_argument('--output', type=str, dest='output_path', default='../docker/gemsec_data/temp/')
    parser.add_argument('--verbose', dest='verbose', default=False, action='store_true')

    parsed_args = parser.parse_args()

    folder = parsed_args.folder
    input_file = os.path.expanduser(parsed_args.input_file)
    data_home = parsed_args.datahome
    mode = parsed_args.mode
    output_path = os.path.expanduser(parsed_args.output_path)
    verbose = parsed_args.verbose

    split_views(data_home, folder, input_file, mode, output_path, verbose)
