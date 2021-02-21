import argparse
import os
import random


def random_selection(ammount):
    runs = []
    while len(runs) < ammount:
        t = tuple(range(ammount))
        # (0, 1, 2, 3, 4)
        tr = tuple(random.sample(t, len(t)))
        print(tr)
        # (4, 3, 1, 0, 2)

        if tr[ammount-1] not in [r[ammount-1] for r in runs] :
            runs.append(tr)

        #[(4, 3, 1, 0, 2), (3, 4, 2, 1, 0), (3, 2, 4, 0, 1), (2, 3, 1, 0, 4), (1, 2, 0, 4, 3)]
    return runs


def our_selection():
    runs = []
    runs.append((1,2,3,4,0))
    runs.append((2,3,4,0,1))
    runs.append((3,4,0,1,2))
    runs.append((4,0,1,2,3))
    runs.append((0,1,2,3,4))
    return runs


def load_runs(file):
    runs = []
    with open(file,'r') as input:
        for row in input:
            runs.append(tuple(map(int, row.split(','))) )
    return runs


def save_runs(file, runs):
    with open(file,'w') as out:
        for r in runs:
            out.write(','.join(map(str,r))+'\n')


def merge_files(out_file, *in_files):
    with open(out_file, 'w') as out:
        for file in in_files:
            with open(file, 'r') as input:
                lines = input.readlines()
                for l in lines:
                    out.write(l)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=''' Selecting folds' roles (train, valid, test)''')

    parser.add_argument('--foldpath', type=str, dest='fold_path', default='../../datasets/ml1m-sun2cao/ml1m/')
    parser.add_argument('--ammount', type=str, dest='ammount', default='5')
    parser.add_argument('--savepath', type=str, dest='save_path', default='../../datasets/ml1m-sun2cao/ml1m/')

    parsed_args = parser.parse_args()

    fold_path = parsed_args.fold_path
    #ammount = int(parsed_args.ammount)
    save_path = parsed_args.save_path

    runs_file = os.path.join(fold_path, 'runs.csv')
    train_file = os.path.join(save_path, 'train.dat')
    valid_file = os.path.join(save_path, 'valid.dat')
    test_file = os.path.join(save_path, 'test.dat')
    sun_train_file = os.path.join(save_path, 'sun_training.txt')
    sun_test_file = os.path.join(save_path, 'sun_test.txt')

    if os.path.isfile(runs_file):
        runs = load_runs(runs_file)
    else:
        runs = our_selection()

    if len(runs) == 0:
        print('Empty runs list. Delete runs.csv to redo fold selection.')
    else:
        r = runs.pop(0)
        merge_files(train_file,
                    os.path.join(fold_path, 'fold'+str(r[0])+'.dat'),
                    os.path.join(fold_path, 'fold'+str(r[1])+'.dat'),
                    os.path.join(fold_path, 'fold'+str(r[2])+'.dat'))
        merge_files(valid_file, os.path.join(fold_path, 'fold'+str(r[3])+'.dat'))
        merge_files(test_file, os.path.join(fold_path, 'fold'+str(r[4])+'.dat'))

        # merge_files(sun_train_file,
        #             os.path.join(fold_path, 'sun_fold'+str(r[0])+'.txt'),
        #             os.path.join(fold_path, 'sun_fold'+str(r[1])+'.txt'),
        #             os.path.join(fold_path, 'sun_fold'+str(r[2])+'.txt'),
        #             os.path.join(fold_path, 'sun_fold'+str(r[3])+'.txt'))
        # merge_files(sun_test_file, os.path.join(fold_path, 'sun_fold'+str(r[4])+'.txt'))
        save_runs(runs_file, runs)
