import argparse
import os
from rdflib import Graph
import pandas as pd
import numpy as np
import json


def extend_ml_sun_with_mo(nt_file, dataset_path, output_file):
    nl='\n'
    # copy nt_file to output_file
    with open(nt_file) as fin, open(output_file, 'w') as fout:
        for line in fin:
            fout.write(line)
    # copy mo-genre-t-box.nt to output_file
    mo_genre_t_box = os.path.expanduser('~/git/kg-summ-rec/util/mo/mo-genre-t-box.nt')
    with open(mo_genre_t_box) as fin, open(output_file, 'a+') as fout:
        for line in fin:
            fout.write(line)
    kg_map = {}
    with open(f'{dataset_path}kg_map.dat') as fin, open(output_file, 'a+') as fout:
        for line in fin:
            (entity_name, entity_uri) = line.rstrip('\n').split('\t')
            kg_map[entity_name] = entity_uri
            # add actor is a Actor
            if '<http://ml1m-sun/actor' in entity_uri:
                fout.write(f'{entity_uri} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/ontology/Actor> .{nl}')
            # add director is a Director
            if '<http://ml1m-sun/director' in entity_uri:
                fout.write(f'{entity_uri} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/page/Film_Director> {nl}')
    # copy mo-genre-a-box.nt to output_file
    mo_genre_a_box = os.path.expanduser('~/git/kg-summ-rec/util/mo/mo-genre-a-box.tsv')
    with open(mo_genre_a_box) as fin, open(output_file, 'a+') as fout:
        for line in fin:
            (instance, concept) = line.rstrip('\n').split('\t')
            if instance in kg_map:
                fout.write(f'<{kg_map.get(instance, instance)}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> {concept} .{nl}')


def ig2uig(nt_file, dataset_path, output_file):
    nl = '\n'
    # copy nt_file to output_file
    with open(nt_file) as fin, open(output_file, 'w') as fout:
        for line in fin:
            fout.write(line)
    i_map = {}
    with open(f'{dataset_path}i_map.dat') as fin:
        for line in fin:
            (item_id, original_item_id) = line.rstrip('\n').split('\t')
            i_map[item_id] = original_item_id
    i2kg_map = {}
    with open(f'{dataset_path}i2kg_map.tsv') as fin:
        for line in fin:
            (id, name, entity) = line.rstrip('\n').split('\t')
            i2kg_map[id] = entity
    # add triples about user-item ratings to output_file
    with open(f'{dataset_path}train.dat') as fin, open(output_file, 'a+') as fout:
        for line in fin:
            (u, i, r) = line.rstrip('\n').split('\t')
            fout.write(f'<http://ml1m-sun/user{u}> <http://ml1m-sun/rates> <{i2kg_map[i_map[i]]}> .{nl}')


#nt to edges (gemsec format)
def nt2edges(nt_file, output_file, edge_map_file):
    #create entity-edge map mapping
    edge_map = {}
    edge_id = 0
    nl='\n'
    sep = ','
    #find'n'replace entities with ids
    with open(nt_file) as fin, open(output_file, 'w') as fout:
        #for each triple, replace entity in triple with entity id
        for line in fin:
            (s, p, o, dot) = line.split(' ')
            #write in csv edge format
            key = s[1:-1]
            if key in edge_map:
                sid = edge_map[key]
            else:
                sid = edge_map[key] = edge_id
                edge_id+=1
            key = o[1:-1]
            if key in edge_map:
                oid = edge_map[key]
            else:
                oid = edge_map[key] = edge_id
                edge_id+=1
            fout.write(f'{sid}{sep}{oid}{nl}')
    with open(edge_map_file, 'w') as fout:
        #save edge_map
        for k, v in edge_map.items():
            fout.write(f'{k}{sep}{v}{nl}')


#assignment (gemsec format) to cluster
def assignment2cluster(assignment_file, edge_map_file, output_file):
    #open id-entity mapping
    edge_map = {}
    nl = '\n'
    sep = '\t'
    with open(edge_map_file) as fin:
        for line in fin:
            (entity, id) = line.rstrip('\n').split(',')
            edge_map[id] = entity
    #open entity-cluster id mapping
    with open(assignment_file) as json_file:
        c_map = json.load(json_file)
    #find'n'replace entities with clusters
    with open(output_file, 'w') as fout:
        #for each cluster, each triple, each entity in cluster, replace entity in triple with cluster
        for k, v in c_map.items():
            if 'movie' not in edge_map[k]:
                fout.write(f'<{edge_map[k]}>{sep}cluster{v}{nl}')


def remove_duplicates(input_file, output_file):
    #remove duplicate triples
    with open(input_file) as fin, open(output_file, 'w') as fout:
        lines_seen = set() # holds lines already seen
        for line in fin:
            if line not in lines_seen: # not a duplicate
                fout.write(line)
                lines_seen.add(line)


def mv_cluster2nt(cluster_file, input_file, output_file):
    #open entity-cluster mapping
    c_map = {}
    r_map = {}
    with open(cluster_file) as fin:
        #for each cluster, each triple, each entity in cluster, replace entity in triple with cluster
        n_relation = 0
        for line in fin:
            (relation, entity, cluster) = line.rstrip('\n').split('\t')
            if relation not in c_map:
                c_map[relation] = {}
                r_map[relation] = n_relation
                n_relation += 1
            c_map[relation][entity] = f'<http://know-rec/relation{r_map[relation]}-'+cluster+'>'
    #find'n'replace entities with clusters
    with open(input_file) as fin, open('temp.dat', 'w') as fout:
        #for each cluster, each triple, each entity in cluster, replace entity in triple with cluster
        for line in fin:
            (s, p, o, dot) = line.split(' ')
            #read replace the string and write to output file
            if p in c_map:
                new_line = line.replace(s, c_map[p].get(s, s))
                new_line = new_line.replace(o, c_map[p].get(o, o))
                fout.write(new_line)
            else:
                fout.write(line)
    remove_duplicates('temp.dat', output_file)
    #remove temporary file
    os.remove('temp.dat')


def cluster2nt(cluster_file, input_file, output_file):
    #open entity-cluster mapping
    c_map = {}
    with open(cluster_file) as fin:
        #for each cluster, each triple, each entity in cluster, replace entity in triple with cluster
        for line in fin:
            (entity, cluster) = line.rstrip('\n').split('\t')
            c_map[entity] = '<http://know-rec/' + cluster + '>'
    #find'n'replace entities with clusters
    with open(input_file) as fin, open('temp.dat', 'w') as fout:
        #for each cluster, each triple, each entity in cluster, replace entity in triple with cluster
        for line in fin:
            (s, p, o, dot) = line.split(' ')
            #read replace the string and write to output file
            new_line = line.replace(s, c_map.get(s, s))
            new_line = new_line.replace(o, c_map.get(o, o))
            fout.write(new_line)
    remove_duplicates('temp.dat', output_file)
    #remove temporary file
    os.remove('temp.dat')


# does not work with cao kg_hop0.dat
def rdf2nt(input_file, output_file):
    g = Graph()
    g.parse(input_file)
    g.serialize(destination=output_file, format='nt')


# does not work with cao kg_hop0.dat
def splitkg2nt(file, fr_e_map, fr_r_map, save_file):
    e_map = {}
    with open(fr_e_map, 'r') as fin:
        for line in fin:
            (e_id, uri) = line.rstrip('\n').split('\t')
            e_map[e_id] = uri

    r_map = {}
    with open(fr_r_map, 'r') as fin:
        for line in fin:
            (e_id, uri) = line.rstrip('\n').split('\t')
            r_map[e_id] = uri

    with open(file, 'r') as fin:
        with open(save_file, 'a+') as fout:
            for line in fin:
                (s, o, r) = line.rstrip('\n').split('\t')
                fout.write('<{}> <{}> <{}> .\n'.format(e_map.get(s, s),
                                                r_map.get(r, r),
                                                e_map.get(o, o)))


def statistics(kg_path, input_file, output_file, KG_format='nt'):
    input_items_file = os.path.join(kg_path, 'cao-format', 'ml1m', 'i2kg_map.tsv')

    g = Graph()
    g.parse(input_file, format=KG_format)

    items = [f'{x}' for x in pd.read_csv(input_items_file, sep='\t', names=["id", "name", "url"]).url.unique().tolist()]
    items = np.unique(items)
    #print(items[0:10])
    n_items = len(items)
    nodes = [ row['node'].toPython() for row in g.query('SELECT DISTINCT ?node WHERE { {?node ?p1 ?o1. } UNION {?s2 ?p2 ?node. FILTER(!IsLiteral(?node)).} }') ]
    nodes = np.unique(nodes)
    n_nodes = len(nodes)
    n_nodes2 = len(set(nodes))
    #print(nodes[0:10])
    n_entities = len( np.setdiff1d( np.array(nodes), np.array(items) ) )
    n_entities2 = len ( [node for node in nodes if node not in items] )
    n_relations = [ row['count'].toPython() for row in g.query('SELECT (count (distinct ?p) as ?count) WHERE { ?s ?p ?o . }') ][0]
    n_triples = len(g)
    n_loops = [ row['count'].toPython() for row in g.query('SELECT (count (*) as ?count) WHERE { ?e ?p ?e . }') ][0]
    density_rate = n_triples / (n_entities * n_relations *n_entities)
    sparsity_rate = 1 - density_rate

    nl = '\n'
    sep = '\t'
    ignore_list = items
    with open(output_file, 'w') as fout:
        fout.write(
            f'#Items{sep}{n_items}{nl}'
            f'#Nodes{sep}{n_nodes}{nl}'
            f'#Nodes2{sep}{n_nodes2}{nl}'
            f'#Entities{sep}{n_entities}{nl}'
            f'#Entities2{sep}{n_entities2}{nl}'
            f'#Relations{sep}{n_relations}{nl}'
            f'#Triples{sep}{n_triples}{nl}'
            f'Sparsity rate{sep}{sparsity_rate*100}{nl}'
            f'#Loops{sep}{n_loops}{nl}'
        )
        for row_t in g.query('SELECT ?p (COUNT (*) AS ?count) WHERE { ?s ?p ?o . } GROUP BY ?p ORDER BY ?p'):
            fout.write(
                f"#Triples<{row_t['p'].toPython()}>{sep}{row['count'].toPython()}{nl}"
            )
            count_head=0
            count_head_entities=0
            for row_s in g.query('SELECT DISTINCT ?s WHERE { ?s <'+row_t['p'].toPython()+'> ?o . }'):
                count_head+=1
                if row_s[0] not in ignore_list:
                    count_head_entities+=1
            fout.write(
                f"#Head<{row_t['p'].toPython()}>{sep}{count_head}{nl}"
                f"#Head-Entities<{row_t['p'].toPython()}>{sep}{count_head_entities}{nl}"
            )
            count_tail=0
            count_tail_entities=0
            for row_o in g.query('SELECT DISTINCT ?o WHERE { ?s <'+row_t['p'].toPython()+'> ?o . }'):
                count_tail+=1
                if row_o[0] not in ignore_list:
                    count_tail_entities+=1
            fout.write(
                f"#Head<{row_t['p'].toPython()}>{sep}{count_tail}{nl}"
                f"#Head-Entities<{row_t['p'].toPython()}>{sep}{count_tail_entities}{nl}"
            )


def infrequent_entities(input_file, output_file, input_format="nt"):
    g = Graph()
    g.parse(input_file, format=input_format)
    #entity_frequency = g.query('SELECT ?o (COUNT(?o) AS ?count) WHERE { ?s ?p ?o . } GROUP BY ?o ORDER BY DESC(?count)')
    entity_frequency = g.query('SELECT ?count (COUNT(?count) AS ?count2) WHERE { select ?o (COUNT(?o) as ?count) where {?s ?p ?o . } GROUP BY ?o } GROUP BY ?count ORDER BY ?count')
    nl = '\n'
    with open(output_file, 'w') as fout:
        for row in entity_frequency:
            #print(f"{row[0].toPython()} {row[1].toPython()}")
            fout.write(f"{row[0].toPython()} {row[1].toPython()}{nl}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='''Convert kg to turtle format''')

    parser.add_argument('--mode', type=str, dest='mode', default='splitkg')
    parser.add_argument('--kgpath', type=str, dest='kg_path', default='../../datasets/ml1m-sun2cao/ml1m/kg/')
    parser.add_argument('--input', type=str, dest='input_file', default='../docker/ampligraph-data/kg-ig.nt')
    parser.add_argument('--input2', type=str, dest='input_file_2', default='../docker/ampligraph-data/cluster25.csv')
    parser.add_argument('--output', type=str, dest='output_file', default='../docker/ampligraph-data/kg_cluster25.nt')
    parser.add_argument('--output2', type=str, dest='output_file_2', default='../docker/gemsec-data/temp/edge_map.csv')

    parsed_args = parser.parse_args()

    mode = parsed_args.mode
    kg_path = os.path.expanduser(parsed_args.kg_path)
    input_file = os.path.expanduser(parsed_args.input_file)
    input_file_2 = os.path.expanduser(parsed_args.input_file_2)
    output_file = os.path.expanduser(parsed_args.output_file)
    output_file_2 = os.path.expanduser(parsed_args.output_file_2)

    if mode == 'splitkg':
        train_file = os.path.join(kg_path, 'train.dat')
        valid_file = os.path.join(kg_path, 'valid.dat')
        test_file = os.path.join(kg_path, 'test.dat')
        fr_e_map = os.path.join(kg_path, 'e_map.dat')
        fr_r_map = os.path.join(kg_path, 'r_map.dat')

        splitkg2nt(train_file, fr_e_map, fr_r_map, output_file)
        splitkg2nt(valid_file, fr_e_map, fr_r_map, output_file)
        splitkg2nt(test_file, fr_e_map, fr_r_map, output_file)
    elif mode == 'rdf':
        rdf2nt(input_file, output_file)
    elif mode == 'cluster':
        cluster2nt(input_file_2, input_file, output_file)
    elif mode == 'mv_cluster':
        mv_cluster2nt(input_file_2, input_file, output_file)
    elif mode == 'statistics':
        statistics(kg_path, input_file, output_file)
    elif mode == 'infrequent':
        infrequent_entities(input_file, output_file)
    elif mode == 'duplicates':
        remove_duplicates(input_file, output_file)
    elif mode == 'nt2edges':
        nt2edges(input_file, output_file, output_file_2)
    elif mode == 'assignment2cluster':
        assignment2cluster(input_file, input_file_2, output_file)
    elif mode == 'ig2uig':
        ig2uig(input_file, input_file_2, output_file)
    elif mode == 'sun_mo':
        extend_ml_sun_with_mo(input_file, input_file_2, output_file)
