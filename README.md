# kg-summ-rec
Experiments with Knowledge Graph (KG) -based Summarization (Summ.) and Recommendation (Rec).

We summarize KG representing side information about items gathered by KG-based RSs. We use a KG Embedding (KGE) clustering Summ. strategy with Accenture/AmpliGraph project.

We evaluate summaries of KG representing side information with recommendation metrics from caserec/CaseRecommender project. We adapt TaoMiner/joint-kg-recommender and sunzhuntu/Recurrent-Knowledge-Graph-Embedding projects for generating results with CaseRecommender.

Also, we provide exploratory data analisys (EDA) of original and summarized datasets using jupyter notebook.

## Setup

This code was deployed on a machine with an Intel(R) Xeon(R) CPU E5-2640 v4 @ 2.40GHz, 10 physical cores (HT enabled), L1 cache: 32KB data, 32KB instruction per core, L2 cache: 256KB per core,  L3 cache: 25MB accessible by all CPU core, NUMA nodes: 2 (20 physical cores + HT), 128 GB of RAM, NVIDIA Tesla K40c, running the linux Ubuntu 16.06 x86_64.

Use the following steps in order to setup our project properly.

1. Run setup script.<br />
`$ setup.sh`

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

4. Install cuda 7.5 from https://developer.nvidia.com/cuda-75-downloads-archive<br />
5. Install Anaconda3, reopen terminal is required.<br />
`$ wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh`
`$ bash -i Anaconda3-2020.02-Linux-x86_64.sh`
`$ conda update -n base -c defaults conda`
6. Create python environment for each project.<br />
`$ bash -i util/create_envs.sh`

## Run

`$ cd ~/git/kg-summ-rec`
`$ bash -i run.sh`

OR

`$ cd ~/git/kg-summ-rs`
`$ nohup bash -i run.sh </dev/null >nohup.out 2>nohup.err &`
`$ watch "ps -aux | grep 'python\|bash\|nohup'"`
`$ watch "ls -l"`
