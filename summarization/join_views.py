import argparse
import os
import numpy as np
import pandas as pd
from glob import iglob


def join_clusters(folder, data_home, pattern, output_file):
    nl='\n'
    tab='\t'
    view_prop = {'0': '<http://ml1m-sun/actor>', '1': '<http://ml1m-sun/director>', '2': '<http://ml1m-sun/genre>'}
    input_files = os.path.join(data_home, folder, pattern)
    with open(output_file, 'w') as fout:
        for view_file in iglob(input_files):
            (prefix, suffix) = os.path.basename(view_file).split('.')
            (name, view_number)  = prefix.split('-')
            with open(view_file) as fin:
                for line in fin:
                    (entity_uri, cluster) = line.rstrip('\n').split('\t')
                    fout.write(f"{view_prop[view_number]}{tab}{entity_uri}{tab}{cluster}{nl}")


def join_views(folder, data_home, pattern, output_file):
    input_files = os.path.join(data_home, folder, pattern)
    joint_kg_ig_df = pd.DataFrame(columns=['s', 'p', 'o'])
    for view_file in iglob(input_files):
        triples = load_from_ntriples(folder, view_file, data_home)
        df = pd.DataFrame(triples, columns=['s', 'p', 'o'])
        joint_kg_ig_df = pd.concat([joint_kg_ig_df, df])
    joint_kg_ig_df.to_csv(output_file, sep='\t', header=False, index=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='''JOIN VIEWS''')

    parser.add_argument('--datahome', type=str, dest='datahome', default='../docker/gemsec_data/')
    parser.add_argument('--folder', type=str, dest='folder', default='temp')
    parser.add_argument('--pattern', type=str, dest='pattern', default='cluster*.tsv')
    parser.add_argument('--mode', type=str, dest='mode', default='clusters')
    parser.add_argument('--output_file', type=str, dest='output_file', default='../docker/gemsec_data/temp/cluster.tsv')
    parser.add_argument('--verbose', dest='verbose', default=False, action='store_true')

    parsed_args = parser.parse_args()

    data_home = parsed_args.datahome
    folder = parsed_args.folder
    pattern = parsed_args.pattern
    mode = parsed_args.mode
    output_file = parsed_args.output_file

    try:
        if mode == 'clusters':
            join_clusters(folder, data_home, pattern, output_file)
        elif mode == 'assignments':
            join_assignments(folder, data_home, pattern, output_file)
        else:
            raise ValueError
    except ValueError:
        print(f'Join mode {mode} is invalid.')
