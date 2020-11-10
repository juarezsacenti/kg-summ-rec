import argparse
import logging
import os
import sys
sys.path.append(os.path.abspath('../../joint-kg-recommender'))

from jTransUP.data.preprocessRatings import preprocess as preprocessRating
from jTransUP.data.preprocessTriples import preprocess as preprocessKG


if __name__ == '__main__':

    #print(os.getcwd())
    parser = argparse.ArgumentParser(description='''Step 2: ''')

    parser.add_argument('--data_path', type=str, dest='data_path', default='../../datasets/ml1m-sun2cao/')
    parser.add_argument('--dataset', type=str, dest='dataset', default='ml1m')
    parser.add_argument('--filterunseen', type=bool, dest='filter_unseen', default=True)
    parser.add_argument('--lowfrequence', type=int, dest='low_frequence', default=10)

    parsed_args = parser.parse_args()

    data_path = os.path.expanduser(parsed_args.data_path)
    dataset = parsed_args.dataset
    filter_unseen = parsed_args.filter_unseen
    low_frequence = parsed_args.low_frequence

    dataset_path = os.path.join(data_path, dataset)
    kg_path = os.path.join(dataset_path, 'kg')

    triple_file = os.path.join(kg_path, "kg_hop0.dat")
    relation_file = os.path.join(kg_path, "relation_filter.dat")
    i2kg_file = os.path.join(dataset_path, "i2kg_map.tsv")

    log_path = dataset_path

    logger = logging.getLogger()
    logger.setLevel(level=logging.DEBUG)

    log_file = os.path.join(dataset_path, "data_preprocess.log")
    # Formatter
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    # FileHandler
    file_handler = logging.FileHandler(log_file)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    # StreamHandler
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)

    #print(kg_path)
    preprocessKG([triple_file], kg_path, entity_file=i2kg_file, relation_file=relation_file, train_ratio=0.7, test_ratio=0.2, shuffle_data_split=True, filter_unseen_samples=filter_unseen, low_frequence=low_frequence, logger=logger)
