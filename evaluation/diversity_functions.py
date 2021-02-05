# coding=utf-8
""""
    These functions are responsible for evaluate diversity of recommendation algorithms.

    They are used by evaluation/diversity_evaluation.py

"""

# © 2021. Case Recommender (MIT License)

import numpy as np

__author__ = 'Juarez Sacenti <juarez[DOT]sacenti[AT]gmail[DOT]com>'


def genre_coverage_at_k(recommended_items, i2genre_map, k):
    """
    Genre coverage

    :param recommended_items: item id list in rank order (first element is the first item)
    :type ranking: list

    :param i2genre_map: Dictionary with item-genre map information. # To be filled as: {item_id: [genre_id_1, genre_id_2, ..., genre_id_N]} and also {'distinct_genres': [genre_id_1, genre_id_2, ..., genre_id_N]}
    :type i2genre_map: dict

    :param k: length of recommended list
    :type k: int

    :return: Genre coverage @ k
    :rtype: float

    """

    assert k >= 1
    if len(recommended_items) != k:
        raise ValueError('Recommended item list length < k')

    total_genres = len(i2genre_map.get('distinct_genres',[]))
    recommended_genres = set()
    for i in recommended_items:
        for g in i2genre_map.get(str(i),[]):
            recommended_genres.add(g)
    total_recommended_genres = len(recommended_genres)
    genre_coverage = total_recommended_genres / total_genres
    nl='\n'
    assert genre_coverage >= 0 and genre_coverage <= 1, f'{genre_coverage} = {total_recommended_genres} / {total_genres} {nl} {recommended_genres}'

    return genre_coverage


def genre_redundancy_at_k(recommended_items, i2genre_map, k):
    """
    Genre redundancy

    :param recommended_items: item id list in rank order (first element is the first item)
    :type ranking: list

    :param i2genre_map: Dictionary with item-genre map information. # To be filled as: {item_id: [genre_id_1, genre_id_2, ..., genre_id_N]} and also {'distinct_genres': [genre_id_1, genre_id_2, ..., genre_id_N]}
    :type i2genre_map: dict

    :param k: length of recommended list
    :type k: int

    :return: Genre coverage @ k
    :rtype: float

    """

    assert k >= 1
    if len(recommended_items) != k:
        raise ValueError('Recommended item list length < k')

    total_redundant_genres=0
    distinct_genres = set()
    for i in recommended_items:
        for g in i2genre_map.get(str(i),[]):
            distinct_genres.add(g)
            total_redundant_genres+=1
    total_distinct_genres = len(distinct_genres)
    genre_redundancy = total_distinct_genres / total_redundant_genres
    nl='\n'
    assert genre_redundancy >= 0 and genre_redundancy <= 1, f'{genre_redundancy} = {total_distinct_genres} / {total_redundant_genres} {nl} {distinct_genres}'

    return genre_redundancy


def jaccard_similarity_genre(genres_i, genres_j):
    """
    Intra-List Diversity
    Ref: http://ceur-ws.org/Vol-2225/paper2.pdf, https://link.springer.com/article/10.1007/s10115-019-01371-0?shared-article-renderer

    :param recommended_items: item id list in rank order (first element is the first item)
    :type ranking: list

    :param i2genre_map: Dictionary with item-genre map information. # To be filled as: {item_id: [genre_id_1, genre_id_2, ..., genre_id_N]} and also {'distinct_genres': [genre_id_1, genre_id_2, ..., genre_id_N]}
    :type i2genre_map: dict

    :param k: length of recommended list
    :type k: int

    :return: Genre coverage @ k
    :rtype: float

    """

    fst, snd = (genres_i, genres_j) if len(genres_i) < len(genres_j) else (genres_j, genres_i)
    genres_intersection = set(fst).intersection(snd)
    print(genres_i, genres_j)
    genres_union = genres_i.copy()
    genres_union.extend(genres_j)
    print(genres_union)
    genres_union = set(genres_union)
    return len(genres_intersection) / len(genres_union)


def intra_list_diversity_genre(recommended_items, i2genre_map, k):
    """
    Intra-List Diversity
    Ref: http://ceur-ws.org/Vol-2225/paper2.pdf, https://link.springer.com/article/10.1007/s10115-019-01371-0?shared-article-renderer

    :param recommended_items: item id list in rank order (first element is the first item)
    :type ranking: list

    :param i2genre_map: Dictionary with item-genre map information. # To be filled as: {item_id: [genre_id_1, genre_id_2, ..., genre_id_N]} and also {'distinct_genres': [genre_id_1, genre_id_2, ..., genre_id_N]}
    :type i2genre_map: dict

    :param k: length of recommended list
    :type k: int

    :return: Genre coverage @ k
    :rtype: float

    """

    assert k >= 1
    if len(recommended_items) != k:
        raise ValueError('Recommended item list length < k')

    sorted_predictions = sorted(recommended_items)
    sum = 0
    for i in sorted_predictions:
        for j in sorted_predictions:
            if i < j:
                genres_i = sorted(i2genre_map.get(str(i),[]))
                genres_j = sorted(i2genre_map.get(str(j),[]))
                sum += (1 - jaccard_similarity_genre(genres_i, genres_j))
            else:
                pass

    diversity = (sum * 2) / (k * (k - 1))
    return genre_redundancy
