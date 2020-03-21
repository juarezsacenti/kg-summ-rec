import argparse
import os
import numpy as np
import pandas as pd

def load_ml1m_sun_data(load_file):
    # file: rating-delete-missing-itemid

    # pass in column names for each CSV
    r_cols = ['user_id', 'movie_id', 'rating', 'timestamp']
    rating = pd.read_csv(load_file, sep='\t', engine="python", names=r_cols, encoding='utf-8', header=None)

    return rating

def id_map(df, u_map_file, i_map_file):
    array = df['user_id'].unique()
    array.sort()
    zipObj = zip(array, range(0, len(array)))
    u_map = dict(zipObj)

    array = df['movie_id'].unique()
    array.sort()
    zipObj = zip(array, range(0, len(array)))
    i_map = dict(zipObj)

    df['user_id'] = df['user_id'].replace(u_map)
    df['movie_id'] = df['movie_id'].replace(i_map)

    with open(u_map_file, 'w') as fout:
        for k,v in u_map.items():
            fout.write(str(v)+'\t'+str(v)+'\n')

    with open(i_map_file, 'w') as fout:
        for k,v in i_map.items():
            fout.write(str(v)+'\t'+str(v)+'\n')

    return df


def sun2cao_split(df, column='user_id', frac=[0.1,0.2]):
    df_remain = df.copy()
    size = len(df_remain)
    g_size = len(df_remain[column].unique())
    num_sets = len(frac)

    # init sets (train, valid, test, folds...)
    sets = []
    for i in range(num_sets):
        sets.append(pd.DataFrame())

    # select at least 1 item for each user
    all_groups = df_remain[column].unique()
    for g in all_groups:
        g_df = df_remain[df_remain[column] == g]
        samples = g_df.sample(n=len(frac))
        for i in range(num_sets):
            idx = samples.index[i]
            sample = samples[i:i+1]
            sets[i] = pd.concat([sets[i], sample], ignore_index=False)

    # drop selected rows
    for i in range(num_sets):
        df_remain = df_remain.drop(sets[i].index)

    # sample remain by frac
    for i in range(num_sets):
        n = (np.ceil((frac[i]*size) - g_size)).astype(int)
        samples = df_remain.sample(n)
        sets[i] = pd.concat([sets[i], samples], ignore_index=False)
        df_remain = df_remain.drop(samples.index)

    return df_remain, sets


if __name__ == '__main__':

    #print(os.getcwd())
    parser = argparse.ArgumentParser(description=''' Map Auxiliary Information into ID''')

    parser.add_argument('--loadfile', type=str, dest='load_file', default='../../datasets/ml1m-sun/ml1m/rating-delete-missing-itemid.txt')
    parser.add_argument('--column', type=str, dest='column', default='user_id')
    parser.add_argument('--umapfile', type=str, dest='u_map_file', default='../../datasets/ml1m-sun2cao/ml1m/u_map.dat')
    parser.add_argument('--imapfile', type=str, dest='i_map_file', default='../../datasets/ml1m-sun2cao/ml1m/i_map.dat')
    parser.add_argument('--savepath', type=str, dest='save_path', default='../../datasets/ml1m-sun2cao/ml1m/')
    #parser.add_argument('--frac', type=str, dest='frac', default='[0.1, 0.2]')

    parsed_args = parser.parse_args()

    load_file = parsed_args.load_file
    column = parsed_args.column
    u_map_file = parsed_args.u_map_file
    i_map_file = parsed_args.i_map_file
    save_path = parsed_args.save_path
    #frac = parsed_args.frac

    df = load_ml1m_sun_data(load_file)
    df = id_map(df, u_map_file, i_map_file)
    train, sets = sun2cao_split(df, column)

    valid = sets[0]
    test = sets[1]

    print('train: '+str(len(train)/len(df)) + '\nvalid: ' + str(len(valid)/len(df)) + '\ntest: ' + str(len(test)/len(df)) )

    train = train.drop(columns=['timestamp'])
    valid = valid.drop(columns=['timestamp'])
    test = test.drop(columns=['timestamp'])

    train.to_csv(save_path+'train.dat', sep='\t', header=False, encoding='utf-8', index=False)
    valid.to_csv(save_path+'valid.dat', sep='\t', header=False, encoding='utf-8', index=False)
    test.to_csv(save_path+'test.dat', sep='\t', header=False, encoding='utf-8', index=False)