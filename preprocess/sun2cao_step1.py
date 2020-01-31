#This is used to map the auxiliary information (genre, director and actor) into mapping ID for MovieLens

import argparse
import os

def mapping(fr_auxiliary, fr_i2kg_map, fw_mapping):
    '''
    mapping the auxiliary info (e.g., genre, director, actor) into ID

    Inputs:
        @fr_auxiliary: the auxiliary infomation
        @fw_mapping: the auxiliary mapping information
    '''
    actor_map = {}
    director_map = {}
    genre_map = {}

    actor_count = director_count = genre_count = 0
    all_entity_set = set()
    input_entity_set = set()

    i2kg_map = {}
    for line in fr_i2kg_map:
        (id, name, uri) = line.split("\t")
        i2kg_map[int(id)] = uri.replace('\n', '')

    for line in fr_auxiliary:

        lines = line.replace('\n', '').split('|')
        if len(lines) != 4:
            continue

        movie_id = lines[0].split(':')[1]
        genre_list = []
        director_list = []
        actor_list = []

        for genre in lines[1].split(":")[1].split(','):
            if genre not in genre_map:
                genre_map.update({genre:genre_count})
                genre_list.append(genre_count)
                genre_count = genre_count + 1
            else:
                genre_id = genre_map[genre]
                genre_list.append(genre_id)

        for director in lines[2].split(":")[1].split(','):
            if director not in director_map:
                director_map.update({director:director_count})
                director_list.append(director_count)
                director_count = director_count + 1
            else:
                director_id = director_map[director]
                director_list.append(director_id)

        for actor in lines[3].split(':')[1].split(','):
            if actor not in actor_map:
                actor_map.update({actor:actor_count})
                actor_list.append(actor_count)
                actor_count = actor_count + 1
            else:
                actor_id = actor_map[actor]
                actor_list.append(actor_id)

        # Writing
        head_json_str = "["

        for genre_id in genre_list:
            head_json_str += '{ "p": { "type": "uri", "value": "http://ml1m-sun/genre" }, "o": { "type": "uri", "value": "http://ml1m-sun/genre' + str(genre_id) + '" }}'
            head_json_str += ', '

        for director_id in director_list:
            head_json_str += '{ "p": { "type": "uri", "value": "http://ml1m-sun/director" }, "o": { "type": "uri", "value": "http://ml1m-sun/director' + str(director_id) + '" }}'
            head_json_str += ', '

        for actor_id in actor_list:
            head_json_str += '{ "p": { "type": "uri", "value": "http://ml1m-sun/actor" }, "o": { "type": "uri", "value": "http://ml1m-sun/actor' + str(actor_id) + '" }}'
            head_json_str += ', '

        head_json_str = head_json_str[:-2] + "]"
        output_line = i2kg_map.get(int(movie_id), "http://ml1m-sun/movie_"+movie_id) + '\t' + head_json_str + '\t' + '[]' + '\n'
        fw_mapping.write(output_line)

        ''' WRONG NEW CODE
        new_movie_id = int(movie_id) - 1
        for genre_id in genre_list:
            output_line = f'{new_movie_id}' + ' 0 ' + f'{genre_id}' + '\n'
            fw_mapping.write(output_line)

        for director_id in director_list:
            output_line = f'{new_movie_id}' + ' 1 ' + f'{director_id}' + '\n'
            fw_mapping.write(output_line)

        for actor_id in actor_list:
            output_line =  f'{new_movie_id}' + ' 2 ' +f'{actor_id}' + '\n'
            fw_mapping.write(output_line)
        '''

        ''' OLD CODE
        genre_list = ",".join(list(map(str, genre_list)))
        director_list = ",".join(list(map(str, director_list)))
        actor_list = ",".join(list(map(str, actor_list)))

        output_line = movie_id + '|' + genre_list + '|' + director_list + '|' + actor_list + '\n'
        fw_mapping.write(output_line)
        '''
        # Entities and predicates
        all_entity_set.add(i2kg_map.get(int(movie_id), "http://ml1m-sun/movie_"+movie_id))
        input_entity_set.add(movie_id)

    for actor_id in actor_map.values():
        all_entity_set.add("http://ml1m-sun/actor{}".format(actor_id))
    for director_id in director_map.values():
        all_entity_set.add("http://ml1m-sun/director{}".format(director_id))
    for genre_id in actor_map.values():
        all_entity_set.add("http://ml1m-sun/genre{}".format(genre_id))

    all_predicate_set = set()
    all_predicate_set.add("http://ml1m-sun/actor")
    all_predicate_set.add("http://ml1m-sun/director")
    all_predicate_set.add("http://ml1m-sun/genre")

    data_path = "../../datasets/"
    dataset = 'ml1m-sun2cao'
    dataset_path = os.path.join(data_path, dataset)
    kg_path = os.path.join(dataset_path, 'kg')
    predicate_file = os.path.join(kg_path, "predicate_vocab.dat")
    with open(predicate_file, 'w') as fout:
        for pred in all_predicate_set:
            fout.write(pred + '\n')

    relations_file = os.path.join(kg_path, "relation_filter.dat")
    with open(relations_file, 'w') as fout:
        for pred in all_predicate_set:
            fout.write(pred + '\n')

    entity_file = os.path.join(kg_path, "entity_vocab.dat")
    with open(entity_file, 'w') as fout:
        for ent in all_entity_set:
            fout.write(ent + '\n')

    input_entity_file = os.path.join(dataset_path, "i2kg_map.tsv")
    with open(input_entity_file, 'w') as fout:
        id=1
        for movie_id in input_entity_set:
            fout.write(str(movie_id) + '\t' + "name" + '\t' + i2kg_map.get(int(movie_id), "http://ml1m-sun/movie_"+movie_id) + '\n')
            id+=1

    return genre_count, director_count, actor_count


def print_statistic_info(genre_count, director_count, actor_count):
    '''
    print the number of genre, director and actor
    '''

    print ('The number of genre is: ' + str(genre_count))
    print ('The number of director is: ' + str(director_count))
    print ('The number of actor is: ' + str(actor_count))


if __name__ == '__main__':

    print(os.getcwd())
    parser = argparse.ArgumentParser(description=''' Map Auxiliary Information into ID''')

    parser.add_argument('--auxiliary', type=str, dest='auxiliary_file', default='../../datasets/ml1m-sun/auxiliary.txt')
    parser.add_argument('--i2kg_map', type=str, dest='i2kg_map_file', default='../../datasets/ml1m-cao/i2kg_map.tsv')
    parser.add_argument('--mapping', type=str, dest='mapping_file', default='../../datasets/ml1m-sun2cao/kg_hop0_sun.dat')

    parsed_args = parser.parse_args()

    auxiliary_file = parsed_args.auxiliary_file
    i2kg_map_file = parsed_args.i2kg_map_file
    mapping_file = parsed_args.mapping_file

    fr_auxiliary = open(auxiliary_file,'r', encoding="utf-8")
    fr_i2kg_map = open(i2kg_map_file, 'r', encoding="utf8")
    fw_mapping = open(mapping_file,'w')

    genre_count, director_count, actor_count = mapping(fr_auxiliary, fr_i2kg_map, fw_mapping)
    print_statistic_info(genre_count, director_count, actor_count)

    fr_auxiliary.close()
    fw_mapping.close()
