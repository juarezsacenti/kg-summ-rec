# know-rec
Knowledge-based experiments with TaoMiner/joint-kg-recommender and sunzhuntu/Recurrent-Knowledge-Graph-Embedding projects.

## Setup

This code was deployed on a machine with an Intel(R) Xeon(R) CPU E5-2640 v4 @ 2.40GHz, 10 physical cores (HT enabled), L1 cache: 32KB data, 32KB instruction per core, L2 cache: 256KB per core,  L3 cache: 25MB accessible by all CPU core, NUMA nodes: 2 (20 physical cores + HT), 128 GB of RAM, NVIDIA Tesla K40c, running the linux Ubuntu 16.06 x86_64.

Use the following steps in order to setup our project properly.

1. Run setup script.<br />
`$ setup.sh`
2. Download Cao datasets from https://drive.google.com/file/d/1FIbaWzP6AWUNG2-8q6SKQ3b9yTiiLvGW/view<br />
3. Move Cao's ml1m data to ~/git/datasets/ml1m-cao.<br />

Git folder should have the follow structure:

```
git
└─datasets
| └─ml1m-cao (with Cao's data)
| | └─ml1m
| | | └─kg
| └─ml1m-cao2sun
| | └─ml1m
| └─ml1m-sun (with Sun's data)
| | └─ml1m
| └─ml1m-sun2cao
| | └─ml1m
| | | └─kg
| └─ml1m-sun_sum0
| | └─ml1m
| | | └─kg
└─joint-kg-recommender
└─know-rec
└─ORBS
└─Recurrent-Knowledge-Graph-Embedding
└─results
| └─ml1m-cao
| └─ml1m-sun
| └─ml1m-sun_sum0
```

4. Install cuda 7.5 from https://developer.nvidia.com/cuda-75-downloads-archive<br />
5. Install Anaconda3, reopen terminal is required.<br />
`$ wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh`
`$ bash -i Anaconda3-2020.02-Linux-x86_64.sh`
`$ conda update -n base -c defaults conda`
6. Create python environment for each project.<br />
`$ bash -i util/create_envs.sh`

## Run

`$ cd ~/git/know-rec/preprocess/`
`$ bash -i preprocess_crossvalid.sh`

`$ cd ~/git/know-rec/run/`
`$ bash -i run_ml1m-crossvalid.sh`
