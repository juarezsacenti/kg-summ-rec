import argparse
from caserec.utils.process_data import WriteFile

def load_kgat_data(input_file):
    user_dict = dict()

    lines = open(input_file, 'r').readlines()
    for l in lines:
        tmps = l.strip()
        ids = [int(i) for i in tmps.split(' ')]

        user, item_ids = ids[0], ids[1:]
        item_ids = list(set(item_ids))

        for item in item_ids:
            user_dict.setdefault(user, {}).update({item: 1.0})

    return user_dict


def save_case_rec_data(output_file, user_dict):
#    WriteFile(file_name, data=user_dict, sep='\t', mode='w', as_binary=False).write_with_dict()
    sep='\t'
    with open(output_file, 'w') as infile:
        for user in user_dict:
            for item in user_dict[user]:
                infile.write('%d%s%d%s%f\n' % (user, sep, item, sep, user_dict[user][item]))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=''' Converting file formats ''')

    parser.add_argument('--input_file', type=str, dest='input_file', default='../../knowledge_graph_attention_network/Data/ml1m-sun2kgat/test.txt')
    parser.add_argument('--input_format', type=str, dest='input_format', default='kgat')
    parser.add_argument('--output_file', type=str, dest='output_file', default='../../knowledge_graph_attention_network/Data/ml1m-sun2kgat/case_rec_test.txt')
    parser.add_argument('--output_format', type=str, dest='output_format', default='case_rec')

    parsed_args = parser.parse_args()

    input_file = parsed_args.input_file
    input_format = parsed_args.input_format
    output_file = parsed_args.output_file
    output_format = parsed_args.output_format

    user_dict = dict()

    if input_format == 'kgat':
        user_dict = load_kgat_data(input_file)
        print(len(user_dict))

    if output_format == 'case_rec':
        save_case_rec_data(output_file, user_dict)
