import argparse
import pandas as pd
import numpy as np
from ampligraph.datasets import load_from_ntriples


def split_views(data_home, folder, input_file, mode, output_path, verbose):
    kg_ig = load_from_ntriples(folder, input_file, data_home)

    try
        if mode == 'relation':
            split_by_relation(kg_ig, output_path, verbose)
        else
            raise ValueError
    except ValueError:
        print(f'Split mode {mode} is invalid.')


def split_by_relation(kg_ig, output_path, verbose):
    # Select all entities, except items
    triples_df = pd.DataFrame(kg_ig, columns=['s', 'p', 'o'])
    relations = triples_df.p.unique()

    for i in range(0, len(relations)):
        r = relations[i]
        kg_ig_view_df = triples_df.loc[triples_df['p'] == r]
        
        if verbose:
            print(f'[kg-summ-rec] split_views: by relation {r}')
            print(f'[kg-summ-rec] split_views: #Triples: {len(kg_ig_view_df)}'

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
    kg_ig_view_df.to_csv(output_file, sep='\t', header=False, index=False)


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
