import logging
import os
import sys
sys.path.append(os.path.abspath('../../joint-kg-recommender'))

from jTransUP.data.preprocessRatings import preprocess as preprocessRating
from jTransUP.data.preprocessTriples import preprocess as preprocessKG

data_path = "../../datasets/ml1m-sun2cao/"
dataset = 'ml1m'

dataset_path = os.path.join(data_path, dataset)
kg_path = os.path.join(dataset_path, 'kg')

triple_file = os.path.join(dataset_path, "kg_hop0_sun.dat")
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

preprocessKG([triple_file], kg_path, entity_file=i2kg_file, relation_file=relation_file, logger=logger)
