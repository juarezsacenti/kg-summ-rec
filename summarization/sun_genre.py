#This is used to map the auxiliary information (genre, director and actor) into mapping ID for MovieLens

import argparse
import os

def summarize(fr_auxiliary, fr_hierarchy, fw_summarized):
    '''
    Summarizing Auxiliary Genre Information by Hierarchy

    Inputs:
        @fr_auxiliary: the auxiliary infomation
        @fr_hierarchy: the genre hierarchy information
        @fw_summarized: the output file
    '''
    hierarchy = {}

    genres_not_found = set()

    for line in fr_hierarchy:
        (child, parent) = line.split(",")
        hierarchy[child] = parent.replace('\n', '')

    for line in fr_auxiliary:
        new_line = ''
        lines = line.replace('\n', '').split('|')
        if len(lines) != 4:
            continue

        new_line = lines[0] + '|'
        new_line += lines[1].split(":")[0] + ':'

        for genre in lines[1].split(":")[1].split(','):
            if genre not in hierarchy.keys():
                genres_not_found.add(genre)
                new_line += genre + ','
            else:
                new_line += hierarchy[genre] + ','
        new_line = new_line[:-1] + '|'

        new_line += lines[2] + '|'
        new_line += lines[3] + '\n'

        # Writing
        fw_summarized.write(new_line)

        if len(genres_not_found) > 0:
            print('Not found genres in hierarchy: '+ str(genres_not_found))

    return len(genres_not_found)


if __name__ == '__main__':
    print(os.getcwd())
    parser = argparse.ArgumentParser(description='''Summarizing Auxiliary Genre Information by Hierarchy''')

    parser.add_argument('--auxiliary', type=str, dest='auxiliary_file', default='../../datasets/ml1m-sun/ml1m/auxiliary.txt')
    parser.add_argument('--hierarchy', type=str, dest='hierarchy_file', default='../../datasets/ml1m-summarized_sun/ml1m/hierarchy.txt')
    parser.add_argument('--summarized', type=str, dest='summarized_file', default='../../datasets/ml1m-summarized_sun/ml1m/auxiliary.txt')

    parsed_args = parser.parse_args()

    auxiliary_file = parsed_args.auxiliary_file
    hierarchy_file = parsed_args.hierarchy_file
    summarized_file = parsed_args.summarized_file

    fr_auxiliary = open(auxiliary_file,'r', encoding="utf-8-sig")
    fr_hierarchy = open(hierarchy_file, 'r', encoding="utf8")
    fw_summarized = open(summarized_file,'w', encoding="utf-8-sig")

    genres_not_found = summarize(fr_auxiliary, fr_hierarchy, fw_summarized)

    fr_auxiliary.close()
    fr_hierarchy.close()
    fw_summarized.close()
