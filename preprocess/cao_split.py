import argparse
import os
import numpy as np
import pandas as pd

def load_ml1m_cao_data(load_file):
    # file: rating-delete-missing-itemid

    # pass in column names for each CSV
    r_cols = ['user_id', 'movie_id', 'rating']
    rating = pd.read_csv(load_file, sep='\t', engine="python", names=r_cols, encoding='utf-8', header=None)

    return rating


def cao_split(df, column='user_id', frac=[0.1,0.2]):
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


def sun_format(df_remain, sets):
    sun_remain = df_remain.copy()
    sun_remain = sun_remain.drop(columns=['rating'])
    sun_sets = []
    for i in range(len(sets)):
        sun_sets.append(sets[i].copy())
        sun_sets[i] = sun_sets[i].drop(columns=['rating'])
    return sun_remain, sun_sets


if __name__ == '__main__':
    #print(os.getcwd())
    parser = argparse.ArgumentParser(description=''' Split Cao''')

    parser.add_argument('--loadpath', type=str, dest='load_path', default='~/git/datasets/ml-cao/cao-format/ml1m/')
    parser.add_argument('--column', type=str, dest='column', default='user_id')
    parser.add_argument('--frac', type=str, dest='frac', default='0.2,0.2,0.2,0.2')
    parser.add_argument('--savepath', type=str, dest='save_path', default='~/git/datasets/ml-cao_ho_oKG/cao-format/ml1m/')

    parsed_args = parser.parse_args()

    load_file = os.path.expanduser(parsed_args.load_file)
    column = parsed_args.column
    frac = np.fromstring(parsed_args.frac, dtype=float, sep=',')
    print(frac)
    save_path = os.path.expanduser(parsed_args.save_path)

    df_train = load_ml1m_cao_data(os.path.join(load_path, 'train.dat.old'))
    df_valid = load_ml1m_cao_data(os.path.join(load_path, 'valid.dat.old'))
    df_test = load_ml1m_cao_data(os.path.join(load_path, 'test.dat.old'))
    df = pd.concat([df_train,df_valid,df_test], ignore_index=True)

    cao_remain, cao_sets = cao_split(df, column, frac)

    #sun_remain, sun_sets = sun_format(df_remain, sets)

    if len(frac) < 3:
        cao_remain.to_csv(save_path+'train.dat', sep='\t', header=False, encoding='utf-8', index=False)
        cao_sets[0].to_csv(save_path+'valid.dat', sep='\t', header=False, encoding='utf-8', index=False)
        cao_sets[1].to_csv(save_path+'test.dat', sep='\t', header=False, encoding='utf-8', index=False)
    else:
        cao_remain.to_csv(save_path+'fold0.dat', sep='\t', header=False, encoding='utf-8', index=False)
        for i in range(len(cao_sets)):
            cao_sets[i].to_csv(save_path+'fold'+str(i+1)+'.dat', sep='\t', header=False, encoding='utf-8', index=False)
