#This is used to map the auxiliary information (genre, director and actor) into mapping ID for MovieLens

import argparse
import os
import numpy as np
import pandas as pd # pandas is a data manipulation library

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

def clean(auxiliary):
    i = auxiliary.index[auxiliary['movie_id'] == 1581]
    auxiliary.iloc[i] = [1581,'Mystery','Anthony Asquith', 'Jean Kent,Dirk Bogarde,John McCallum']
    auxiliary = auxiliary.replace({'Biograpy':'Biography'}, regex=True)
    auxiliary = auxiliary.replace('N/A,', np.NaN)
    auxiliary = auxiliary.replace('N/A', np.NaN)

    return auxiliary

def summarize(df_auxiliary, fr_summarize):
    '''
    Summarizing Auxiliary Genre Information by Hierarchy

    Inputs:
        @fr_auxiliary: the auxiliary infomation
        @fr_hierarchy: the genre hierarchy information
        @fw_summarized: the output file
    '''
    hierarchy = {}

    genres_not_found = set()

    for line in fr_summarize:
        (child, parent) = line.split(",")
        hierarchy[child] = parent.replace('\n', '')

    if len(df_auxiliary.columns) != 4:
        print(df_auxiliary.columns)

    for index, row in df_auxiliary.iterrows():
        if pd.notnull(row['genre']):
            new_genres = set()
            for genre in row['genre'].split(','):
                if genre not in hierarchy.keys():
                    genres_not_found.add(genre)
                    new_genres.add(genre)
                else:
                    new_genres.add(hierarchy[genre])
            str_new_genres = ','.join(str(g) for g in new_genres)
            df_auxiliary.iloc[index, df_auxiliary.columns.get_loc('genre')] = str_new_genres

        if len(genres_not_found) > 0:
            print('Not found genres in hierarchy: '+ str(genres_not_found))

    return df_auxiliary

def save_to_csv(df_auxiliary):
    df_auxiliary['movie_id'] = 'id:' + df_auxiliary['movie_id'].map(str)
    df_auxiliary['genre'] = 'genre:' + df_auxiliary['genre'].map(str)
    df_auxiliary['director'] = 'director:' + df_auxiliary['director'].map(str)
    df_auxiliary['actors'] = 'actors:'+ df_auxiliary['actors'].map(str)

    df_auxiliary.to_csv(output_file, sep='|', encoding='utf-8-sig', index=False, header=False)


if __name__ == '__main__':

    #print(os.getcwd())
    parser = argparse.ArgumentParser(description=''' Map Auxiliary Information into ID''')

    parser.add_argument('--auxiliary', type=str, dest='auxiliary_file', default='../../datasets/ml1m-sun/ml1m/auxiliary.txt')
    parser.add_argument('--summarize', type=str, dest='summarize_file', default=None)
    parser.add_argument('--output', type=str, dest='output_file', default='../../datasets/ml1m-summarized_sun/ml1m/sum_auxiliary.txt')

    parsed_args = parser.parse_args()

    auxiliary_file = parsed_args.auxiliary_file
    summarize_file = parsed_args.summarize_file
    output_file = parsed_args.output_file

    df_auxiliary = load_ml1m_sun_data(auxiliary_file)
    df_auxiliary = clean(df_auxiliary)

    if summarize_file is not None:
        fr_summarize = open(summarize_file, 'r', encoding="utf8")
        df_auxiliary = summarize(df_auxiliary, fr_summarize)
        fr_summarize.close()

    save_to_csv(df_auxiliary)
