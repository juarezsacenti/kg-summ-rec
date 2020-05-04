import argparse
import os

def file2ttl(file, fr_e_map, fr_r_map, save_file):
    e_map = {}
    with open(fr_e_map, 'r') as fin:
        for line in fin:
            (e_id, uri) = line.split("\t")
            e_map[e_id] = uri.replace('\n', '')

    r_map = {}
    with open(fr_r_map, 'r') as fin:
        for line in fin:
            (e_id, uri) = line.split("\t")
            r_map[e_id] = uri.replace('\n', '')

    with open(file, 'r') as fin:
        with open(save_file, 'a') as fout:
            for line in fin:
                (s, o, r) = line.split('\t')
                fout.write('<{}> <{}> <{}>.\n'.format(e_map.get(s, s),
                                                r_map.get(r.replace('\n', ''), r.replace('\n', '')),
                                                e_map.get(o, o)))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=''' Selecting folds' roles (train, valid, test)''')

    parser.add_argument('--kgpath', type=str, dest='kg_path', default='../../datasets/ml1m-sun2cao/ml1m/kg/')
    parser.add_argument('--savepath', type=str, dest='save_path', default='../../results/ml1m-sun/')

    parsed_args = parser.parse_args()

    kg_path = parsed_args.kg_path
    save_path = parsed_args.save_path

    train_file = os.path.join(kg_path, 'train.dat')
    valid_file = os.path.join(kg_path, 'valid.dat')
    test_file = os.path.join(kg_path, 'test.dat')
    fr_e_map = os.path.join(kg_path, 'e_map.dat')
    fr_r_map = os.path.join(kg_path, 'r_map.dat')
    save_file = os.path.join(save_path, 'kg.ttl')

    file2ttl(train_file, fr_e_map, fr_r_map, save_file)
    file2ttl(valid_file, fr_e_map, fr_r_map, save_file)
    file2ttl(test_file, fr_e_map, fr_r_map, save_file)
