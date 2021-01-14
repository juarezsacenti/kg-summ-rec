import argparse
import sys
import numpy as np
import pandas as pd
from glob import iglob


def join_views(folder, data_home, pattern, output_file):
    input_files = os.path.join(data_home, folder, pattern)
    joint_kg_ig_df = pd.DataFrame(columns=['s', 'p', 'o'])
    for view_file in iglob(input_files):
	triples = load_from_ntriples(folder, view_file, data_home)
        df = pd.DataFrame(triples, columns=['s', 'p', 'o'])
        joint_kg_ig_df = pd.concat([joint_kg_ig_df, df])
    joint_kg_ig_df.to_csv(output_file, sep='\t', header=False, index=False)
    


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='''Using Ampligraph KGE models with K-means to cluster and then summarize KGs''')
   
    parser.add_argument('--datahome', type=str, dest='datahome', default='../docker/gemsec_data/')
    parser.add_argument('--folder', type=str, dest='folder', default='temp')
    parser.add_argument('--pattern', type=str, dest='pattern', default='kg-ig-*.nt')
    parser.add_argument('--output_file', type=str, dest='output_file', default='../docker/gemsec_data/temp/joint-kg-ig.nt')
    parser.add_argument('--verbose', dest='verbose', default=False, action='store_true')

    parsed_args = parser.parse_args()

    input_path = parsed_args.input
    folder = parsed_args.folder
    data_home = parsed_args.datahome
    pattern = parsed_args.pattern
    ouput_file = parsed_args.output_file

    join_views(folder, data_home, pattern, output_file)

