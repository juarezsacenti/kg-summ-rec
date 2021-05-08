import argparse
from collections import defaultdict
import pandas as pd

def count_clusters(clusterfile):
    c_map = defaultdict(list)
    with open(clusterfile) as fin:
        for line in fin:
            (relation, uri, cluster) = line.rstrip('\n').split('\t')
            c_map[cluster].append(uri)
    for k, v in c_map:
        count[sorted(v)] = count.setdefault(sorted(v), 0) + 1
    c_df = pd.DataFrame.from_dict(count, orient='index')
    print(c_df.value_counts())

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='''Using Ampligraph KGE models with K-means to cluster and then summarize KGs''')
    parser.add_argument('--clusterfile', type=str, dest='clusterfile', default='/data')
    parsed_args = parser.parse_args()
    clusterfile = parsed_args.clusterfile
    count_clusters(clusterfile)
