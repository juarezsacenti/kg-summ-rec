# Build knowledge graph and mine the connected paths between users and movies in the training data of MovieLens

import argparse
import networkx as nx
import random


def load_data(file):
    '''
    load training (positive) or negative user-movie interaction data
    Input:
        @file: training (positive) data or negative data
    Output:
        @data: pairs containing positive or negative interaction data
    '''
    data = []

    for line in file:
        lines = line.split('\t')
        user = lines[0]
        movie = lines[1].replace('\n','')
        data.append((user, movie))

    return data


def add_user_movie_interaction_into_graph(positive_rating):
    '''
    add user-movie interaction data into the graph
    Input:
        @pos_rating: user-movie interaction data
    Output:
        @Graph: the built graph with user-movie interaction info
    '''
    Graph = nx.DiGraph()

    for pair in positive_rating:
        user = pair[0]
        movie = pair[1]
        user_node = 'u' + user
        movie_node = 'i' + movie
        Graph.add_node(user_node)
        Graph.add_node(movie_node)
        Graph.add_edge(user_node, movie_node)

    return Graph


def add_auxiliary_into_graph(fr_auxiliary, Graph):
    '''
    add auxiliary information (e.g., actor, director, genre) into graph
    Input:
        @fr_auxiliary: auxiliary mapping information about movies
        @Graph: the graph with user-movie interaction info
    Output:
        @Graph: the graph with user-moive interaction and auxiliary info
    '''

    pred_cnt = 0
    for line in fr_auxiliary:
        lines = line.replace('\n', '').split('|')

        movie_id = lines.pop(0)
        for pred in lines:
            pred_list = pred.split(',')

            #add movie nodes into Graph, in case the movie is not included in the training data
            movie_node = 'i' + movie_id
            if not Graph.has_node(movie_node):
                Graph.add_node(movie_node)

            #add the pred nodes into the graph
            for pred_id in pred_list:
                pred_node = 'p' + str(pred_cnt) + '_' + pred_id
                if not Graph.has_node(pred_node):
                    Graph.add_node(pred_node)
                Graph.add_edge(movie_node, pred_node)
                Graph.add_edge(pred_node, movie_node)

            pred_cnt += 1

    return Graph


def print_graph_statistic(Graph):
    '''
    output the statistic info of the graph
    Input:
        @Graph: the built graph
    '''
    print('The knowledge graph has been built completely \n')
    print('The number of nodes is:  ' + str(len(Graph.nodes()))+ ' \n')
    print('The number of edges is  ' + str(len(Graph.edges()))+ ' \n')


def mine_paths_between_nodes(Graph, user_node, movie_node, maxLen, sample_size, fw_file):
    '''
    mine qualified paths between user and movie nodes, and get sampled paths between nodes
    Inputs:
        @user_node: user node
        @movie_node: movie node
        @maxLen: path length
        @fw_file: the output file for the mined paths
    '''

    connected_path = []
    for path in nx.all_simple_paths(Graph, source=user_node, target=movie_node, cutoff=maxLen):
        if len(path) == maxLen + 1:
            connected_path.append(path)

    path_size = len(connected_path)

    #as there is a huge number of paths connected user-movie nodes, we get randomly sampled paths
    #random sample can better balance the data distribution and model complexity
    if path_size > sample_size:
        random.shuffle(connected_path)
        connected_path = connected_path[:sample_size]

    for path in connected_path:
        line = ",".join(path) + '\n'
        fw_file.write(line)

    #print('The number of paths between '+ user_node + ' and ' + movie_node + ' is: ' +  str(len(connected_path)) +'\n')


def dump_paths(Graph, rating_pair, maxLen, sample_size, fw_file):
    '''
    dump the postive or negative paths
    Inputs:
        @Graph: the well-built knowledge graph
        @rating_pair: positive_rating or negative_rating
        @maxLen: path length
        @sample_size: size of sampled paths between user-movie nodes
    '''
    for pair in rating_pair:
        user_id = pair[0]
        movie_id = pair[1]
        user_node = 'u' + user_id
        movie_node = 'i' + movie_id

        if Graph.has_node(user_node) and Graph.has_node(movie_node):
            mine_paths_between_nodes(Graph, user_node, movie_node, maxLen, sample_size, fw_file)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description=''' Build Knowledge Graph and Mine the Connected Paths''')

    parser.add_argument('--training', type=str, dest='training_file', default='../../datasets/ml1m-cao2sun/training.txt')
    parser.add_argument('--negtive', type=str, dest='negative_file', default='../../datasets/ml1m-cao2sun/negative.txt')
    parser.add_argument('--auxiliary', type=str, dest='auxiliary_file', default='../../datasets/ml1m-cao2sun/auxiliary-mapping.txt')
    parser.add_argument('--positivepath', type=str, dest='positive_path', default='../../datasets/ml1m-cao2sun/positive-path.txt', \
                        help='paths between user-item interaction pairs')
    parser.add_argument('--negativepath', type=str, dest='negative_path', default='../../datasets/ml1m-cao2sun/negative-path.txt', \
                        help='paths between negative sampled user-item pair')
    parser.add_argument('--pathlength', type=int, dest='path_length', default=3, help='length of paths with choices [3,5,7]')
    parser.add_argument('--samplesize', type=int, dest='sample_size', default=5, \
                        help='the sampled size of paths between nodes with choices [5, 10, 20, ...]')

    parsed_args = parser.parse_args()

    training_file = parsed_args.training_file
    negative_file = parsed_args.negative_file
    auxiliary_file = parsed_args.auxiliary_file
    positive_path = parsed_args.positive_path
    negative_path = parsed_args.negative_path
    path_length = parsed_args.path_length
    sample_size = parsed_args.sample_size

    print(os.getcwd())

    fr_training = open(training_file,'r')
    fr_negative = open(negative_file, 'r')
    fr_auxiliary = open(auxiliary_file,'r')
    fw_positive_path = open(positive_path, 'w')
    fw_negative_path = open(negative_path, 'w')

    positive_rating = load_data(fr_training)
    negative_rating = load_data(fr_negative)

    print('The number of user-movie interaction data is:  ' + str(len(positive_rating))+ ' \n')
    print('The number of negative sampled data is:  ' + str(len(negative_rating))+ ' \n')

    Graph = add_user_movie_interaction_into_graph(positive_rating)
    Graph = add_auxiliary_into_graph(fr_auxiliary, Graph)
    print_graph_statistic(Graph)

    dump_paths(Graph, positive_rating, path_length, sample_size, fw_positive_path)
    dump_paths(Graph, negative_rating, path_length, sample_size, fw_negative_path)

    fr_training.close()
    fr_negative.close()
    fr_auxiliary.close()
    fw_positive_path.close()
    fw_negative_path.close()
