#This is used to map the auxiliary information (genre, director and actor) into mapping ID for MovieLens

import argparse
import os
import numpy as np
import pandas as pd # pandas is a data manipulation library
from rdflib import Graph


def load_ml1m_sun_data(csv_path):
    # pass in column names for each CSV
    r_cols = ['movie_id', 'genre', 'director', 'actors']
    auxiliary = pd.read_csv(csv_path, sep='|', engine="python", names=r_cols, encoding='utf-8-sig', header=None)
    auxiliary['movie_id'] = auxiliary['movie_id'].str.split(':').str[1]
    auxiliary['movie_id'] = pd.to_numeric(auxiliary['movie_id'])
    auxiliary['genre'] = auxiliary['genre'].str.split(':').str[1]
    auxiliary['director'] = auxiliary['director'].str.split(':').str[1]
    auxiliary['actors'] = auxiliary['actors'].str.split(':').str[1]
    return auxiliary


def cleanning(auxiliary):
    auxiliary = auxiliary.replace('nan', np.NaN)
    return auxiliary


def df2nt(df_auxiliary, output_file, i2kg_map_file=''):
    actor_map = {}
    director_map = {}
    genre_map = {}

    actor_count = director_count = genre_count = 0

    i2kg_map = {}
    if not i2kg_map_file == '':
        with open(i2kg_map_file) as fin:
            for line in fin:
                (id, name, uri) = line.split("\t")
                i2kg_map[int(id)] = uri.replace('\n', '')

    if len(df_auxiliary.columns) != 4:
        print(df_auxiliary.columns)

    with open(output_file, 'w') as fout:
        for index, row in df_auxiliary.iterrows():
            movie_id = str(row['movie_id'])
            genre_list = []
            director_list = []
            actor_list = []

            if pd.notnull(row['genre']):
                for genre in row['genre'].split(','):
                    if genre not in genre_map:
                        genre_map.update({genre:genre_count})
                        genre_list.append(genre_count)
                        genre_count = genre_count + 1
                    else:
                        genre_id = genre_map[genre]
                        genre_list.append(genre_id)

            if pd.notnull(row['director']):
                for director in row['director'].split(','):
                    if director not in director_map:
                        director_map.update({director:director_count})
                        director_list.append(director_count)
                        director_count = director_count + 1
                    else:
                        director_id = director_map[director]
                        director_list.append(director_id)

            if pd.notnull(row['actors']):
                for actor in row['actors'].split(','):
                    if actor not in actor_map:
                        actor_map.update({actor:actor_count})
                        actor_list.append(actor_count)
                        actor_count = actor_count + 1
                    else:
                        actor_id = actor_map[actor]
                        actor_list.append(actor_id)

            # Writing
            nt_str = ""

            movie_str = "<" + i2kg_map.get(int(movie_id), "http://ml1m-sun/movie"+movie_id)+ ">"
            for genre_id in genre_list:
                nt_str += movie_str + ' <http://ml1m-sun/genre> <http://ml1m-sun/genre' + str(genre_id) + '> .\n'
            for director_id in director_list:
                nt_str += movie_str + ' <http://ml1m-sun/director> <http://ml1m-sun/director' + str(director_id) + '> .\n'
            for actor_id in actor_list:
                nt_str += movie_str + ' <http://ml1m-sun/actor> <http://ml1m-sun/actor' + str(actor_id) + '> .\n'

            fout.write(nt_str)


def mapping(df_auxiliary, mapping_path, i2kg_map_file=''):
    '''
    mapping the auxiliary info (e.g., genre, director, actor) into ID

    Inputs:
        @df_auxiliary: the auxiliary infomation
        @fw_mapping: the auxiliary mapping information
        @i2kg_map_file (opt): the item to kg mapping information
    '''
    actor_map = {}
    director_map = {}
    genre_map = {}

    actor_count = director_count = genre_count = 0
    all_entity_set = set()
    input_entity_set = set()

    i2kg_map = {}
    if not i2kg_map_file == '':
        with open(i2kg_map_file) as fin:
            for line in fin:
                (id, name, uri) = line.split("\t")
                i2kg_map[int(id)] = uri.replace('\n', '')

    if len(df_auxiliary.columns) != 4:
        print(df_auxiliary.columns)

    kg_path = os.path.join(mapping_path, 'kg')
    input_entity_file = os.path.join(kg_path, "kg_hop0.dat")
    with open(input_entity_file, 'w') as fout:
        for index, row in df_auxiliary.iterrows():
            movie_id = str(row['movie_id'])
            genre_list = []
            director_list = []
            actor_list = []

            if pd.notnull(row['genre']):
                for genre in row['genre'].split(','):
                    if genre not in genre_map:
                        genre_map.update({genre:genre_count})
                        genre_list.append(genre_count)
                        genre_count = genre_count + 1
                    else:
                        genre_id = genre_map[genre]
                        genre_list.append(genre_id)

            if pd.notnull(row['director']):
                for director in row['director'].split(','):
                    if director not in director_map:
                        director_map.update({director:director_count})
                        director_list.append(director_count)
                        director_count = director_count + 1
                    else:
                        director_id = director_map[director]
                        director_list.append(director_id)

            if pd.notnull(row['actors']):
                for actor in row['actors'].split(','):
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
            output_line = i2kg_map.get(int(movie_id), "http://ml1m-sun/movie"+movie_id) + '\t' + head_json_str + '\t' + '[]' + '\n'
            fout.write(output_line)

            # Entities and predicates
            all_entity_set.add(i2kg_map.get(int(movie_id), "http://ml1m-sun/movie"+movie_id))
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

    input_entity_file = os.path.join(mapping_path, "i2kg_map.tsv")
    with open(input_entity_file, 'w') as fout:
        id=1
        for movie_id in input_entity_set:
            fout.write(str(movie_id) + '\t' + "name" + '\t' + i2kg_map.get(int(movie_id), "http://ml1m-sun/movie"+movie_id) + '\n')
            id+=1

    kg_map_file = os.path.join(mapping_path, "kg_map.dat")
    with open(kg_map_file, 'w') as fout:
        for key, value in genre_map.items():
            fout.write(key + '\t' + "http://ml1m-sun/genre" + str(value) + "\n")

        for key, value in director_map.items():
            fout.write(key + '\t' + "http://ml1m-sun/director" + str(value) + "\n")

        for key, value in actor_map.items():
            fout.write(key + '\t' + "http://ml1m-sun/actor" + str(value) + "\n")

    #print(genre_map)#

    return genre_count, director_count, actor_count


def mapping_from_nt(nt_file, mapping_path):
    '''
    mapping the auxiliary info (e.g., genre, director, actor) into ID

    Inputs:
        @nt_file: the auxiliary infomation ntriples format
        @fr_i2kg_map: the item to kg mapping infomation
        @fw_mapping: the auxiliary mapping information
    '''
    g = Graph()
    g.parse(nt_file, format='nt')
    subjs = [ row['s'] for row in g.query('SELECT DISTINCT ?s WHERE { ?s ?p ?o . }') ]
    preds = [ row['p'] for row in g.query('SELECT DISTINCT ?p WHERE { ?s ?p ?o . }') ]
    #print(len(subjs))
    #print(len(preds))

    kg_path = os.path.join(mapping_path, 'kg')
    caokg_file = os.path.join(kg_path, 'kg_hop0.dat')
    with open(caokg_file, 'w') as fout:
        mid_str = ""
        for subj in subjs:
            fout.write(str(subj))
            fout.write('\t[')
            for pred in preds:
                objs = [ o for s, p, o in g.triples((subj, pred, None)) ]
                #print(f'{subj} {pred} {len(objs)}')
                for obj in objs:
                    #print(f'{subj} {pred} {obj}')
                    fout.write(mid_str)
                    mid_str = f'{{ "p": {{ "type": "uri", "value": "{str(pred)}" }}, "o": {{ "type": "uri", "value": "{str(obj)}" }}}}, '
            fout.write(mid_str[:-2])
            fout.write( ']\t[]\n' )
            mid_str = ""

    predicate_file = os.path.join(kg_path, 'predicate_vocab.dat')
    with open(predicate_file, 'w') as fout:
        for pred in preds:
            fout.write(str(pred) + '\n')

    relations_file = os.path.join(kg_path, 'relation_filter.dat')
    with open(relations_file, 'w') as fout:
        for pred in preds:
            fout.write(str(pred) + '\n')

    subj_set = set()
    obj_set = set()
    for subj in subjs:
        subj_set.add(str(subj))
    for obj in g.objects():
        obj_set.add(str(obj))
        

    entity_file = os.path.join(kg_path, 'entity_vocab.dat')
    with open(entity_file, 'w') as fout:
        for ent in subj_set:
            fout.write(ent + '\n')
        for ent in obj_set:
            fout.write(ent + '\n')

    #input_entity_file = os.path.join(mapping_path, 'i2kg_map.tsv') # same from original KG

    kg_map_file = os.path.join(mapping_path, 'kg_map.dat')
    with open(entity_file, 'w') as fout:
        for ent in obj_set:
            if ent not in subj_set:
                fout.write('name\t' + ent + '\n')


    genre_count = [ row['count'].toPython() for row in g.query('SELECT (count (distinct ?o) as ?count) WHERE { ?s <http://ml1m-sun/genre> ?o . }') ][0]
    director_count = [ row['count'].toPython() for row in g.query('SELECT (count (distinct ?o) as ?count) WHERE { ?s <http://ml1m-sun/director> ?o . }') ][0]
    actor_count = [ row['count'].toPython() for row in g.query('SELECT (count (distinct ?o) as ?count) WHERE { ?s <http://ml1m-sun/actor> ?o . }') ][0]
    
    return genre_count, director_count, actor_count


def print_statistic_info(genre_count, director_count, actor_count):
    '''
    print the number of genre, director and actor
    '''

    print ('The number of genre is: ' + str(genre_count))
    print ('The number of director is: ' + str(director_count))
    print ('The number of actor is: ' + str(actor_count))


if __name__ == '__main__':

    #print(os.getcwd())
    parser = argparse.ArgumentParser(description=''' Map Auxiliary Information into ID''')

    parser.add_argument('--mode', type=str, dest='mode', default='auxiliary')
    parser.add_argument('--input', type=str, dest='input_file', default='../../datasets/ml1m-sun/ml1m/auxiliary.txt')
    parser.add_argument('--i2kg_map', type=str, dest='i2kg_map_file', default='')
    parser.add_argument('--mapping', type=str, dest='mapping_path', default='../../datasets/ml1m-sun2cao/ml1m/')

    parsed_args = parser.parse_args()

    mode = parsed_args.mode
    input_file = os.path.expanduser(parsed_args.input_file)
    i2kg_map_file = os.path.expanduser(parsed_args.i2kg_map_file)
    mapping_path = os.path.expanduser(parsed_args.mapping_path)

    genre_count = director_count = actor_count = -1
    if mode == 'auxiliary':
        df_auxiliary = load_ml1m_sun_data(input_file)
        df_auxiliary = cleanning(df_auxiliary)
        genre_count, director_count, actor_count = mapping(df_auxiliary, mapping_path, i2kg_map_file)
        df2nt(df_auxiliary, os.path.join(mapping_path,"..","..","kg-ig.nt") )
    elif mode == 'nt':
        genre_count, director_count, actor_count = mapping_from_nt(input_file, mapping_path)

    print_statistic_info(genre_count, director_count, actor_count)

