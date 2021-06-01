# kg-summ-rec
Experiments with Knowledge Graph (KG) -based Summarization (Summ.) and Recommendation (Rec).

This is the code of the <em>Knowledge Graph Summarization Impacts on Movie Recommendations</em> in *JIIS'21*, which investigated the use of Graph Summarization (GS) as a Knowledge Graph (KG) preprocessing step of KG-based Recommender Systems (RS) and proposed KGE-K-Means Summarization, a GS method that combines KG Embedding (from [Accenture/Ampligraph project](https://github.com/Accenture/AmpliGraph)) with node clustering (K-Means).

We summarize KG representing side information that enriches user-items interactions of KG-based RSs. 
Then, we evaluate summarized KGs in terms of reduction, RS model (from [TaoMiner/joint-kg-recommender project](https://github.com/juarezsacenti/joint-kg-recommender)) training efficiency and RS effectiveness (with metrics from [caserec/CaseRecommender project](https://github.com/caserec/CaseRecommender)). We adapt KG-based RS projects to evaluates effectiveness using CaseRec (see adapt folder).

Also, we provide exploratory data analisys (EDA) of original and summarized datasets using jupyter notebook.

## Setup
Use the following steps in order to setup our project properly.

1. Run setup script.
```
$ setup.sh
```

Git folder should have the follow structure:

```
git
└─datasets
| └─ml-cao (with Cao's data)
| | └─cao-format
| | | └─ml1m
| | | | └─kg
| └─ml-sun (with Sun's data)
| | └─sun-format
└─joint-kg-recommender
└─kg-summ-rec
└─Recurrent-Knowledge-Graph-Embedding
└─results
| └─ml-cao
| └─ml-sun
```

4. Install cuda 7.5 from https://developer.nvidia.com/cuda-75-downloads-archive

5. Install Anaconda3, reopen terminal is required.
```
$ wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh
$ bash -i Anaconda3-2020.02-Linux-x86_64.sh
$ conda update -n base -c defaults conda
```
6. Create python environment for each project.
```
$ bash -i util/create_envs.sh
```

## Run
```
$ cd ~/git/kg-summ-rec
$ bash -i run.sh
```

OR

```$ cd ~/git/kg-summ-rec
$ nohup bash -i run.sh </dev/null >nohup.out 2>nohup.err &
$ watch "ps -aux | grep 'python\|bash\|nohup'"
$ watch "ls -l"
```

## Data and Results
We provide datasets and results of KGE-K-Means Summarization [1] from example *JIIS-2021-revised* in [sacenti-jiis-2021](https://github.com/juarezsacenti/sacenti-jiis-2021). Note that these results were produced using *JIIS2021* version of this project. To clone this specific version, please use the following command:
```
git clone --depth 1 --branch JIIS2021 https://github.com/juarezsacenti/kg-summ-rec.git
```

## Reference
If you use our code, please cite our paper:
```
@inproceedings{sacenti2021knowledge,
  title={Knowledge Graph Summarization Impacts on Movie Recommendations},
  author={Sacenti, Juarez A. P. and Fileto, Renato and Willrich, Roberto},
  journal={J Intell Inf Syst},
  publisher={Springer},
  year={2021}
}
```
