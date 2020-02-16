import argparse
import os
from collections import defaultdict

def mapping(input_folder, fw_mapping):
    '''
    mapping train.dat, test.dat, valid.dat, e_map.dat, r_map.dat, i2kg_map
    into auxiliary_mapping.txt

    Inputs:
        @input_folder: the Cao's data folder
        @fw_mapping: the auxiliary mapping information
    '''
    kg = defaultdict(lambda: defaultdict(list))
    triple_count = 0
    item_set = set()
    entity_set = set()
    kg_path = os.path.join(input_folder, 'kg')

    train_file = os.path.join(kg_path, 'train.dat')
    with open(train_file, 'r', encoding="utf-8") as fin:
        for line in fin:
            (sub, obj, pred) = line.split("\t")
            kg[sub][pred.replace('\n', '')].append(obj)
            triple_count += 1
            item_set.add(sub)
            entity_set.add(obj)

    test_file = os.path.join(kg_path, 'test.dat')
    with open(test_file, 'r', encoding="utf-8") as fin:
        for line in fin:
            (sub, obj, pred) = line.split("\t")
            kg[sub][pred.replace('\n', '')].append(obj)
            triple_count += 1
            item_set.add(sub)
            entity_set.add(obj)

    valid_file = os.path.join(kg_path, 'valid.dat')
    with open(valid_file, 'r', encoding="utf-8") as fin:
        for line in fin:
            (sub, obj, pred) = line.split("\t")
            kg[sub][pred.replace('\n', '')].append(obj)
            triple_count += 1
            item_set.add(sub)
            entity_set.add(obj)

    r_map_file = os.path.join(kg_path, 'r_map.dat')
    relation_list = []
    with open(r_map_file, 'r', encoding="utf-8") as fin:
        for line in fin:
            (r_id, uri) = line.split("\t")
            relation_list.append(r_id)

    for sub in kg.keys():
        output_line = sub
        for r_id in relation_list:
            output_line += '|' + str(kg[sub][r_id]).strip('[]')
        output_line += '\n'
        fw_mapping.write(output_line)

    return len(item_set), len(entity_set.union(item_set)), len(relation_list), triple_count


def back_to_ratings(input_folder, fw_ratings):
    '''
    Union of train.dat, valid.dat, test.dat to ratings-delete-missing-itemid.txt
    '''
    time = "0"
    ratings_cnt = 0

    train_file = os.path.join(input_folder, 'train.dat')
    with open(train_file, 'r', encoding="utf-8") as fin:
        for line in fin:
            (u_id, i_id, rate) = line.split("\t")
            fw_ratings.write(u_id+"\t"+i_id+"\t"+rate.replace('\n', '')+"\t"+time+"\n")
            ratings_cnt += 1

    valid_file = os.path.join(input_folder, 'valid.dat')
    with open(valid_file, 'r', encoding="utf-8") as fin:
        for line in fin:
            (u_id, i_id, rate) = line.split("\t")
            fw_ratings.write(u_id+"\t"+i_id+"\t"+rate.replace('\n', '')+"\t"+time+"\n")
            ratings_cnt += 1

    test_file = os.path.join(input_folder, 'test.dat')
    with open(test_file, 'r', encoding="utf-8") as fin:
        for line in fin:
            (u_id, i_id, rate) = line.split("\t")
            fw_ratings.write(u_id+"\t"+i_id+"\t"+rate.replace('\n', '')+"\t"+time+"\n")
            ratings_cnt += 1

    return ratings_cnt


def print_statistic_info(item_count, entity_count, relation_count, triple_count, ratings_count):
    '''
    print the number of item, entity, relations, triples
    '''

    print ('The number of item is: ' + str(item_count))
    print ('The number of entity is: ' + str(entity_count))
    print ('The number of relations is: ' + str(relation_count))
    print ('The number of triples is: ' + str(triple_count))
    print ('The number of ratings is: ' + str(ratings_count))


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description=''' Map Auxiliary Information into ID''')

    parser.add_argument('--input_folder', type=str, dest='input_folder', default='../../datasets/ml1m-cao/ml1m/')
    parser.add_argument('--mapping', type=str, dest='mapping_file', default='../../datasets/ml1m-cao2sun/ml1m/auxiliary-mapping.txt')
    parser.add_argument('--ratings', type=str, dest='ratings_file', default='../../datasets/ml1m-cao2sun/ml1m/rating-delete-missing-itemid.txt')

    parsed_args = parser.parse_args()

    input_folder = parsed_args.input_folder
    mapping_file = parsed_args.mapping_file
    ratings_file = parsed_args.ratings_file

    fw_mapping = open(mapping_file,'w')
    item_count, entity_count, relations_count, triples_count = mapping(input_folder, fw_mapping)
    fw_mapping.close()

    fw_ratings = open(ratings_file,'w')
    ratings_count = back_to_ratings(input_folder, fw_ratings)
    fw_ratings.close()

    print_statistic_info(item_count, entity_count, relations_count, triples_count, ratings_count)
