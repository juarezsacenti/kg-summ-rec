# coding=utf-8
""""
    This class is responsible for evaluate diversity of recommendation algorithms (rankings).

    This file contains diversity-based evaluation metrics:
        - Genre coverage

    Types of evaluation:
        - Simple: Evaluation with traditional strategy
        - All-but-one Protocol: Considers only one pair (u, i) from the test set to evaluate the ranking

"""

# © 2021. Case Recommender (MIT License)

import numpy as np
import random

from caserec.evaluation.base_evaluation import BaseEvaluation
from diversity_functions import genre_coverage_at_k

from caserec.utils.process_data import ReadFile, WriteFile
from caserec.evaluation.item_recommendation import ItemRecommendationEvaluation


__author__ = 'Juarez Sacenti <juarez[DOT]sacenti[AT]gmail[DOT]com>'


class DiversityEvaluation(BaseEvaluation):
    def __init__(self, sep='\t', n_ranks=list([1, 3, 5, 10]),
                 metrics=list(['GENRE_COVERAGE']), all_but_one_eval=False,
                 verbose=True, as_table=False, table_sep='\t'):
        """
        Class to evaluate predictions in a item recommendation (ranking) scenario

        :param sep: Delimiter for input files
        :type sep: str, default '\t'

        :param n_ranks: List of positions to evaluate the ranking
        :type n_ranks: list, default [1, 3, 5, 10]

        :param metrics: List of evaluation metrics
        :type metrics: list, default ('GENRE_CONVERAGE')

        :param all_but_one_eval: If True, considers only one pair (u, i) from the test set to evaluate the ranking
        :type all_but_one_eval: bool, default False

        :param verbose: Print the evaluation results
        :type verbose: bool, default True

        :param as_table: Print the evaluation results as table (only work with verbose=True)
        :type as_table: bool, default False

        :param table_sep: Delimiter for print results (only work with verbose=True and as_table=True)
        :type table_sep: str, default '\t'

        """

        if type(metrics) == list:
            metrics = [m + '@' + str(n) for m in metrics for n in n_ranks]
        super(ItemRecommendationEvaluation, self).__init__(sep=sep, metrics=metrics, all_but_one_eval=all_but_one_eval,
                                                           verbose=verbose, as_table=as_table, table_sep=table_sep)

        self.n_ranks = n_ranks

    def evaluate(self, predictions, test_set, i2genre_map):
        """
        Method to calculate all the metrics for item recommendation scenario using dictionaries of ranking
        and test set. Use read() in ReadFile to transform your file in a dict

        :param predictions: Dictionary with ranking information. # To be filled as: {user_id: [item_id_1, item_id_2, ..., item_id_N]}
        :type predictions: dict

        :param test_set: Dictionary with test set information.
        :type test_set: dict

        :param i2genre_map: Dictionary with item-genre map information. # To be filled as: {item_id: [genre_id_1, genre_id_2, ..., genre_id_N]} and also {'distinct_genres': [genre_id_1, genre_id_2, ..., genre_id_N]}
        :type i2genre_map: dict

        :return: Dictionary with all evaluation metrics and results
        :rtype: dict

        """

        eval_results = {}
        num_user = len(test_set['users'])
        partial_map_all = None

        if self.all_but_one_eval:
            for user in test_set['users']:
                # select a random item
                test_set['items_seen_by_user'][user] = [random.choice(test_set['items_seen_by_user'].get(user, [-1]))]

        for i, n in enumerate(self.n_ranks):
            if n < 1:
                raise ValueError('Error: N must >= 1.')

            partial_genre_coverage = list()
            partial_genre_redundancy = list()

            for user in test_set['users']:
                hit_cont = 0
                # Generate user intersection list between the recommended items and test.
                #list_feedback = set(list(predictions.get(user, []))[:n])
                #intersection = list(list_feedback.intersection(test_set['items_seen_by_user'].get(user, [])))

                #if len(intersection) > 0:
                #    ig_ranking = np.zeros(n)
                #    for item in intersection:
                #        hit_cont += 1
                #        ig_ranking[list(predictions[user]).index(item)] = 1

                partial_genre_coverage.append(genre_coverage_at_k(list(predictions.get(user, []))[:n], i2genre_map, n))
                partial_genre_redundancy.append(genre_redundancy_at_k(list(predictions.get(user, []))[:n], i2genre_map, n))

            # create a dictionary with final results
            eval_results.update({
                'GENRE_COVERAGE@' + str(n): round(sum(partial_genre_coverage) / float(num_user), 6),
                'GENRE_REDUNDANCY@' + str(n): round(sum(partial_genre_redundancy) / float(num_user), 6)
            })

        # if (self.save_eval_file is not None):
        #     # Saving evaluations to a file
        #     from caserec.utils.process_data import WriteFile

        #     WriteFile(output_file=save_eval_file, data=)

        if self.verbose:
            self.print_results(eval_results)

        return eval_results


def evaluate_predictions(input_file, dataset_path, ratio, output_file):
    predictions_data = ReadFile(input_file=input_file).read()
    i2genre_map = read_i2genre_map(dataset_path, ratio)
    # Creating kg-summ-rec evaluator with diversity parameters
    evaluator = DiversityEvaluation(n_ranks=[10])
    # Getting evaluation
    diversity_metrics = evaluator.evaluate(predictions_data['feedback'], eval_data, i2genre_map)
    with open(output_file) as fout:
        fout.write("From kg-summ-rec diversity evaluator: {}.".format(str(diversity_metrics)))


def evaluate_predictions2(prediction_file, dataset_path, ratio, test_file, output_file):
    predictions_data = ReadFile(input_file=prediction_file).read()
    eval_data = ReadFile(input_file=test_file).read()
    # Creating CaseRecommender evaluator with item-recommendation parameters
    evaluator = ItemRecommendationEvaluation(n_ranks=[10])
    # Getting evaluation
    item_rec_metrics = evaluator.evaluate(predictions_data['feedback'], eval_data)
    i2genre_map = read_i2genre_map(dataset_path, ratio)
    # Creating kg-summ-rec evaluator with diversity parameters
    evaluator = DiversityEvaluation(n_ranks=[10])
    # Getting evaluation
    diversity_metrics = evaluator.evaluate(predictions_data['feedback'], eval_data, i2genre_map)
    with open(output_file) as fout:
        fout.write("From kg-summ-rec diversity evaluator: {}.".format(str(item_rec_metrics)))
        fout.write("From kg-summ-rec diversity evaluator: {}.".format(str(diversity_metrics)))


def read_i2genre_map(dataset_path, ratio):
    i2genre_map = {}

    i2kg_map = {}
    i2kg_map_file = os.path.join(dataset_path, 'cao-format','ml1m','i2kg_map.tsv')
    with open(i2kg_map_file) as fin:
        for line in fin:
            (item_id, name, item_uri) = line.rstrip('\n').split('\t')
            i2kg_map.get(item_id, []).append(f'<{item_uri}>')

    kg = {}
    genre_set = ()
    kg_file = os.path.join(dataset_path, 'kg-ig.nt')
    with open(kg_file) as fin:
        for line in fin:
            (s, p, o, dot) = line.rstrip('\n').split(' ')
            if 'movie' in s && 'genre' in p:
                kg.get(s, []).append(o)
                genre_set.add(o)

    cluster = {}
    if ratio != '100':
        cluster_file = os.path.join(dataset_path, f'cluster{ratio}.tsv')
        with open(cluster_file) as fin:
            for line in fin:
                (entity_uri, cluster_uri) = line.rstrip('\n').split('\t')
                cluster.get(f'<{cluster_uri}>', []).append(entity_uri)

    e_map = {}
    e_map_file = os.path.join(dataset_path,'cao-format','ml1m','kg','e_map.dat')
    with open(e_map_file) as fin:
        for line in fin:
            (entity_id, entity_uri) = line.rstrip('\n').split('\t')
            e_map.get(f'<{entity_uri}>', []).append(entity_id)

    for item_id, item_uri_list in i2kg_map.items():
        for item_uri in item_uri_list:
            if ratio != '100':
                cluster_uri_list = kg.get(item_uri, [])
                for cluster_uri in cluster_uri_list:
                    genre_uri_list = cluster.get(cluster_uri,[])
                    for genre_uri in genre_uri_list:
                        genre_id_list = e_map.get(genre_uri, [])
                        for genre_id in genre_id_list:
                            i2genre_map.get(item_id,[]).append(genre_id)
            else:
                genre_uri_list = kg.get(item_uri, [])
                for genre_uri in genre_uri_list:
                    genre_id_list = e_map.get(genre_uri, [])
                    for genre_id in genre_id_list:
                        i2genre_map.get(item_id,[]).append(genre_id)

    i2genre_map['distinct_genres'] = list(genre_set)

    return i2genre_map


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='''Evaluate diversity of predictions.''')

    parser.add_argument('--input', type=str, dest='input_file', default='../../results/Sacenti-JOURNAL2021/ml-sun_ho_oKG/ml1m-jtransup-1611183692_pred.dat')
    parser.add_argument('--datapath', type=str, dest='datapath', default='../../datasets/Sacenti-JOURNAL2021/ml-sun_ho_oKG/')
    parser.add_argument('--ratio', type=str, dest='ratio', default='100')
    parser.add_argument('--test', type=str, dest='test', default='../../datasets/Sacenti-JOURNAL2021/ml-sun_ho_oKG/')
    parser.add_argument('--output', type=str, dest='output_file', default='../../results/Sacenti-JOURNAL2021/ml-sun_ho_oKG/rec_quality.log')

    parsed_args = parser.parse_args()

    input_file = os.path.expanduser(parsed_args.input_file)
    datapath = os.path.expanduser(parsed_args.datapath)
    ratio = parsed_args.ratio
    test_file = os.path.expanduser(parsed_args.test)
    output_file = os.path.expanduser(parsed_args.output_file)

    evaluate_predictions(input_file, dataset_path, ratio, output_file)
