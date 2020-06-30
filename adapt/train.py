import tensorflow as tf
import numpy as np
from model import RippleNet

### +Added Imports
from preprocess import load_dict
from caserec.utils.process_data import ReadFile, WriteFile
from caserec.evaluation.item_recommendation import ItemRecommendationEvaluation
### -Added Imports

### +Added Functions
def case_rec_evaluation(sess, args, model, data, ripple_set, batch_size):
    predictions_output_filepath = './ripplenet_pred.dat'
    test_path = './ripplenet_test.dat'

    i_map = load_dict('../data/' + args.dataset + '/i_map.txt')
    u_map = load_dict('../data/' + args.dataset + '/i_map.txt')

    start = 0
    print_preds = []
    while start < data.shape[0]:
        feed_dict = get_feed_dict(args, model, data, ripple_set, start, start + batch_size)
        labels, scores = sess.run([model.labels, model.scores_normalized], feed_dict)
        for u, u_scores in enumerate(scores):
            print('%d\t:%s'%u,str(u_scores))
            for i, score in enumerate(u_scores):
                print_preds.append((u_map[start+u], i_map[i], score))
        start += batch_size
    WriteFile(predictions_output_filepath, data=print_preds, sep='\t').write()

    for u, u_data in enumerate(data):
        for i, score in enumerate(u_data):
            print_preds.append((u_map[start+u], i_map[i], score))

    # Using CaseRecommender ReadFile class to read test_set from file
    eval_data = ReadFile(input_file=test_path).read()
    predictions_data = ReadFile(input_file=predictions_output_filepath).read()

    # Creating CaseRecommender evaluator with item-recommendation parameters
    evaluator = ItemRecommendationEvaluation(n_ranks=[10])

    # Getting evaluation
    item_rec_metrics = evaluator.evaluate(predictions_data['feedback'], eval_data)
    print ('\nItem Recommendation Metrics:\n', item_rec_metrics)

    return item_rec_metrics
### -Added Functions

def train(args, data_info, show_loss):
    train_data = data_info[0]
    eval_data = data_info[1]
    test_data = data_info[2]
    n_entity = data_info[3]
    n_relation = data_info[4]
    ripple_set = data_info[5]

    model = RippleNet(args, n_entity, n_relation)

    with tf.Session() as sess:
        sess.run(tf.global_variables_initializer())
        for step in range(args.n_epoch):
            # training
            np.random.shuffle(train_data)
            start = 0
            while start < train_data.shape[0]:
                _, loss = model.train(
                    sess, get_feed_dict(args, model, train_data, ripple_set, start, start + args.batch_size))
                start += args.batch_size
                if show_loss:
                    print('%.1f%% %.4f' % (start / train_data.shape[0] * 100, loss))

            # evaluation
            train_auc, train_acc = evaluation(sess, args, model, train_data, ripple_set, args.batch_size)
            eval_auc, eval_acc = evaluation(sess, args, model, eval_data, ripple_set, args.batch_size)
            test_auc, test_acc = evaluation(sess, args, model, test_data, ripple_set, args.batch_size)

            print('epoch %d    train auc: %.4f  acc: %.4f    eval auc: %.4f  acc: %.4f    test auc: %.4f  acc: %.4f'
                  % (step, train_auc, train_acc, eval_auc, eval_acc, test_auc, test_acc))

### +Added Instructions
        case_rec_evaluation(sess, args, model, test_data, ripple_set, args.batch_size)
### -Added Instructions


def get_feed_dict(args, model, data, ripple_set, start, end):
    feed_dict = dict()
    feed_dict[model.items] = data[start:end, 1]
    feed_dict[model.labels] = data[start:end, 2]
    for i in range(args.n_hop):
        feed_dict[model.memories_h[i]] = [ripple_set[user][i][0] for user in data[start:end, 0]]
        feed_dict[model.memories_r[i]] = [ripple_set[user][i][1] for user in data[start:end, 0]]
        feed_dict[model.memories_t[i]] = [ripple_set[user][i][2] for user in data[start:end, 0]]
    return feed_dict


def evaluation(sess, args, model, data, ripple_set, batch_size):
    start = 0
    auc_list = []
    acc_list = []
    while start < data.shape[0]:
        auc, acc = model.eval(sess, get_feed_dict(args, model, data, ripple_set, start, start + batch_size))
        auc_list.append(auc)
        acc_list.append(acc)
        start += batch_size
    return float(np.mean(auc_list)), float(np.mean(acc_list))
