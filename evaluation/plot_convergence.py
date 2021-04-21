# coding=utf-8
""""
    This class is responsible for plot loss vs epoch graphics given a logfile
    of TaoMiner project joint-kg-recommender.

"""

import matplotlib.pyplot as plt
import numpy as np
import argparse
import os

__author__ = 'Juarez Sacenti <juarez[DOT]sacenti[AT]gmail[DOT]com>'

def read_rec_log(mode, log_file):
    train_losses, test_losses = [] , []
    eval_interval_steps, steps_per_epoch = 0, 0
    with open(log_file) as fin:
        for line in fin:
            line = line.strip()
            if 'eval_interval_steps' in line:
                tokens = line.strip().split(' ')
                eval_interval_steps = tokens[1][:-1]
            if 'One epoch is' in line:
                tokens = line.split(' ')
                steps_per_epoch = tokens[10]
            if 'loss' in line:
                tokens = line.split(' ')
                if mode == 'train_test':
                    train_loss = float(tokens[9][5:-1])
                    train_losses.append(train_loss)
                    test_loss = float(tokens[12][5:-1])
                    test_losses.append(test_loss)
                else:
                    train_loss = float(tokens[8][5:-1])
                    train_losses.append(train_loss)

    epochs_per_eval = float(eval_interval_steps)/float(steps_per_epoch)
    return train_losses, test_losses, epochs_per_eval


def read_summ_log(mode, log_file):
    losses = []
    epochs = 0
    with open(log_file) as fin:
        for line in fin:
            line = line.strip()
            if 'Average Loss:' in line:
                tokens = line.strip().split('Average Loss:')
                for i in range(1,len(tokens)):
                    t = tokens[i].strip().split(' ')
                    loss = float(t[0][:-1])
                    losses.append(loss)

    return losses[:int(len(losses)/2)], [], 1


def plot_convergence(mode, save_file, train_losses, test_losses, epochs_per_eval):
    plt.figure(figsize=(14,11))
    x = [ i * epochs_per_eval for i in range(1, len(train_losses)+1)]
    plt.plot(x, train_losses, 'o', color='gray', label='Train')
    if mode == 'train_test':
        plt.plot(x, test_losses, 'o', color='black', label='Test')
    plt.xlabel('Epochs', fontsize=16)
    plt.ylabel('Loss', fontsize=16)
    plt.title('Convergence', fontsize=16)
    plt.legend()
    fmt = save_file.split('.')[-1]
    plt.savefig(save_file, format=fmt, dpi=600)
    print('Saving plot with {} points.'.format(len(train_losses)))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='''Convergence Plot for TaoMiner joint-kg-recommender logs.''')

    parser.add_argument('--mode', type=str, dest='mode', default='train_test')
    parser.add_argument('--logfile', type=str, dest='logfile', default='../../results/JIIS-revised-exp8/ml-sun_ho_oKG_rec_cao/ml1m-cfkg-1617764095.log')
    parser.add_argument('--savefile', type=str, dest='savefile', default='../../results/JIIS-revised-exp8/ml-sun_ho_oKG_rec_cao/ml1m-cfkg-1617764095-convergence.eps')
    parsed_args = parser.parse_args()

    mode = os.path.expanduser(parsed_args.mode)
    log_file = os.path.expanduser(parsed_args.logfile)
    save_file = os.path.expanduser(parsed_args.savefile)
    print(mode)
    if mode == 'summ':
        train_losses, test_losses, epochs_per_eval = read_summ_log(mode, log_file)
    else:
        train_losses, test_losses, epochs_per_eval = read_rec_log(mode, log_file)
    plot_convergence(mode, save_file, train_losses, test_losses, epochs_per_eval)
